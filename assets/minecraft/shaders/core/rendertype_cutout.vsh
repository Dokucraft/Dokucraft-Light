#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <wave.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;
uniform sampler2D Sampler0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;
uniform float GameTime;
uniform int FogShape;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

void main() {
  vec3 position = Position + ChunkOffset;

  #if defined(ENABLE_WAVING) || defined(ENABLE_LANTERN_SWAY)
    int alpha = int(textureLod(Sampler0, UV0, 0).a * 255 + 0.5);

    if (alpha == 141 || alpha == 24) {
      #ifdef ENABLE_LANTERN_SWAY
        float time = (1.0 + fract(dot(floor(Position), vec3(1))) / 2.0) * GameTime * SWAYING_SPEED + dot(floor(Position), vec3(1)) * 1234.0;
        vec3 newForward = normalize(vec3(
          sin(time) * SWAYING_AMOUNT,
          sin(time * PHI) * SWAYING_AMOUNT,
          -1 + sin(time * 3.14) * SWAYING_AMOUNT
        ));

        vec3 relativePos = fract(Position);
        if (relativePos.y > EPSILON) {
          relativePos -= vec3(0.5, 1, 0.5);
          relativePos = tbn(newForward, vec3(0, 1, 0)) * relativePos;
          vec4 swayedPos = vec4(floor(Position) + relativePos + vec3(0.5, 1, 0.5) + ChunkOffset, 1.0);
          gl_Position = ProjMat * ModelViewMat * swayedPos;
          vertexDistance = fog_distance(ModelViewMat, swayedPos.xyz, FogShape);
        }
      #else
        gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
        vertexDistance = fog_distance(ModelViewMat, position, FogShape);
      #endif
    } else {
      #ifdef ENABLE_WAVING
        float xs = 0.0;
        float zs = 0.0;
        float animation = GameTime * 4000.0;
        if (alpha == 18 || alpha == 253 ) {
          xs = rsin((position.x + position.y + animation) / 2) * -1.0;
          zs = rcos((position.z + position.y + animation) / 2) * -1.0;
        } else if (alpha == 19 || alpha == 252 ) {
          xs = rsin((position.x + position.y + animation) / 2) * -2.0;
          zs = rcos((position.z + position.y + animation) / 2) * -2.0;
        } else if (alpha == 20 || alpha == 254 ) {
          xs = rsin((position.x + position.y + animation) / 2) * -0.5;
          zs = rcos((position.z + position.y + animation) / 2) * -0.5;
        } else if (alpha == 22) { // very weak, delayed sway used for the bottom of the torch fire
          xs = rsin((position.x + position.y + animation) / 2 - 1.0) * -0.5;
          zs = rcos((position.z + position.y + animation) / 2 - 1.0) * -0.5;
        }
        vec4 wavedPos = vec4(position, 1.0) + vec4(xs / 32.0, 0, zs / 32.0, 0.0);
        gl_Position = ProjMat * ModelViewMat * wavedPos;
        vertexDistance = fog_distance(ModelViewMat, wavedPos.xyz, FogShape);
      #else
        gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
        vertexDistance = fog_distance(ModelViewMat, position, FogShape);
      #endif
    }
  #else
    gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
    vertexDistance = fog_distance(ModelViewMat, position, FogShape);
  #endif

  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
  normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
  glpos = gl_Position;
}
