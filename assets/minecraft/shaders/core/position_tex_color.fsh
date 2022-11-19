#version 150

#moj_import <utils.glsl>
#moj_import <../config.txt>
#moj_import <../flavor.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

#if CUSTOM_END_SKY >= 1
  uniform float GameTime;
#endif

in vec2 texCoord0;
in vec4 vertexColor;
in vec4 Pos;
in float isNeg;
in vec2 ScrSize;

#if CUSTOM_END_SKY >= 1
  in vec3 direction;
#endif

out vec4 fragColor;

//Mini-config for background transitions part
#define CHANGE_SPEED 3 //Panoramas changing speed of background transitions; Decimal.
#define TIMES 2        //Amount of full cycles on one turnover; Integer.

#if CUSTOM_END_SKY >= 1
  #define M_PI 3.141592653589793

  mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
  }

  vec3 rotate(vec3 v, vec3 axis, float angle) {
    mat4 m = rotationMatrix(axis, angle);
    return (m * vec4(v, 1.0)).xyz;
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
    return noiseVal / 0.6;
  }

  float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
  }

  float star(vec2 uv, float maxVal, float crossIntensity, float distScale, float starScale) {
    float d = length(uv * starScale);
    return min((0.1 / d + max(0.0, 1.0 - abs(uv.x * uv.y * 600))*8 * crossIntensity) * smoothstep(1, 0.1, d * distScale), maxVal);
  }

  vec3 starfield(vec3 direction, int scsqrt, float bandPow, float maskOpacity, float maskOffset, float crossIntensity, float distScale, float twinkle, float time, vec3 baseColor, vec3 colorVar) {
    vec3 dir = direction / length(direction.xz);
    vec2 uv = vec2(atan(dir.z, dir.x), dir.y) / M_PI * scsqrt;
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    int scsqrt2 = scsqrt * 2;
    vec3 col = vec3(0);
    for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
      vec2 o = vec2(x, y);
      float n = hash21(mod(id + o, scsqrt2));
      float size = fract(n * 745.32);
      vec3 color = (sin(vec3(0.2, 0.3, 0.9) * fract(n * 2345.7) * 109.2) * 0.5 + 0.5) * colorVar + baseColor;
      col += vec3(star(gv - o - vec2(n, fract(n * 34.2)) + 0.5, 15, crossIntensity, distScale, 1 + (sin(time + n * 23.2)) * 0.5 * twinkle)) * size * color;
    }
    return col / 9 * pow(1.0 - abs(direction.y), bandPow) * (1 - maskOpacity * smoothstep(-0.25, 0.5, vec3(flownoise(normalize(direction + maskOffset) * 2))));
  }
#endif

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
int hash(int x) {
  x += ( x << 10 );
  x ^= ( x >>  6 );
  x += ( x <<  3 );
  x ^= ( x >> 11 );
  x += ( x << 15 );
  return x;
}

int noise(ivec2 v, int seed) {
  return hash(v.x ^ hash(v.y + seed) ^ seed);
}

