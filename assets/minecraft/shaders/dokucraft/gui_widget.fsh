#version 330

#moj_import <dokucraft:flavor.glsl>
#moj_import <dokucraft:config.glsl>
#moj_import <minecraft:mob_effects.glsl>

uniform sampler2D Sampler0;
uniform vec4 ColorModulator;
uniform vec2 ScreenSize;
uniform mat4 ModelViewMat;

in mat4 ProjInv;
in vec3 cscale;
in vec2 texCoord0;
in vec4 vertexColor;

#ifdef ENABLE_MOB_EFFECTS
  flat in int mobEffect;
  flat in float time;
  in vec4 glpos;
  in vec2 rectA;
  in vec2 rectB;
  in vec2 texRectA;
  in vec2 texRectB;
#endif

out vec4 fragColor;

#ifdef ENABLE_MOB_EFFECTS

  #if defined(ENABLE_DARKNESS_EFFECT) || defined(ENABLE_WITHER_EFFECT)
    #define TAU 6.28318530718
    #define TILING_FACTOR 1.0
    #define MAX_ITER 4

    float caustic(vec2 p, float time, float alpha) {
      vec2 i = vec2(p);
      float c = 0.0;
      float af = mix(1.0, 6.0, alpha);
      float inten = .005 * af;

      for (int n = 0; n < MAX_ITER; n++) {
        float t = time * (1.0 - (3.5 / float(n+1)));
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0/length(vec2(p.x / (sin(i.x+t)),p.y / (cos(i.y+t))));
      }
      c = 0.2 + c / (inten * float(MAX_ITER));
      c = 1.17-pow(c, 1.4);
      c = pow(abs(c), 8.0);
      return c / sqrt(af);
    }
  #endif

  #ifdef ENABLE_DARKNESS_EFFECT
    vec4 darknessEffect(float time) {
      float distCenter = pow(2.0*length(texCoord0 - 0.5), 2.0);
      float alpha = smoothstep(0.4, 1.8, distCenter);

      vec2 p = mod(texCoord0*TAU*TILING_FACTOR, TAU)-250.0;
      float c = caustic(p, time, alpha);

      float a = c * (0.05 + 0.95 * smoothstep(0.2, 0.9, distCenter));
      return vec4(mix(vec3(0, 0, 0), vec3(0.1, 0.2, 0.2), pow(a, 2)), a);
    }
  #endif

  #ifdef ENABLE_WITHER_EFFECT
    vec4 witherEffect(float time) {
      float distCenter = pow(2.0*length(texCoord0 - 0.5), 2.0);
      float alpha = smoothstep(0.4, 1.8, distCenter);

      vec2 p = mod(texCoord0*TAU*TILING_FACTOR, TAU)-250.0;
      float c = caustic(p, 115.86, alpha);

      float beat1 = pow((sin(time*TAU*6    ) + 1) * 0.5, 10);
      float beat2 = pow((sin(time*TAU*6+1.8) + 1) * 0.5, 10);

      float a = pow(c * (0.05 + 0.95 * smoothstep(0.2, 0.9, distCenter)), 2.0 - beat1 - beat2);
      return vec4(mix(vec3(140.0/255.0, 0, 55.0/255.0), vec3(200.0/255.0, 15.0/255.0, 0), a), a);
    }
  #endif

  #ifdef ENABLE_SPEED_EFFECT
    float rand(vec2 n) {return fract(sin(dot(n,vec2(12.9898,12.1414)))*83758.5453);}
    float fnoise(vec2 n) {
      const vec2 d = vec2(0.0, 1.0);
      vec2 b = floor(n);
      vec2 f = vec2(smoothstep(0.0, 1.0, fract(n)));
      return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
    }
    float fire(vec2 n) {return fnoise(n) + fnoise(n * 2.3)*0.31 + fnoise(n * 5.7)*0.41;}

    vec2 polar(vec2 uv, float shift) {
      float px = atan(uv.y, uv.x) + shift;
      float py = length(uv);
      return vec2(px, py);
    }

    float shade(vec2 uv, float t) {
      uv.y *= -0.1;
      uv.x *= 5.3;
      float q = fire(uv - t);
      vec2 r = vec2(fire(uv - q - t - uv.x - uv.y), fire(uv + q + t));
      return 2 - r.y;
    }

    vec4 speedEffect(float time) {
      vec2 uv = texCoord0;
      uv = polar(vec2(0.5) - uv, 1.3);
      float c = shade(uv, time);

      float d = length(texCoord0 - 0.5);
      c = pow(c*d*d,2.6);

      return vec4(1, 1, 1, c);
    }
  #endif

#endif


void main() {
  #ifdef ENABLE_MOB_EFFECTS
    if (mobEffect > 0) {
      vec2 omtc0 = vec2(1) - texCoord0;
      vec2 rA = rectA / omtc0;
      vec2 rB = rectB / texCoord0;
      vec2 rMin = min(rA, rB);
      vec2 rMax = max(rA, rB);
      vec2 tF = abs(glpos.xy - rA) / abs(rB - rA);
      vec4 tCol = texture(Sampler0, texRectA / omtc0 * (vec2(1) - tF) + texRectB / texCoord0 * tF);

      if (glpos.x >= rMin.x && glpos.x <= rMax.x && glpos.y >= rMin.y && glpos.y <= rMax.y && tCol.a >= 0.99) {
        gl_FragDepth = gl_FragCoord.z;
        fragColor = tCol;
      } else {
        // Force the screen effect to be behind all other UI elements
        gl_FragDepth = 1.0;

        if (mobEffect == EFFECT_DARKNESS) {
          #ifdef ENABLE_DARKNESS_EFFECT
            fragColor = mix(darknessEffect(time+1181), darknessEffect(time+1180), smoothstep(0.2, 0.8, time));
          #endif
        } else if (mobEffect == EFFECT_WITHER) {
          #ifdef ENABLE_WITHER_EFFECT
            fragColor = witherEffect(time);
          #endif
        } else if (mobEffect == EFFECT_SPEED) {
          #ifdef ENABLE_SPEED_EFFECT
            fragColor = mix(speedEffect(time*4), speedEffect((time-1)*4), smoothstep(0.2, 0.8, time));
          #endif
        }
      }
      return;
    }
  #endif

  vec4 color = vec4(0.0);

  #ifdef ENABLE_BUTTON_GRADIENTS
    color = texture(Sampler0, texCoord0);

    if (int(color.a * 255 + 0.5) == 252) {
      float cs = cscale.x / 2;

      if (color.g >= 0.99)
        cs += 0.5;

      if (color.b >= 0.99)
        cs = 0.5;

      cs = color.r >= 0.99 ? cs : 1 - cs;

      color.rgb = mix(BUTTON_GRADIENT_COLOR_A, BUTTON_GRADIENT_COLOR_B, clamp(cs, 0, 1));
    }

    color *= ColorModulator * vertexColor;
  #else
    color = texture(Sampler0, texCoord0) * ColorModulator * vertexColor;
  #endif

  if (color.a < 0.01 || ivec2(floor(color.ra * 255.0 + 0.5)) == ivec2(241, 16)) {
    discard;
  }
  fragColor = color;
}
