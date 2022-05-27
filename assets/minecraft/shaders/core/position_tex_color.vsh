#version 150

#moj_import <../config.txt>

in vec3 Position;
in vec2 UV0;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

#ifdef ENABLE_CUSTOM_END_SKY
  uniform mat3 IViewRotMat;
#endif

out vec2 texCoord0;
out vec4 vertexColor;
out vec4 Pos;

#ifdef ENABLE_CUSTOM_END_SKY
  out vec3 direction;
#endif

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

  Pos = ModelViewMat * vec4(1);

  texCoord0 = UV0;
  vertexColor = Color;

  #ifdef ENABLE_CUSTOM_END_SKY
    direction = IViewRotMat * Position;
  #endif
}
