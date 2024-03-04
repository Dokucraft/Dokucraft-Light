#version 150

//=====================================================================================================================

/*
  Controls the type of effect to apply to the menu background.
  0: No effect. The blur will still be applied, that can be changed in post/blur.json
  1: Darken and desaturate.
  2: Sketch filter. The blur radius in post/blur.json should be set to 3 for this effect, and the accessibility
  setting should be disabled in program/blur.fsh.
*/
#define MENU_BACKGROUND 1


// Extra options for menu background effect 1
#define SATURATION 0.5
#define BRIGHTNESS 0.8


// Extra options for menu background effect 2

// The color used as a base for the sketch effect. The stains will affect how this looks, so it might be a good idea to
// disable the stains if you edit this color
#define SKETCH_PAPER_COLOR vec3(0.909, 0.878, 0.819)

// The color used for all shading in the sketch effect, including the outlines, the fill, and the paper texture
#define SKETCH_INK_COLOR vec3(0.231, 0.145, 0)

// Remove or comment out this line to disable the paper texture effect
#define SKETCH_PAPER_TEXTURE

// Remove or comment out this line to disable the stains
#define SKETCH_STAINS

// Uncomment this line to enable a grid of dots
// #define SKETCH_GRID_DOTS

// Uncomment this line to enable a grid of lines
// #define SKETCH_GRID_LINES

//=====================================================================================================================

uniform sampler2D DiffuseSampler;

in vec2 texCoord;
in vec2 oneTexel;

uniform vec2 InSize;

out vec4 fragColor;

#if MENU_BACKGROUND >= 1
  // https://alienryderflex.com/hsp.html
  float perceivedBrightness(vec3 color) {
    vec3 c = color * color * vec3(0.299, 0.587, 0.114);
    return c.r + c.g + c.b;
  }
#endif

#if MENU_BACKGROUND == 2
  const int thresholds[8] = int[8](0, 4, 2, 6, 1, 5, 3, 7);

  float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
  }

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

  vec2 gradient(vec2 intPos, float t) {
    float rand = fract(sin(dot(intPos, vec2(12.9898, 78.233))) * 43758.5453);
    float angle = 6.283185 * rand + 4.0 * t * rand;
    return vec2(cos(angle), sin(angle));
  }

  float flownoise(vec3 p) {
    vec2 i = floor(p.xy);
    vec2 f = p.xy - i;
    vec2 blend = f * f * (3.0 - 2.0 * f);
    float noiseVal = 
      mix(
        mix(
          dot(gradient(i + vec2(0, 0), p.z), f - vec2(0, 0)),
          dot(gradient(i + vec2(1, 0), p.z), f - vec2(1, 0)),
          blend.x),
        mix(
          dot(gradient(i + vec2(0, 1), p.z), f - vec2(0, 1)),
          dot(gradient(i + vec2(1, 1), p.z), f - vec2(1, 1)),
          blend.x),
      blend.y
    );
    return noiseVal / 0.7;
  }

  float colorDifference(vec3 c1, vec3 c2) {
    vec3 delta = c1 - c2;
    return sqrt(dot(delta * vec3(0.299, 0.587, 0.114), delta));
  }
#endif

void main() {
  vec4 color = texture(DiffuseSampler, texCoord);

  #if MENU_BACKGROUND == 0
    fragColor = color;

  #else
    float l = perceivedBrightness(color.rgb);
    #if MENU_BACKGROUND == 1
      fragColor = vec4(mix(vec3(l), color.rgb, SATURATION) * BRIGHTNESS, color.a);

    #elif MENU_BACKGROUND == 2
      // Sketch filter
      vec2 px = vec2(1) / InSize;
      vec4 c1 = texture(DiffuseSampler, texCoord + vec2(px.x, 0));
      vec4 c2 = texture(DiffuseSampler, texCoord + vec2(0, px.y));
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
