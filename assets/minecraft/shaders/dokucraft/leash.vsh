#version 330

#moj_import <minecraft:fog.glsl>

in vec3 Position;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec4 ColorModulator;
uniform int FogShape;

out float vertexDistance;
flat out vec4 vertexColor;
out vec4 glpos;

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
  glpos = gl_Position;

  vertexDistance = fog_distance(Position, FogShape);
  vertexColor = Color * ColorModulator * texelFetch(Sampler2, UV2 / 16, 0);
}
