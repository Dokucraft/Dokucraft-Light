#version 330

#moj_import <minecraft:fog.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

out float vertexDistance;
out vec2 texCoord0;
out vec4 vertexColor;

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

  vertexDistance = fog_distance(Position, FogShape);
  texCoord0 = UV0;
  if (int(texture(Sampler0, UV0).a * 255) == 25) {
    vertexColor = texelFetch(Sampler2, UV2 / 16, 0);
  } else {
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
  }
}
