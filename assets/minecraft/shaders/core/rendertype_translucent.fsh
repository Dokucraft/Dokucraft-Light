#version 150

#moj_import <fog.glsl>
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

#if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR)
  #ifdef ENABLE_FRAGMENT_FRESNEL
    in vec3 wpos;
    in vec3 wnorm;
  #else
    in float fresnel;
  #endif
#endif

out vec4 fragColor;

void main() {
  #if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR)
    vec4 color = texture(Sampler0, texCoord0);

    if (color.a >= 0.4 && color.a < 0.9) {
      #ifdef ENABLE_FRAGMENT_FRESNEL
        float fresnel = 1.0 - abs(dot(normalize(-wpos), wnorm));
        fresnel *= fresnel;
      #endif

      vec4 vc = vertexColor;

      #if defined(ENABLE_FRESNEL_EFFECT) && defined(ENABLE_FRESNEL_BRIGHTNESS_COMPENSATION)
        vc.rgb *= mix(1, (color.a + 1) / 2, fresnel);
      #endif

      #ifdef ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR
        float cmax = max(color.r, max(color.g, color.b));
        float cmin = min(color.r, min(color.g, color.b));
        float sat = (cmax - cmin) / cmax;
        vec4 tinted = color * vc * ColorModulator;
        color = mix(tinted, color, 1 - smoothstep(0, 0.75, sat)) * lightColor;
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
