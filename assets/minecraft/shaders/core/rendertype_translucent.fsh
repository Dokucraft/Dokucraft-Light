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
  in float fresnel;
#endif

out vec4 fragColor;

void main() {
  #if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR)
    vec4 color = texture(Sampler0, texCoord0);

    #ifdef ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR
      color = mix(color * vertexColor * ColorModulator, color, color.r * color.g * color.b * (1 - fresnel)) * lightColor;
    #else
      color *= vertexColor * ColorModulator * lightColor;
    #endif
  #else
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator * lightColor;
  #endif

  #ifdef ENABLE_FRESNEL_EFFECT
    color.a = mix(color.a, 1, fresnel);
  #endif

  fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
