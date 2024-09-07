#version 330

uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;

out vec4 fragColor;

void main() {
  fragColor = vec4(mix(vertexColor.rgb, FogColor.rgb, 0.5), vertexColor.a);
  fragColor.a *= smoothstep(FogEnd + 48, FogStart - 16, vertexDistance);
}
