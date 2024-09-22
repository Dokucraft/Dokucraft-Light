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

#ifdef ENABLE_MOB_EFFECTS
  flat out int mobEffect;
  flat out float time;
  out vec4 glpos;
  out vec2 rectA;
  out vec2 rectB;
  out vec2 texRectA;
  out vec2 texRectB;
#endif

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
  ProjInv = mat4(0.0);
  cscale = vec3(0.0);
  ivec2 tsize = textureSize(Sampler0, 0);
  texCoord0 = UV0;
  vertexColor = Color;

  #ifdef ENABLE_BUTTON_GRADIENTS
    const vec2[] corners = vec2[](vec2(0), vec2(0, 1), vec2(1), vec2(1, 0));
    vec2 corner = corners[gl_VertexID % 4];
    
    cscale = vec3(corner, 1);
  #endif

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
