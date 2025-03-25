#version 330

#moj_import <dokucraft:config.glsl>

#ifdef ENABLE_CUSTOM_SKY
  #moj_import <minecraft:utils.glsl>
#endif

uniform vec4 ColorModulator;

in vec4 vertexColor;

#ifdef ENABLE_CUSTOM_SKY
  in vec4 glpos;
#endif

out vec4 fragColor;

void main() {
  #ifdef ENABLE_CUSTOM_SKY
    discardControlGLPos(gl_FragCoord.xy, glpos);
  #endif

  vec4 color = vertexColor;
  if (color.a < 0.1) {
    discard;
  }
  fragColor = color * ColorModulator;
}
