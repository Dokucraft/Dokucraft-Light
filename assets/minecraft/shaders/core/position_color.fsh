#version 150

#moj_import <utils.glsl>

in vec4 vertexColor;
in float isHorizon;
in float isSpyglass;

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
    if (isSpyglass > 0.5 && distance(color.rgb, vec3(0, 0, 0)) < 0.01) fragColor = vec4(1, 0, 0, 1);
    fragColor = color * ColorModulator;
	if (isHorizon > 0.5) {fragColor.a = 0;}
}
