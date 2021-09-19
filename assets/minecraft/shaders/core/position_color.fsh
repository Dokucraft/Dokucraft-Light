#version 150

#moj_import <utils.glsl>

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
    if (isSpyglass > 0.5 && distance(color.rgb, vec3(0, 0, 0)) < 0.01) fragColor = vec4(1, 0, 0, 1); //backgound colour
    fragColor = color * ColorModulator;
    if (customType == 1) {
      ivec2 hoverUv = ivec2(uv);
      if ((hoverUv.x == 17 || hoverUv.x == 0) || (hoverUv.y == 17 || hoverUv.y == 0)) {
        fragColor = vec4(0.988, 0.988, 0.98, 0.8); //outline
      } else {
        fragColor = vec4(0, 0, 0, 0.2); //inside
      }
    }
	if (isHorizon > 0.5) {fragColor.a = 0;}
}