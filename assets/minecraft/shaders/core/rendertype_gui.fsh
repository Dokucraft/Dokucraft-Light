#version 150

#moj_import <../flavor.glsl>

in vec4 vertexColor;
in vec2 uv;
flat in int customType;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
  vec4 color = vertexColor;
  if (color.a == 0.0) {
    discard;
  }
  if (customType == 1) { // Tooltip outline
    fragColor = vec4(TOOLTIP_OUTLINE_COLOR.rgb, TOOLTIP_OUTLINE_COLOR.a * uv.x);
  } else {
    fragColor = color * ColorModulator;
  }
}
