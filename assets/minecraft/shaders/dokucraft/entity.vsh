#version 330

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat4 TextureMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 shadeColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;
out vec4 glpos;

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
  glpos = gl_Position;

  vertexDistance = fog_distance(Position, FogShape);
  
  vertexColor = Color;

  #ifdef NO_CARDINAL_LIGHTING
    shadeColor = vec4(1);
  #else
    shadeColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, vec4(1));
  #endif

  lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
  overlayColor = texelFetch(Sampler1, UV1, 0);

  #ifndef APPLY_TEXTURE_MATRIX
    texCoord0 = UV0;
  #else
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
  #endif
}
