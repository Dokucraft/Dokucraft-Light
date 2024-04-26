#version 150

#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in vec2 texCoord0;
in vec4 vertexColor;
in vec4 Pos;
in float isNeg;
in vec2 ScrSize;

out vec4 fragColor;

void main() {
  vec4 color = texture(Sampler0, texCoord0) * vertexColor;
  vec2 texSize = textureSize(Sampler0, 0);

  if (color.a < 0.1) {
    discard;
  }

  fragColor = color * ColorModulator;
}
