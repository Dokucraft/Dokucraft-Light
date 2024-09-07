#version 330

#moj_import <minecraft:projection.glsl>

in vec3 Position;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 texProj0;
out vec4 glpos;

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
  glpos = gl_Position;

  texProj0 = projection_from_position(gl_Position);
}
