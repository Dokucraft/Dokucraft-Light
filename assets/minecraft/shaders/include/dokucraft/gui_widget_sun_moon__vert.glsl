#version 330

#moj_import <dokucraft:flavor.glsl>
#moj_import <dokucraft:config.glsl>
#moj_import <minecraft:mob_effects.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;

uniform sampler2D Sampler0;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out mat4 ProjInv;
out vec3 cscale;
out vec2 texCoord0;
out vec4 vertexColor;

#ifdef ENABLE_CUSTOM_SKY
  out vec3 c1;
  out vec3 c2;
  out vec3 c3;
  out float isSun;
#endif

#ifdef ENABLE_MOB_EFFECTS
  flat out int mobEffect;
  flat out float time;
  out vec4 glpos;
  out vec2 rectA;
  out vec2 rectB;
  out vec2 texRectA;
  out vec2 texRectB;
#endif

#ifdef ENABLE_POST_MOON
  flat out float moonPhase;
#endif

#define SUNSIZE 60
#define SUNDIST 110
#define OVERLAYSCALE 2.0

void main() {
  vec4 candidate = ProjMat * ModelViewMat * vec4(Position, 1.0);
  texCoord0 = UV0;
  vertexColor = Color;
  #ifdef ENABLE_CUSTOM_SKY
    ProjInv = mat4(0.0);
    cscale = vec3(0.0);
    c1 = vec3(0.0);
    c2 = vec3(0.0);
    c3 = vec3(0.0);
    isSun = 0.0;
    ivec2 tsize = textureSize(Sampler0, 0);

    // Sun or moon
    if (Position.y < SUNDIST  && Position.y > -SUNDIST && (ModelViewMat * vec4(Position, 1.0)).z > -SUNDIST) {

      // only the sun has a 64x64 texture
      if (tsize.x == 64 && tsize.y == 64) {
        isSun = 1.0;
        candidate = vec4(-2.0 * OVERLAYSCALE, -OVERLAYSCALE, 0.0, 1.0);

        // modify position of sun so that it covers the entire screen and store c1, c2, c3 so player space position of sun can be extracted in fsh.
        // this is the key to get everything working since it guarantees that we can access sun info in the control pixels in fsh.
        if (UV0.x < 0.5) {
          c1 = Position;
          cscale.x = 1.0;
        } else {
          candidate.x = OVERLAYSCALE;
          if (UV0.y < 0.5) {
            c2 = Position;
            cscale.y = 1.0;
          } else {
            candidate.y = 2.0 * OVERLAYSCALE;
            c3 = Position;
            cscale.z = 1.0;
          }
        }
        ProjInv = inverse(ProjMat * ModelViewMat);
      } else if (tsize.x == tsize.y * 2) { // Moon
        isSun = 0.5;

        #ifdef ENABLE_POST_MOON
          candidate = vec4(-2.0 * OVERLAYSCALE, -OVERLAYSCALE, 0.0, 1.0);

          int vidm4 = gl_VertexID % 4;
          if (vidm4 == 2) {
            moonPhase = UV0.x / 2.0 + UV0.y;
            candidate.x = OVERLAYSCALE;
            candidate.y = 2.0 * OVERLAYSCALE;
          } else if (vidm4 == 1) {
            candidate.x = OVERLAYSCALE;
          }
        #endif
      }
    }

    #ifdef ENABLE_BUTTON_GRADIENTS
      else {
    #endif
  #endif

  #ifdef ENABLE_BUTTON_GRADIENTS
    const vec2[] corners = vec2[](vec2(0), vec2(0, 1), vec2(1), vec2(1, 0));
    vec2 corner = corners[gl_VertexID % 4];
    
    cscale = vec3(corner, 1);
    #ifdef ENABLE_CUSTOM_SKY
      }
    #endif
  #endif

  gl_Position = candidate;

  #ifdef ENABLE_MOB_EFFECTS
    mobEffect = 0;

    // Isolate mob effect icons
    if (gl_Position.x > 0.8334 && tsize == ivec2(512, 256)) {
      int vx = int(gl_VertexID % 4 >= 2);
      int vy = (gl_VertexID % 4 - vx) % 2;
      vec2 v = vec2(vx, vy);
      vec4 tcol = texture(Sampler0, texCoord0 - v / vec2(tsize));
      int tcbf = int(floor(tcol.b * 255.0 + 0.5));

      if (
        // Double-check that this is definitely a mob effect icon, otherwise
        // this can break the moon if it is positioned correctly
        ivec2(floor(tcol.ra * 255.0 + 0.5)) == ivec2(241, 16)

        // Make sure that this specific effect is enabled so that the icon
        // won't get stretched to cover the screen if it's not
        && (false
          #ifdef ENABLE_DARKNESS_EFFECT
            || tcbf == 215
          #endif

          #ifdef ENABLE_WITHER_EFFECT
            || tcbf == 216
          #endif

          #ifdef ENABLE_SPEED_EFFECT
            || tcbf == 217
          #endif
        )
      ) {
        vec2 omv = vec2(1) - v;
        rectA = gl_Position.xy * omv;
        rectB = gl_Position.xy * v;
        texRectA = texCoord0 * omv;
        texRectB = texCoord0 * v;
        texCoord0 = v;
        gl_Position.xy = vec2(vx, 1 - vy) * 2 - 1;
        time = tcol.g;

        if (tcbf == 215) {
          mobEffect = EFFECT_DARKNESS;
        } else if (tcbf == 216) {
          mobEffect = EFFECT_WITHER;
        } else if (tcbf == 217) {
          mobEffect = EFFECT_SPEED;
        }
      }
    }
    glpos = gl_Position;
  #endif
}
