#version 150

#moj_import <dokucraft:config.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in vec2 UV2;
in vec3 Normal;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord1;
out vec2 texCoord2;

#ifdef ENABLE_CUSTOM_SKY
  out vec4 glpos;
#endif

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

  #ifdef ENABLE_CUSTOM_SKY
    glpos = gl_Position;
  #endif

  vertexColor = Color;
  texCoord0 = UV0;
  texCoord1 = UV1;
  texCoord2 = UV2;
}
