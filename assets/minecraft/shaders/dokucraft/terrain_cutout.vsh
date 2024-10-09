#version 330

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:wave.glsl>
#moj_import <dokucraft:config.glsl>
#moj_import <dokucraft:flavor.glsl>

#ifdef ENABLE_BETTER_LAVA
  #moj_import <minecraft:snoise.glsl>
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
uniform vec3 ModelOffset;
uniform float GameTime;
uniform int FogShape;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 glpos;

// Some things only need to be checked for solid blocks, and some only for
// cutout blocks, so use some logic to redefine the config options here so they
// are easier to use later in the script.
#ifdef SOLID
  #define USE_GRASS_TYPE 0
  #ifdef ENABLE_BETTER_LAVA
    #define USE_BETTER_LAVA
  #endif
#else
  #define USE_GRASS_TYPE GRASS_TYPE
  #ifdef ENABLE_LANTERN_SWING
    #define USE_LANTERN_SWING
  #endif
#endif

#if defined(USE_BETTER_LAVA) || USE_GRASS_TYPE > 0
  flat out int type;
#endif

#if USE_GRASS_TYPE == 2 || USE_GRASS_TYPE == 3
  out vec3 shellGrassUV;
#endif

#ifdef USE_BETTER_LAVA
  out float noiseValue;
  out vec2 tileUVLava;

  flat out int randomTile;
#endif

#ifdef ENABLE_PARALLAX_SUBSURFACE
  out vec3 pos;
  out vec3 wnorm;
  out vec2 tileUVPara;
#endif

#if (defined(USE_BETTER_LAVA)) || defined(ENABLE_PARALLAX_SUBSURFACE)
  flat out vec2 tileSize;
#endif

