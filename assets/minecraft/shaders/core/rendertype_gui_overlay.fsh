#version 150

#moj_import <../flavor.glsl>

in vec4 vertexColor;
in vec2 uv;
flat in int customType;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
  vec4 color = vertexColor;
  if (color.a < 0.01) {
    discard;
  }
  if (customType == 1) { // Item hover highlight
    float m = abs(1.0 - (0.5 + uv.x * 0.5) - (0.5 + uv.y * 0.5));
    if ((abs(uv.x) > 0.94) || (abs(uv.y) > 0.94)) {
      fragColor = vec4(HOVER_OUTLINE_COLOR.rgb, HOVER_OUTLINE_COLOR.a * m); // outline
    } else if ((abs(uv.x) > 0.88) || (abs(uv.y) > 0.88)) {
      fragColor = vec4(0.0, 0.0, 0.0, HOVER_OUTLINE_COLOR.a * (0.5 * m + 0.2)); // outline shadow
    } else {
      discard; // inside
    }
    return;
  } else {
    fragColor = color * ColorModulator;
  }
}
