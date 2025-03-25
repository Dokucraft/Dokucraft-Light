#version 330

#moj_import <minecraft:projection.glsl>
#moj_import <dokucraft:config.glsl>

in vec3 Position;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 texProj0;

#ifdef ENABLE_CUSTOM_SKY
  out vec4 glpos;
#endif

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

  #ifdef ENABLE_CUSTOM_SKY
    glpos = gl_Position;
  #endif

  texProj0 = projection_from_position(gl_Position);
}
