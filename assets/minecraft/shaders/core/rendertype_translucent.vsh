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

#if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR)
  #ifdef ENABLE_FRAGMENT_FRESNEL
    out vec3 wpos;
    out vec3 wnorm;
  #else
    out float fresnel;
  #endif
#endif

void main() {
  #if defined(ENABLE_FRESNEL_EFFECT) || defined(ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR)
    #ifdef ENABLE_FRAGMENT_FRESNEL
      wpos = Position + ChunkOffset;
      wnorm = Normal;
    #else
      vec3 wpos = Position + ChunkOffset;
      fresnel = 1.0 - abs(dot(normalize(-wpos), Normal));
      fresnel *= fresnel;
    #endif
  #else
    vec3 wpos = Position + ChunkOffset;
  #endif

  gl_Position = ProjMat * ModelViewMat * vec4(wpos, 1.0);

  vertexDistance = fog_distance(wpos, FogShape);
  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
}
