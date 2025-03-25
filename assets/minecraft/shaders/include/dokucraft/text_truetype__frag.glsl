#version 330

#moj_import <minecraft:fog.glsl>
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
in vec2 texCoord0;

#ifdef ENABLE_CUSTOM_SKY
  in vec4 glpos;
#endif

out vec4 fragColor;

void main() {
  #ifdef ENABLE_CUSTOM_SKY
    discardControlGLPos(gl_FragCoord.xy, glpos);
  #endif

  vec4 color = texture(Sampler0, texCoord0).rrrr * vertexColor * ColorModulator;
  if (color.a < 0.1) {
    discard;
  }
  fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
