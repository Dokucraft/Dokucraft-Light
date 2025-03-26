#version 330

#moj_import <dokucraft:config.glsl>

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;

#ifdef ENABLE_CUSTOM_SKY
  out vec4 glpos;
#endif

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

  #ifdef ENABLE_CUSTOM_SKY
    glpos = gl_Position;
  #endif

  vertexColor = Color;
}
