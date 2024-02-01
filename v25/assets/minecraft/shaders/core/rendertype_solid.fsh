#version 150

#moj_import <fog.glsl>
#moj_import <utils.glsl>
#moj_import <emissive_utils.glsl>
#moj_import <../config.txt>

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

#ifdef ENABLE_BETTER_LAVA
  in float noiseValue;
  in vec2 tileUVLava;

  flat in int customType;
  flat in int randomTile;
#endif

#ifdef ENABLE_PARALLAX_SUBSURFACE
  in vec3 pos;
  in vec3 wnorm;
  in vec2 tileUVPara;
#endif

#if defined(ENABLE_BETTER_LAVA) || defined(ENABLE_PARALLAX_SUBSURFACE)
  flat in vec2 tileSize;
#endif

out vec4 fragColor;

#ifdef ENABLE_PARALLAX_SUBSURFACE
  vec2 parallax(vec2 texCoords, vec3 viewDir, vec3 norm, float depthScale) {
    return texCoords + (viewDir.zy / viewDir.x * vec2(abs(norm.x), norm.x) - viewDir.xz / viewDir.y * vec2(norm.y, abs(norm.y)) - viewDir.xy / viewDir.z * vec2(abs(norm.z), -norm.z)) * tileSize * depthScale;
  }
#endif

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);
  vec4 color = texture(Sampler0, texCoord0);
  if (color.a < 0.5) discard;
  float oa = textureLod(Sampler0, texCoord0, 0.0).a * 255.0;

  #if defined(ENABLE_BETTER_LAVA) || defined(ENABLE_PARALLAX_SUBSURFACE)
    int alpha = int(floor(oa + 0.5));
  #endif

  #ifdef ENABLE_BETTER_LAVA
    if (alpha == 247) {
      vec2 uuv = texCoord0 - tileUVLava * vec2(LAVA_VARIANT_COUNT, 2) * tileSize + tileUVLava * tileSize + vec2(tileSize.x * randomTile, 0);
      vec3 uc = texture(Sampler0, uuv).rgb;
      vec3 lc = texture(Sampler0, uuv + vec2(0, tileSize.y)).rgb;
      fragColor = linear_fog(vec4(mix(uc, lc, noiseValue), 1) * vertexColor * ColorModulator, vertexDistance, FogStart, FogEnd, FogColor);
      return;
    }
  #endif

  #ifdef ENABLE_PARALLAX_SUBSURFACE
    if (alpha == 248) {
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
      color = make_emissive(color * vertexColor * ColorModulator, lightColor, vertexDistance, oa);
    }
  #else
    color = make_emissive(color * vertexColor * ColorModulator, lightColor, vertexDistance, oa);
  #endif

  fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
