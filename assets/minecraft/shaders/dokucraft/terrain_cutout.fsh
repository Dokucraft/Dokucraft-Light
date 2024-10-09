#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:utils.glsl>
#moj_import <minecraft:emissive_utils.glsl>
#moj_import <dokucraft:config.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;
in vec4 normal;
in vec4 glpos;

// Some things only need to be checked for solid blocks, and some only for
// cutout blocks, so use some logic to redefine the config options here so they
// are easier to use later in the script.
#ifdef SOLID
  #define USE_GRASS_TYPE 0
  #ifdef ENABLE_BETTER_LAVA
    #define USE_BETTER_LAVA
  #endif
#else
  #define USE_GRASS_TYPE GRASS_TYPE
#endif

#if defined(USE_BETTER_LAVA) || USE_GRASS_TYPE > 0
  flat in int type;
#endif

#if USE_GRASS_TYPE == 2 || USE_GRASS_TYPE == 3
  in vec3 shellGrassUV;
#endif

#ifdef USE_BETTER_LAVA
  in float noiseValue;
  in vec2 tileUVLava;

  flat in int randomTile;
#endif

#ifdef ENABLE_PARALLAX_SUBSURFACE
  in vec3 pos;
  in vec3 wnorm;
  in vec2 tileUVPara;
#endif

#if defined(USE_BETTER_LAVA) || defined(ENABLE_PARALLAX_SUBSURFACE)
  flat in vec2 tileSize;
#endif

out vec4 fragColor;

#if USE_GRASS_TYPE == 2
  #moj_import <minecraft:hash12.glsl>
#elif USE_GRASS_TYPE == 3
  #moj_import <minecraft:perlin_worley.glsl>
#endif

#ifdef ENABLE_PARALLAX_SUBSURFACE
  vec2 parallax(vec2 texCoords, vec3 viewDir, vec3 norm, float depthScale) {
    return texCoords + (viewDir.zy / viewDir.x * vec2(abs(norm.x), norm.x) - viewDir.xz / viewDir.y * vec2(norm.y, abs(norm.y)) - viewDir.xy / viewDir.z * vec2(abs(norm.z), -norm.z)) * tileSize * depthScale;
  }
