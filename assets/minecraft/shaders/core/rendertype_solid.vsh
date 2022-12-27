#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <../config.txt>

#ifdef ENABLE_BETTER_LAVA
  #moj_import <snoise.glsl>
#endif

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

#ifdef ENABLE_BETTER_LAVA
  uniform float GameTime;
#endif

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

#ifdef ENABLE_BETTER_LAVA
  out float noiseValue;
  out vec2 tileUVLava;

  flat out int randomTile;
#endif

#ifdef ENABLE_PARALLAX_SUBSURFACE
  out vec3 pos;
  out vec3 wnorm;
  out vec2 tileUVPara;

  flat out vec2 tileSize;
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

  #if defined(ENABLE_PARALLAX_SUBSURFACE) || defined(ENABLE_BETTER_LAVA)
    int vidm4 = gl_VertexID % 4;
  #endif

  #ifdef ENABLE_PARALLAX_SUBSURFACE
    wnorm = Normal;
    tileSize = vec2(32) / vec2(textureSize(Sampler0, 0));

    vec2 tileScaleTexCoord = texCoord0 / tileSize;
    vec2 distTLTileVert = tileScaleTexCoord - floor(tileScaleTexCoord);
    tileUVPara = mix(distTLTileVert, vec2(1), ivec2(int((vidm4 == 2 || vidm4 == 3) && distTLTileVert.x < 0.001), int((vidm4 == 1 || vidm4 == 2) && distTLTileVert.y < 0.001)));
  #endif

  #ifdef ENABLE_BETTER_LAVA
    tileUVLava = vec2(int(vidm4 == 2 || vidm4 == 3), int(vidm4 == 1 || vidm4 == 2));
    if (pos.y >= 0) {
      tileUVLava.y = 1.0 - tileUVLava.y;
    }

    vec3 xzp = Position + vec3(ChunkOffset.x, 0, ChunkOffset.z);
    float animation = GameTime * 40.0;
    noiseValue = clamp(0.5 + (
      snoise(vec4(xzp / 32.0, animation)) +
      snoise(vec4(xzp / 16.0, animation * 3.0)) * 0.67 +
      snoise(vec4(xzp / 8.0, animation * 2.6)) * 0.33
    ) / 2, 0.0, 1.0);
    randomTile = int((0.5 + snoise(floor(Position + vec3(0.5)) - vec3(tileUVLava.x, 38971, tileUVLava.y)) * 0.5) * 14863.8924) % LAVA_VARIANT_COUNT;
  #endif
}
