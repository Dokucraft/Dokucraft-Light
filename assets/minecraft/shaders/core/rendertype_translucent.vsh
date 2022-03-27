#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <../config.txt>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

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

#if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR)
  out float fresnel;
#endif

void main() {
  vec3 pos = Position + ChunkOffset;
  gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

  vertexDistance = fog_distance(ModelViewMat, pos, FogShape);
  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
  normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);

  #if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR)
    fresnel = 1.0 - abs(dot(normalize(-pos), Normal));
    fresnel *= fresnel;
  #endif
}
