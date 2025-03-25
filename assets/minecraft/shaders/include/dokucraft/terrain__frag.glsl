#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:emissive_utils.glsl>
#moj_import <dokucraft:config.glsl>

#ifdef ENABLE_CUSTOM_SKY
  #moj_import <minecraft:utils.glsl>
#endif

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
flat in int isWaterSurface;

#ifdef ENABLE_CUSTOM_SKY
  in vec4 glpos;
#endif

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
  in vec2 tileUVPara;
#endif

#if defined(USE_BETTER_LAVA) || defined(ENABLE_PARALLAX_SUBSURFACE)
  flat in vec2 tileSize;
#endif

#if defined(ENABLE_PROCEDURAL_WATER_SURFACE) || defined(ENABLE_PARALLAX_SUBSURFACE)
  in vec3 pos;
#endif

in vec3 wnorm;
in vec3 wpos;
#if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_WATER_HIGHLIGHT)
  #ifndef ENABLE_FRAGMENT_FRESNEL
    in float fresnel;
  #endif
#endif

out vec4 fragColor;

#if USE_GRASS_TYPE == 2 || defined(ENABLE_PROCEDURAL_WATER_SURFACE)
  #moj_import <minecraft:hash12.glsl>
#endif

#if USE_GRASS_TYPE == 3
  #moj_import <minecraft:perlin_worley.glsl>
#endif

#ifdef ENABLE_PARALLAX_SUBSURFACE
  vec2 parallax(vec2 texCoords, vec3 viewDir, vec3 norm, float depthScale) {
    return texCoords + (viewDir.zy / viewDir.x * vec2(abs(norm.x), norm.x) - viewDir.xz / viewDir.y * vec2(norm.y, abs(norm.y)) - viewDir.xy / viewDir.z * vec2(abs(norm.z), -norm.z)) * tileSize * depthScale;
  }
#endif

#ifdef ENABLE_PROCEDURAL_WATER_SURFACE
  #moj_import <minecraft:perlin_worley.glsl>
  #moj_import <dokucraft:flavor.glsl>

  uniform float GameTime;

  vec3 px(vec3 p, float scale) {
    vec2 xz = floor(p.xz * 32.0) / 32.0;
    return vec3(xz.x, p.y, xz.y) * scale;
  }
#endif

void main() {
  // SOLID isn't defined for solid blocks anymore, it is just left here in case that changes in the future
  #if defined(ALPHA_CUTOUT) || defined(SOLID)
    #ifdef ENABLE_CUSTOM_SKY
      discardControlGLPos(gl_FragCoord.xy, glpos);
    #endif

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
    #ifdef ALPHA_CUTOUT
      if (color.a < ALPHA_CUTOUT) discard;
    #else
      if (color.a < 0.5) discard;
    #endif
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

  #else // Translucent
    #if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_WATER_HIGHLIGHT)
      vec4 color = texture(Sampler0, texCoord0);

      if (
        (color.a >= 0.4 && color.a < 0.9)
        #ifdef ENABLE_PROCEDURAL_WATER_SURFACE
          || isWaterSurface == 2
        #endif
      ) {
        #ifdef ENABLE_FRAGMENT_FRESNEL
          float fresnel = 1.0 - abs(dot(normalize(-wpos), wnorm));
          fresnel *= fresnel;
        #endif

        #ifdef ENABLE_PROCEDURAL_WATER_SURFACE
          if (isWaterSurface == 2) {
            float time = floor(GameTime * 24000) / 24000;
            float distFactor = pow(1.0 - min(1, max(0, vertexDistance - 50) / 200.0), 0.5);
            vec3 pxpos = px(pos, 2);
            float n1 = pow(1 - worleyNoise(pxpos + vec2(time * 750, time * 30).xyx, 16 * 2), 2);
            float n2 = pow(1 - worleyNoise(pxpos + vec2(-time * 600, time * 50 + 100).xyx, 16 * 2), 2);
            float n3 = pow(1 - worleyNoise(pxpos + vec2(0, time * 10 + 200).xyx, 16 * 2), 2);
            float n4 = smoothstep(0.98, 1, hash12(px(pos, 1).xz * 15));
            float t = (n1 * 0.75 + n2 * 0.6 + n3) * 0.9;
            t += (t * 0.75 + 0.25) * n4;

            #ifdef ENABLE_PWS_REDUCE_SHADOW_HIGHLIGHTS
              t = pow(t, mix(3, 1, lightColor.g));
            #endif

            t = floor(t * 8.0) / 8.0;
            t *= pow(1 - fresnel, 0.3) * distFactor;

            color.rgb = mix(
              PROCEDURAL_WATER_COLOR_1,
              mix(
                PROCEDURAL_WATER_COLOR_2,
                mix(
                  PROCEDURAL_WATER_COLOR_3,
                  PROCEDURAL_WATER_COLOR_4,
                  clamp((t - 0.8) / (1 - 0.8), 0, 1)
                ),
                clamp((t - 0.5) / (0.8 - 0.5), 0, 1)
              ),
              clamp(t / 0.5, 0, 1)
            );
            color.a = mix(0.5, 0.6, t);
          }
        #endif

        vec4 vc = vertexColor;

        #if defined(ENABLE_FRESNEL_EFFECT) && defined(ENABLE_FRESNEL_BRIGHTNESS_COMPENSATION)
          vc.rgb *= mix(1, (color.a + 1) / 2, fresnel);
        #endif

        #ifdef ENABLE_DESATURATE_WATER_HIGHLIGHT
          if (isWaterSurface > 0) {
            float cmax = max(color.r, max(color.g, color.b));
            float cmin = min(color.r, min(color.g, color.b));
            float sat = (cmax - cmin) / cmax;
            vec4 tinted = color * vc * ColorModulator;
            color = mix(tinted, color, 1 - smoothstep(0, 0.75, sat)) * lightColor;
          } else {
            color *= vc * ColorModulator * lightColor;
          }
        #else
          color *= vc * ColorModulator * lightColor;
        #endif

        #ifdef ENABLE_FRESNEL_EFFECT
          color.a = mix(color.a, 1, fresnel);
        #endif
      } else {
        color *= vertexColor * ColorModulator * lightColor;
      }
    #else
      vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator * lightColor;
    #endif

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
  #endif
}