void main() {
  vec4 color = texture(Sampler0, texCoord0) * vertexColor;
  vec2 texSize = textureSize(Sampler0, 0);
  if (Pos.y != -1999) {
    if (texSize.x != texSize.y) {
      #moj_import <background-transitions.glsl>
    }
  } else {
    #moj_import <menus-enchanted.glsl>
  }

  if (color.a < 0.1) {
    discard;
  }

  #if CUSTOM_END_SKY == 1 // Otherworldy Rift End sky
    if (floor(vertexColor.r * 255 + 0.5) == 40) {
      float gt = GameTime * 80;
      vec3 nd = normalize(direction);

      #ifdef ENABLE_END_SKY_PIXELIZATION
        nd /= max(abs(nd.x), max(abs(nd.y), abs(nd.z)));
        nd = normalize((floor(nd * END_SKY_PIXELIZATION_RESOLUTION + 0.5) + 0.5) / END_SKY_PIXELIZATION_RESOLUTION);
      #endif

      float f = smoothstep(0.1, 0.85, dot(vec3(0,1,0), nd) * ((flownoise(nd * 2 + 11 + gt) + flownoise(nd * 6 + 11 - gt) * 0.5 + flownoise(nd * 12 + 11 + vec3(0, gt, 0)) * 0.25) / 3.5 + 0.5));
      float riftMask = smoothstep(0.7, 0.6, f * 2);
      vec3 riftND = rotate(rotate(nd, vec3(1, 0, 0), gt / 5), vec3(0, 0, 1), M_PI / 2);

      #ifdef ENABLE_END_SKY_RIFT_GLOW
        float riftGlow = riftMask * f * 2;
      #endif

      fragColor = vec4(

        #ifdef ENABLE_END_SKY_RIFT_GLOW
          END_SKY_RIFT_COLOR * (riftGlow + pow(riftGlow + 0.2, 16) * ((vec3(1.0) - END_SKY_RIFT_COLOR) * 66.66667 + vec3(20.0)))
        #else
          vec3(0)
        #endif

        #ifdef ENABLE_END_SKY_STARS_OUTSIDE_RIFT
          + ( // Outside of rift
              starfield(rotate(nd, vec3(1, 0, 0), 2.4), 48, 1, 1, 25, 0, 1, 0, 0, END_SKY_STARS_OUTSIDE_BASE_COLOR, END_SKY_STARS_OUTSIDE_COLOR_VARIANCE)
            + starfield(rotate(nd, vec3(1, 0, 0), 2.4 + M_PI / 2), 32, 1, 1, 12, 0, 1, 0, 0, END_SKY_STARS_OUTSIDE_BASE_COLOR, END_SKY_STARS_OUTSIDE_COLOR_VARIANCE)
            + END_SKY_NEBULAE_OUTSIDE_COLOR * smoothstep(0.1, 1.1, flownoise(nd * 2 + 14) * 0.5 + 0.5) * 0.1
          ) * riftMask
        #endif

        #ifdef ENABLE_END_SKY_STARS_INSIDE_RIFT
          + ( // Inside rift
              starfield(riftND, 130, 1, 1, 25, 0, 1, 0, 0, END_SKY_STARS_INSIDE_BASE_COLOR, END_SKY_STARS_INSIDE_COLOR_VARIANCE)
            + starfield(riftND, 32, 1, 1, 25, 1, 3, 1, gt * 60, END_SKY_STARS_INSIDE_BASE_COLOR, END_SKY_STARS_INSIDE_COLOR_VARIANCE)
            + END_SKY_NEBULAE_INSIDE_COLOR * smoothstep(0.2, 1, flownoise(riftND * 2 + 63) * 0.5 + 0.5) * 0.4
          ) * (1 - riftMask)
        #endif

      , 1);
    } else {
      fragColor = color * ColorModulator;
    }
  #elif CUSTOM_END_SKY == 2 // Cloudy End sky
    if (floor(vertexColor.r * 255 + 0.5) == 40) {
      float gt = GameTime * 64;
      vec3 nd = normalize(direction);

      #ifdef ENABLE_END_SKY_PIXELIZATION
        nd /= max(abs(nd.x), max(abs(nd.y), abs(nd.z)));
        nd = normalize((floor(nd * END_SKY_PIXELIZATION_RESOLUTION + 0.5) + 0.5) / END_SKY_PIXELIZATION_RESOLUTION);
      #endif

      float starMask = smoothstep(-0.2, 0.3, smoothstep(0, 1, abs(dot(vec3(0,1,0), nd))) * (0.5 + (flownoise(nd * 2 + 11 + gt) + flownoise(nd * 6 + 11 - gt * 1.25) * 0.5 + flownoise(nd * 12 + 11 + vec3(0, gt * 1.5, 0)) * 0.25 + flownoise(nd * 24 + 11 - vec3(0, gt * 2, 0)) * 0.125) / 3.5));

      fragColor = vec4(

        smoothstep(-1, -0.5, dot(vec3(0,1,0), nd)) * END_SKY_2_BASE_COLOR + mix(

          // Strong clouds
          mix(END_SKY_2_STRONG_CLOUDS_PRIMARY_COLOR, mix(END_SKY_2_STRONG_CLOUDS_COLOR_1, END_SKY_2_STRONG_CLOUDS_COLOR_2, smoothstep(-0.5, 0.5, flownoise(nd))), smoothstep(0.3, 1.0, starMask)),

          // Stars
            starfield(rotate(nd, vec3(1, 0, 0), 2.4), 48, 1, 1, 25, 0, 1, 0, 0, END_SKY_2_STARS_BASE_COLOR, END_SKY_2_STARS_COLOR_VARIANCE)
          + starfield(rotate(nd, vec3(1, 0, 0), 2.4 + M_PI / 2), 32, 1, 1, 12, 0, 1, 0, 0, END_SKY_2_STARS_BASE_COLOR, END_SKY_2_STARS_COLOR_VARIANCE)

          // Weak clouds
          + END_SKY_2_WEAK_CLOUDS_COLOR * smoothstep(0.1, 1.1, flownoise(nd * 2 + 14) * 0.5 + 0.5) * 0.2

        , starMask)
      , 1);
    } else {
      fragColor = color * ColorModulator;
    }
  #else
    fragColor = color * ColorModulator;
  #endif
}
