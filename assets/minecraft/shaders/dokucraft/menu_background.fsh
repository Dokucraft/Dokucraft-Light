#version 330

#moj_import <dokucraft:config.glsl>
#moj_import <dokucraft:flavor.glsl>

uniform sampler2D MainSampler;

in vec2 texCoord;
in vec2 oneTexel;

out vec4 fragColor;

#if MENU_BACKGROUND >= 1
  // https://alienryderflex.com/hsp.html
  float perceivedBrightness(vec3 color) {
    vec3 c = color * color * vec3(0.299, 0.587, 0.114);
    return c.r + c.g + c.b;
  }
#endif

#if MENU_BACKGROUND == 2
  #moj_import <minecraft:flownoise.glsl>

  const int thresholds[8] = int[8](0, 4, 2, 6, 1, 5, 3, 7);

  float dither(float value, vec2 pos) {
    pos.x += sin((pos.x + pos.y) / 64.0) * 8.0;
    pos.x += cos((pos.x - pos.y) / 16.0) * 8.0;
    value = smoothstep(0.2, 0.6, value);
    value = pow(value, 1.0/3.0);
    value += hash12(pos) * 0.2 - 0.1;
    float q = mod(pos.x - pos.y, 64) / 64;
    int r = min(int(value * 8.0) + thresholds[int(q * 8.0)], 8);
    return float(int(value > 0.1 && r > 6));
  }

  float colorDifference(vec3 c1, vec3 c2) {
    vec3 delta = c1 - c2;
    return sqrt(dot(delta * vec3(0.299, 0.587, 0.114), delta));
  }
#endif

void main() {
  vec4 color = texture(MainSampler, texCoord);

  #if MENU_BACKGROUND == 0
    fragColor = color;

  #else
    float l = perceivedBrightness(color.rgb);
    #if MENU_BACKGROUND == 1
      fragColor = vec4(mix(vec3(l), color.rgb, MENU_BACKGROUND_SATURATION) * MENU_BACKGROUND_BRIGHTNESS, color.a);

    #elif MENU_BACKGROUND == 2
      // Sketch filter
      vec4 c1 = texture(MainSampler, texCoord + vec2(oneTexel.x, 0));
      vec4 c2 = texture(MainSampler, texCoord + vec2(0, oneTexel.y));
      float l1 = perceivedBrightness(c1.rgb);
      float l2 = perceivedBrightness(c2.rgb);
      float acc = max(abs(l - l1), abs(l - l2));
      acc = max(acc, colorDifference(color.rgb, c1.rgb));
      acc = max(acc, colorDifference(color.rgb, c2.rgb));
      float cdf = smoothstep(0.8, 1.1, length(texCoord - 0.5) * 2.0 + sin(atan(texCoord.y - 0.5, texCoord.x - 0.5) * 10.0) / 20.0);
      float sketch =
        // Outlines
        smoothstep(0.4, 0.6, mix(smoothstep(1, 0, pow(smoothstep(0, 1, acc), 0.15)), 1, cdf))
        // Weak, dithered fill
        * mix(mix(0.9, 1, dither(sqrt(l), gl_FragCoord.xy)), 1, cdf)
        // Paper texture
        #ifdef SKETCH_PAPER_TEXTURE
          * (0.9 + 0.1 * smoothstep(-2.5, 0.5, flownoise(vec3(texCoord * 30 * 2, 3)) + flownoise(vec3(texCoord * 80 * 2, 3)) * 0.5 + flownoise(vec3(texCoord * 240 * 2, 3)) * 0.5))
        #endif

        #ifdef SKETCH_GRID_DOTS
          * (smoothstep(0, 2, length(mod(gl_FragCoord.xy, 32) - 16)) * 0.5 + 0.5)
        #elif defined(SKETCH_GRID_LINES)
          * (smoothstep(0, 1, min(abs(mod(gl_FragCoord.x, 32) - 16), abs(mod(gl_FragCoord.y, 32) - 16))) * 0.2 + 0.8)
        #endif
      ;

      // Stains
      vec3 stained = mix(SKETCH_INK_COLOR, SKETCH_PAPER_COLOR, sketch);
      #ifdef SKETCH_STAINS
        float noise = 1.5 * (flownoise(vec3(texCoord * 2.5, 24)) * 0.5 + flownoise(vec3(texCoord * 10, 24)) * 0.25 + flownoise(vec3(texCoord * 20, 24)) * 0.1);
        noise = smoothstep(0.3, 0.32, noise) + smoothstep(0.8, 0.32, noise);
        stained = mix(stained, stained * stained, noise);
      #endif

      fragColor = vec4(stained, color.a);
    #endif
  #endif
}
