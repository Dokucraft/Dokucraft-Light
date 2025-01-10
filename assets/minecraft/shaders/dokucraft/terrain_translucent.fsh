#version 330

#moj_import <minecraft:fog.glsl>
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
flat in int isWaterSurface;

#if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_WATER_HIGHLIGHT)
  #ifdef ENABLE_FRAGMENT_FRESNEL
    in vec3 wpos;
    in vec3 wnorm;
  #else
    in float fresnel;
  #endif
#endif

out vec4 fragColor;

#ifdef ENABLE_PROCEDURAL_WATER_SURFACE
  #moj_import <minecraft:perlin_worley.glsl>
  #moj_import <minecraft:hash12.glsl>
  #moj_import <dokucraft:flavor.glsl>

  uniform float GameTime;
  in vec3 pos;

  vec3 px(vec3 p, float scale) {
    vec2 xz = floor(p.xz * 32.0) / 32.0;
    return vec3(xz.x, p.y, xz.y) * scale;
  }
#endif

void main() {
  #if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_WATER_HIGHLIGHT)
    vec4 color = texture(Sampler0, texCoord0);

    if (
      (color.a >= 0.4 && color.a < 0.9)
      #ifdef ENABLE_PROCEDURAL_WATER_SURFACE
        || isWaterSurface == 1
      #endif
    ) {
      #ifdef ENABLE_FRAGMENT_FRESNEL
        float fresnel = 1.0 - abs(dot(normalize(-wpos), wnorm));
        fresnel *= fresnel;
      #endif

      #ifdef ENABLE_PROCEDURAL_WATER_SURFACE
        if (isWaterSurface == 1) {
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
        if (isWaterSurface == 1) {
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
}
