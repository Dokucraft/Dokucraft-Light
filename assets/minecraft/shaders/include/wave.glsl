
#moj_import <../config.txt>

#ifndef PI
  #define PI 3.141592653589793
#endif

#ifdef ENABLE_LANTERN_SWING
  const float PHI = 1.61803398875;
  const float SWING_AMOUNT = 0.1 * LANTERN_SWING_MULTIPLIER;
  const float SWING_SPEED = 1000.0;
  const float EPSILON = 0.001;

  mat3 tbn(vec3 normal, vec3 up) {
    vec3 tangent = normalize(cross(up, normal));
    vec3 bitangent = cross(normal, tangent);
    
    return mat3(tangent, bitangent, normal);
  }
#endif

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

vec2 waveXZ(vec3 pos, float time) {
  vec3 wind = pos + vec3(32 * sin(fract(time * 20) * 2 * PI)) * vec3(1, 0, 1);
  float t = (fract(time * 600) + flownoise(wind * 0.2)) * 2 * PI;
  return vec2(sin(t), cos(t)) * WAVE_MULTIPLIER;
}
