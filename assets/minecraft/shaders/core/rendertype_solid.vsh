#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <../config.txt>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;
uniform int FogShape;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

#ifdef ENABLE_PARALLAX_SUBSURFACE
  out vec3 pos;
  out vec3 wnorm;
  out vec2 tileSize;
  out vec2 tileUV;
#endif

void main() {

  #ifdef ENABLE_PARALLAX_SUBSURFACE
    pos = Position + ChunkOffset;
  #else
    vec3 pos = Position + ChunkOffset;
  #endif

  gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

  vertexDistance = fog_distance(ModelViewMat, pos, FogShape);
  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
  normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
  glpos = gl_Position;

  #ifdef ENABLE_PARALLAX_SUBSURFACE
    wnorm = Normal;
    tileSize = vec2(32) / vec2(textureSize(Sampler0, 0));

    vec2 tileScaleTexCoord = texCoord0 / tileSize;
    vec2 distTLTileVert = tileScaleTexCoord - floor(tileScaleTexCoord);
    int vidm4 = gl_VertexID % 4;
    tileUV = mix(distTLTileVert, vec2(1), ivec2(int((vidm4 == 2 || vidm4 == 3) && distTLTileVert.x < 0.001), int((vidm4 == 1 || vidm4 == 2) && distTLTileVert.y < 0.001)));
  #endif
}