#endif

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);

  #if USE_GRASS_TYPE == 1
    if (type == 1) {
      fragColor = linear_fog(vertexColor, vertexDistance, FogStart, FogEnd, FogColor);
      return;
    }
  #elif USE_GRASS_TYPE == 2
    if (type == 1) {
      if (hash12(floor(-shellGrassUV.xy)) > DENSE_GRASS_COVERAGE) discard;
      vec2 px = floor(shellGrassUV.xy);
      vec2 o = vec2(
        hash12(px + 47.183),
        hash12(px + 189.215)
      ) * 0.5 + 0.25;
      float n = hash12(px);
      vec2 co = o - fract(shellGrassUV.xy);
      float c = n * max(0, 1.0 - mix(max(abs(co.x), abs(co.y)), length(co), shellGrassUV.z / n) * 2);
      if (1.0 - DENSE_GRASS_RADIUS_THRESHOLD < shellGrassUV.z / n || c < shellGrassUV.z) {
        discard;
      }
      vec4 col = texture(Sampler0, texCoord0);
      fragColor = linear_fog(vertexColor * vec4(vec3(mix(0.65, 1, col.r)), 1), vertexDistance, FogStart, FogEnd, FogColor);
      return;
    }
  #elif USE_GRASS_TYPE == 3
    if (type == 1) {
      float n = clamp(worleyNoise(vec3(shellGrassUV.xy, 0), 256.0), 0.0, 1.0);
      n = pow(1.0 - sqrt(cos(1.5707963 * n)), 2) * n;
      if (n < shellGrassUV.z) {
        discard;
      }
      vec4 col = texture(Sampler0, texCoord0);
      fragColor = linear_fog(vertexColor * vec4(vec3(mix(0.65, 1, col.r)), 1), vertexDistance, FogStart, FogEnd, FogColor);
      return;
    }
  #endif

  #ifdef USE_BETTER_LAVA
    // For future reference: This block of code MUST happen before any alpha threshold checks that discard the pixel.
    if (type == 2) {
      vec2 uuv = texCoord0 - tileUVLava * vec2(LAVA_VARIANT_COUNT, 2) * tileSize + tileUVLava * tileSize + vec2(tileSize.x * randomTile, 0);
      vec3 uc = texture(Sampler0, uuv).rgb;
      vec3 lc = texture(Sampler0, uuv + vec2(0, tileSize.y)).rgb;
      fragColor = linear_fog(vec4(mix(uc, lc, noiseValue), 1) * vertexColor * ColorModulator, vertexDistance, FogStart, FogEnd, FogColor);
      return;
    }
  #endif

  vec4 color = texture(Sampler0, texCoord0);
  if (color.a < 0.5) discard;
  float oa = textureLod(Sampler0, texCoord0, 0.0).a * 255.0;

  #ifdef ENABLE_PARALLAX_SUBSURFACE
    if (int(floor(oa + 0.5)) == 248) {
      vec2 tileOrigin = texCoord0 - tileUVPara * tileSize;
      vec4 t1c = texture(Sampler0, texCoord0 + vec2(tileSize.x, 0));
      vec4 t3c = texture(Sampler0, texCoord0 + tileSize);
      float omh = 1.0 - t1c.r;
      vec3 np = normalize(-pos);
      vec2 ps = vec2(1) / vec2(textureSize(Sampler0, 0));
      vec2 tsmps = tileSize - ps;
      vec4 colModUnlit = vertexColor * ColorModulator;
      vec4 colMod = colModUnlit * lightColor;

      #ifdef ENABLE_PSS_SHALLOW_ANGLE_FIX
        // Mix in more of the surface color at very shallow angles to hide some artifacts
        float ssa = 1.0 - abs(dot(np, wnorm));
        ssa = t1c.g * (1.0 - ssa * ssa);
      #else
        float ssa = t1c.g;
      #endif

      int opts = int(floor(t3c.r * 255 + 0.5));
      if (opts == 1) { // Clamp the UVs to the edges of the texture
        vec2 dg = tileOrigin + clamp(parallax(texCoord0, np, wnorm, omh * 0.44) - tileOrigin, ps, tsmps);
        #ifdef ENABLE_PSS_CHROMATIC_ABERRATION
          vec3 dcol = vec3(
            textureLod(Sampler0, tileOrigin + vec2(0, tileSize.y) + clamp(parallax(texCoord0, np, wnorm, omh * (0.44 - t3c.g * 0.1)) - tileOrigin, ps, tsmps), 0).r,
            textureLod(Sampler0, dg + vec2(0, tileSize.y), 0).g,
            textureLod(Sampler0, tileOrigin + vec2(0, tileSize.y) + clamp(parallax(texCoord0, np, wnorm, omh * (0.44 + t3c.g * 0.1)) - tileOrigin, ps, tsmps), 0).b
          );
        #else
          vec3 dcol = textureLod(Sampler0, dg + vec2(0, tileSize.y), 0).rgb;
        #endif
        color = mix(color * mix(colMod, colModUnlit, t3c.b), vec4(mix(dcol * colMod.rgb, dcol, textureLod(Sampler0, dg + vec2(tileSize.x, 0), 0).b), 1), ssa);

      } else { // Repeat texture instead of clamping
        vec2 dg = tileOrigin + clamp(mod(parallax(texCoord0, np, wnorm, omh * 0.44) - tileOrigin, tileSize), ps, tsmps);
        #ifdef ENABLE_PSS_CHROMATIC_ABERRATION
          vec3 dcol = vec3(
            textureLod(Sampler0, tileOrigin + vec2(0, tileSize.y) + clamp(mod(parallax(texCoord0, np, wnorm, omh * (0.44 - t3c.g * 0.1)) - tileOrigin, tileSize), ps, tsmps), 0).r,
            textureLod(Sampler0, dg + vec2(0, tileSize.y), 0).g,
            textureLod(Sampler0, tileOrigin + vec2(0, tileSize.y) + clamp(mod(parallax(texCoord0, np, wnorm, omh * (0.44 + t3c.g * 0.1)) - tileOrigin, tileSize), ps, tsmps), 0).b
          );
        #else
          vec3 dcol = textureLod(Sampler0, dg + vec2(0, tileSize.y), 0).rgb;
        #endif
        color = mix(color * mix(colMod, colModUnlit, t3c.b), vec4(mix(dcol * colMod.rgb, dcol, textureLod(Sampler0, dg + vec2(tileSize.x, 0), 0).b), 1), ssa);
      }
    } else {
      color = make_emissive(color * vertexColor * ColorModulator, lightColor, oa);
    }
  #else
    color = make_emissive(color * vertexColor * ColorModulator, lightColor, oa);
  #endif

  fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
