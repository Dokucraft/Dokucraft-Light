#version 330

in vec4 vertexColor;
in vec2 uv;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
  vec4 color = vertexColor;
  if (color.a < 0.01) {
    discard;
  }
  fragColor = color * ColorModulator;
}
