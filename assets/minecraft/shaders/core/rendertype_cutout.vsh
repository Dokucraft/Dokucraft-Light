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
out vec4 glpos;

void main() {
  vec3 position = Position + ChunkOffset;

  #if defined(ENABLE_WAVING) || defined(ENABLE_LANTERN_SWING)
    int alpha = int(textureLod(Sampler0, UV0, 0).a * 255 + 0.5);

    #ifdef ENABLE_LANTERN_SWING
      if (alpha == 141 || alpha == 24) {
        float time = (1.0 + fract(dot(floor(Position), vec3(1))) / 2.0) * GameTime * SWING_SPEED + dot(floor(Position), vec3(1)) * 1234.0;
        vec3 newForward = normalize(vec3(
          sin(time) * SWING_AMOUNT,
          sin(time * PHI) * SWING_AMOUNT,
          -1 + sin(time * 3.14) * SWING_AMOUNT
        ));

        vec3 relativePos = fract(Position);
        if (relativePos.y > EPSILON) {
          relativePos -= vec3(0.5, 1, 0.5);
          relativePos = tbn(newForward, vec3(0, 1, 0)) * relativePos;
          position = floor(Position) + relativePos + vec3(0.5, 1, 0.5) + ChunkOffset;
        }
      }
    #endif
    #if defined(ENABLE_WAVING) && defined(ENABLE_LANTERN_SWING)
      else
    #endif
    #ifdef ENABLE_WAVING
      if ((alpha >= 18 && alpha <= 20) || (alpha >= 252 && alpha <= 254) || alpha == 22) {
        float animMult =
          int(alpha == 18 || alpha == 253) +
          int(alpha == 19 || alpha == 252) * 2 +
          int(alpha == 20 || alpha == 254 || alpha == 22) * 0.5
        ;
        float time = GameTime - int(alpha == 22) * 2000;
        position.xz += waveXZ(position, time) * 0.03125 * animMult;
      }
    #endif
  #endif
  gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
  vertexDistance = fog_distance(position, FogShape);

  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
  glpos = gl_Position;
}
