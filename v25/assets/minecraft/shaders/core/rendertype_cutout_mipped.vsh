#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <wave.glsl>
#moj_import <../flavor.glsl>

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

#if GRASS_TYPE > 0
  flat out int type;
#endif

#if GRASS_TYPE == 2
  out vec3 shellGrassUV;
#endif

void main() {
  vec3 position = Position + ChunkOffset;

  #if defined(ENABLE_WAVING) || defined(ENABLE_LANTERN_SWING) || GRASS_TYPE > 0
    vec4 col = textureLod(Sampler0, UV0, 0);
    int alpha = int(col.a * 255 + 0.5);

    #if GRASS_TYPE == 1
      if (alpha == 211 || alpha == 212) {
        type = 1;
        int face = int(alpha - 211);
        int topHalf = int(fract(Position.y) == 0.9375);
        int vidm4 = gl_VertexID % 4;
        ivec2 vidv = ivec2(int(vidm4 > 1), int(vidm4 == 1 || vidm4 == 2));
        float fov = 360.0 / PI * atan(1.0 / ProjMat[1][1]);

        // For face 1, rotate both the vertex ID vector and the position
        vidv = ivec2(mat3(
          1 - face, face, 0,
          -face, 1 - face, 0,
          face, 0, 1
        ) * vec3(vidv, 1));
        position.xz += LOW_POLY_GRASS_WIDTH * vec2(
          (vidv.x * 2 - 1) * (vidv.x ^ vidv.y),
          (vidv.y * 2 - 1) * (1 - (vidv.x ^ vidv.y))
        ) * face;

        // For two of the squares, swap position of the points (0,0) and (1,1)
        position.xz += LOW_POLY_GRASS_WIDTH * -(vidv * 2 - 1) * (1 - (vidv.x ^ vidv.y)) * (topHalf ^ face);

        // Scale and rotate based on texture
        int omcxo = 1 - (vidv.x ^ vidv.y);
        int fb = (omcxo * (1 - face)) ^ (1 - topHalf) * omcxo;
        vec2 bladePos = vec2(vidv ^ fb);
        float btt = col.b * 2 * PI;
        float bts = sin(btt);
        float btc = cos(btt);
        float scale = mix(0.35, 0.75, col.r) + smoothstep(0, mix(160, 32, smoothstep(40, 80, fov)), length(position)) * 0.6;
        position.xz += (mat2(btc, -bts, bts, btc) * (bladePos * 2 - 1) * scale - bladePos) * LOW_POLY_GRASS_WIDTH;

        float offsetY = (int(vidv.x != 1 || vidv.y != 0) ^ topHalf) * 0.5 + 0.5 * topHalf;

        #ifdef ENABLE_WAVING
          float time = fract(GameTime * 600);
          float fn = smoothstep(0, 1, flownoise(position * 0.5));
          float animMult = mix(0.5, 1.0, fn) * 0.1 * smoothstep(0.2, 2, length(position * vec3(1, 0.5, 1))) * offsetY;
          vec2 anim = waveXZ(position, GameTime) * animMult;
          position.xz += anim;
        #endif

        position.y += 0.0625 * (2 - topHalf) + offsetY * LOW_POLY_GRASS_HEIGHT * mix(0.5, 1.5, col.g);

        gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
        glpos = gl_Position;

        vertexColor = vec4(
          Color.rgb * GRASS_COLOR_MULTIPLIER * mix(
            0.596,
            #ifdef ENABLE_WAVING
              mix(
                0.9,
                1.2,
                smoothstep(-0.1, 0.1, anim.x)
              ),
            #else
              1,
            #endif
            offsetY
          ),
          Color.a
        ) * minecraft_sample_lightmap(Sampler2, UV2);

        vertexDistance = fog_distance(position, FogShape);
        texCoord0 = UV0;
        normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);

        return;
      }
    #elif GRASS_TYPE == 2
      if (alpha == 211) {
        // This and sparse grass are mutually exclusive, so reusing type=1 is fine here
        type = 1;
        shellGrassUV = vec3(
          Position.xz * DENSE_GRASS_BLADES_PER_BLOCK,
          fract(Position.y) / 0.15625
        );

        #ifdef ENABLE_WAVING
          float time = fract(GameTime * 600);
          float fn = smoothstep(0, 1, flownoise(position * 0.5));
          float animMult = mix(0.5, 1.0, fn) * 0.1 * smoothstep(0.2, 2, length(position * vec3(1, 0.5, 1))) * shellGrassUV.z;
          vec2 anim = waveXZ(position, GameTime) * animMult;
        #endif

        vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
        vertexColor.rgb *= GRASS_COLOR_MULTIPLIER * mix(
          0.71,
          1.5,
          shellGrassUV.z
          #ifdef ENABLE_WAVING
            * (0.3 + smoothstep(-0.1, 0.1, anim.x) * 0.7)
          #else
            * 0.667
          #endif
        );
        #ifdef ENABLE_WAVING
          position.xz += anim;
        #endif

        gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
        vertexDistance = fog_distance(position, FogShape);
        texCoord0 = UV0;
        normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
        glpos = gl_Position;
        return;
      }
    #endif
    #if defined(ENABLE_LANTERN_SWING) && GRASS_TYPE > 0
      else
    #endif
    #ifdef ENABLE_LANTERN_SWING
      // Lanterns in vanilla use the cutout shader, but with Optifine they use cutout mipped
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
    #if defined(ENABLE_WAVING) && (defined(ENABLE_LANTERN_SWING) || GRASS_TYPE > 0)
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

    #if GRASS_TYPE > 0
      type = 0;
    #endif
  #endif
  gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
  vertexDistance = fog_distance(position, FogShape);

  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
  glpos = gl_Position;
}
