#version 330

#moj_import <dokucraft:config.glsl>

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;


#ifdef ENABLE_CUSTOM_SKY
  flat out int isHorizon;
#endif

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
  vertexColor = Color;

  #ifdef ENABLE_CUSTOM_SKY
    isHorizon = int(1.0 - Color.a);
  #endif
}
