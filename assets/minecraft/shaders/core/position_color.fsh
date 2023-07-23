#version 150

#moj_import <utils.glsl>

in vec4 vertexColor;
in vec4 glpos;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);
  vec4 color = vertexColor;
  if (color.a == 0.0) {
    discard;
  }
  fragColor = color * ColorModulator;
}
