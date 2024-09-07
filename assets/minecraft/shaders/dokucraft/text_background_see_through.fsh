#version 330

#moj_import <minecraft:utils.glsl>

uniform vec4 ColorModulator;

in vec4 vertexColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);
  vec4 color = vertexColor;
  if (color.a < 0.1) {
    discard;
  }
  fragColor = color * ColorModulator;
}
