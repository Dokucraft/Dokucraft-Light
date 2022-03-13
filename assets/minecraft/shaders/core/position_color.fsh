#version 150

#moj_import <utils.glsl>
#moj_import <../flavor.glsl>

in vec4 vertexColor;
in float isHorizon;
in float isSpyglass;
in vec2 uv;
flat in int customType;

uniform vec4 ColorModulator;
uniform vec2 ScreenSize;
uniform mat4 ModelViewMat;

out vec4 fragColor;

void main() {
  if (isHorizon > 0.5) {
    discardControl(gl_FragCoord.xy, ScreenSize.x);
  }
  vec4 color = vertexColor;
  if (color.a == 0.0) {discard;}
  if (isSpyglass > 0.5 && distance(color.rgb, vec3(0, 0, 0)) < 0.01) {
    fragColor = vec4(0, 0, 0, 1); // backgound colour
    return;
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
  } else if (customType == 2) { // Tooltip outline
    fragColor = vec4(TOOLTIP_OUTLINE_COLOR.rgb, TOOLTIP_OUTLINE_COLOR.a * abs(1.0 - (0.5 + uv.x * 0.5) - (0.5 + uv.y * 0.5)));
    return;
  } else {
    fragColor = color * ColorModulator;
  }
	if (isHorizon > 0.5) {
    fragColor.a = 0;
    return;
  }
}