void main() {
  #if defined(ENABLE_PARALLAX_SUBSURFACE) || (defined(USE_BETTER_LAVA)) || USE_GRASS_TYPE == 1
    int vidm4 = gl_VertexID % 4;
  #endif

  #if defined(ENABLE_PARALLAX_SUBSURFACE) || (defined(USE_BETTER_LAVA))
    tileSize = vec2(32) / vec2(textureSize(Sampler0, 0));
  #endif

  #ifdef ENABLE_PARALLAX_SUBSURFACE
    pos = Position + ModelOffset;
  #else
    vec3 pos = Position + ModelOffset;
  #endif

  #if defined(ENABLE_WAVING) || defined(USE_LANTERN_SWING) || defined(USE_BETTER_LAVA) || USE_GRASS_TYPE > 0
    vec4 col = textureLod(Sampler0, UV0, 0);
    int alpha = int(col.a * 255 + 0.5);

    #if USE_GRASS_TYPE == 1
      if (alpha == 211 || alpha == 212) {
        type = 1;
        int face = int(alpha - 211);
        int topHalf = int(fract(Position.y) == 0.9375);
        ivec2 vidv = ivec2(int(vidm4 > 1), int(vidm4 == 1 || vidm4 == 2));
        float fov = 360.0 / PI * atan(1.0 / ProjMat[1][1]);

        // For face 1, rotate both the vertex ID vector and the position
        vidv = ivec2(mat3(
          1 - face, face, 0,
          -face, 1 - face, 0,
          face, 0, 1
        ) * vec3(vidv, 1));
        pos.xz += LOW_POLY_GRASS_WIDTH * vec2(
          (vidv.x * 2 - 1) * (vidv.x ^ vidv.y),
          (vidv.y * 2 - 1) * (1 - (vidv.x ^ vidv.y))
        ) * face;

        // For two of the squares, swap position of the points (0,0) and (1,1)
        pos.xz += LOW_POLY_GRASS_WIDTH * -(vidv * 2 - 1) * (1 - (vidv.x ^ vidv.y)) * (topHalf ^ face);

        // Scale and rotate based on texture
        int omcxo = 1 - (vidv.x ^ vidv.y);
        int fb = (omcxo * (1 - face)) ^ (1 - topHalf) * omcxo;
        vec2 bladePos = vec2(vidv ^ fb);
        float btt = col.b * 2 * PI;
        float bts = sin(btt);
        float btc = cos(btt);
        float scale = mix(0.35, 0.75, col.r) + smoothstep(0, mix(160, 32, smoothstep(40, 80, fov)), length(pos)) * 0.6;
        pos.xz += (mat2(btc, -bts, bts, btc) * (bladePos * 2 - 1) * scale - bladePos) * LOW_POLY_GRASS_WIDTH;

        float offsetY = (int(vidv.x != 1 || vidv.y != 0) ^ topHalf) * 0.5 + 0.5 * topHalf;

        #ifdef ENABLE_WAVING
          float time = fract(GameTime * 600);
          float fn = smoothstep(0, 1, flownoise(pos * 0.5));
          float animMult = mix(0.5, 1.0, fn) * 0.1 * smoothstep(0.2, 2, length(pos * vec3(1, 0.5, 1))) * offsetY;
          vec2 anim = waveXZ(pos, GameTime) * animMult;
          pos.xz += anim;
        #endif

        pos.y += 0.0625 * (2 - topHalf) + offsetY * LOW_POLY_GRASS_HEIGHT * mix(0.5, 1.5, col.g);

        gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
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

        vertexDistance = fog_distance(pos, FogShape);
        texCoord0 = UV0;

        return;
      }
    #elif USE_GRASS_TYPE == 2 || USE_GRASS_TYPE == 3
      if (alpha == 211) {
        // This and low-poly grass are mutually exclusive, so reusing type=1 is fine here
        type = 1;
        shellGrassUV = vec3(
          Position.xz * DENSE_GRASS_BLADES_PER_BLOCK,
          fract(Position.y) / 0.15625
        );

        #ifdef ENABLE_WAVING
          float time = fract(GameTime * 600);
          float fn = smoothstep(0, 1, flownoise(pos * 0.5));
          float animMult = mix(0.5, 1.0, fn) * 0.1 * smoothstep(0.2, 2, length(pos * vec3(1, 0.5, 1))) * shellGrassUV.z;
          vec2 anim = waveXZ(pos, GameTime) * animMult;
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
          pos.xz += anim;
        #endif

        gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
        vertexDistance = fog_distance(pos, FogShape);
        texCoord0 = UV0;
        glpos = gl_Position;
        return;
      }
    #endif

    #if defined(USE_LANTERN_SWING) && USE_GRASS_TYPE > 0
      else
    #endif

    #ifdef USE_LANTERN_SWING
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
          pos = floor(Position) + relativePos + vec3(0.5, 1, 0.5) + ModelOffset;
        }
      }
    #endif

    #if defined(ENABLE_WAVING) && defined(USE_LANTERN_SWING) || USE_GRASS_TYPE > 0
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
        pos.xz += waveXZ(pos, time) * 0.03125 * animMult;
      }
    #endif

    #if defined(USE_BETTER_LAVA) && defined(ENABLE_WAVING)
      else
    #endif

    #ifdef USE_BETTER_LAVA
      if (alpha == 247) {
        tileUVLava = vec2(int(vidm4 == 2 || vidm4 == 3), int(vidm4 == 1 || vidm4 == 2));
        if (pos.y >= 0) {
          tileUVLava.y = 1.0 - tileUVLava.y;
        }

        vec3 xzp = Position + vec3(ModelOffset.x, 0, ModelOffset.z);
        float animation = GameTime * 40.0;
        noiseValue = clamp(0.5 + (
          snoise(vec4(xzp / 32.0, animation)) +
          snoise(vec4(xzp / 16.0, animation * 3.0)) * 0.67 +
          snoise(vec4(xzp / 8.0, animation * 2.6)) * 0.33
        ) / 2, 0.0, 1.0);
        randomTile = int((0.5 + snoise(floor(Position + vec3(0.5)) - vec3(tileUVLava.x, 38971, tileUVLava.y)) * 0.5) * 14863.8924) % LAVA_VARIANT_COUNT;
        type = 2;
        gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
        vertexDistance = fog_distance(pos, FogShape);
        vertexColor = Color;
        lightColor = minecraft_sample_lightmap(Sampler2, UV2);
        texCoord0 = UV0;
        glpos = gl_Position;
        return;
      }
    #endif

    #if USE_GRASS_TYPE > 0 || defined(USE_BETTER_LAVA)
      type = 0;
    #endif
  #endif

  gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
  vertexDistance = fog_distance(pos, FogShape);
  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
  glpos = gl_Position;

  #ifdef ENABLE_PARALLAX_SUBSURFACE
    wnorm = Normal;
    vec2 tileScaleTexCoord = texCoord0 / tileSize;
    vec2 distTLTileVert = tileScaleTexCoord - floor(tileScaleTexCoord);
    tileUVPara = mix(distTLTileVert, vec2(1), ivec2(int((vidm4 == 2 || vidm4 == 3) && distTLTileVert.x < 0.001), int((vidm4 == 1 || vidm4 == 2) && distTLTileVert.y < 0.001)));
  #endif
}
