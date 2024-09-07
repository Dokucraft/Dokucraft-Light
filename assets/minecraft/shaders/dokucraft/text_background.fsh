#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec4 glpos;

out vec4 fragColor;

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);
  vec4 color = vertexColor * ColorModulator;
  if (color.a < 0.1) {
    discard;
  }
  fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
