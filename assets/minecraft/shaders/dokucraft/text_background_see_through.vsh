#version 330

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out vec4 glpos;

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
  glpos = gl_Position;

  vertexColor = Color;
}
