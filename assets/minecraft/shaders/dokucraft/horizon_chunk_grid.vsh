#version 330

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
flat out int isHorizon;

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
  vertexColor = Color;
  isHorizon = int(1.0 - Color.a);
}
