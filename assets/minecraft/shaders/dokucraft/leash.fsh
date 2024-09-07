#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:utils.glsl>

uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
flat in vec4 vertexColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);
  fragColor = linear_fog(vertexColor, vertexDistance, FogStart, FogEnd, FogColor);
}
