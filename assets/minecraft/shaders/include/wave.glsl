
#moj_import <minecraft:flownoise.glsl>
#moj_import <dokucraft:config.glsl>

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

vec2 waveXZ(vec3 pos, float time) {
  vec3 wind = pos + vec3(32 * sin(fract(time * 20) * 2 * PI)) * vec3(1, 0, 1);
  float t = (fract(time * 600) + flownoise(wind * 0.2)) * 2 * PI;
  return vec2(sin(t), cos(t)) * WAVE_MULTIPLIER;
}
