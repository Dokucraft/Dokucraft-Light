
#moj_import <../config.txt>

const float PHI = 1.61803398875;
const float SWAYING_AMOUNT = 0.1 * LANTERN_SWAY_MULTIPLIER;
const float SWAYING_SPEED = 1000.0;
const float EPSILON = 0.001;

float rsin(float v) {
  return (sin(v) + sin(2 * v) + sin(3 * v) + 2 * sin(3 * v - 3) - 0.15) / 2.22 * sin(v / 2.71) * WAVE_MULTIPLIER;
}

float rcos(float v) {
  return (cos(v) + cos(2 * v) + cos(3 * v) + 2 * cos(3 * v - 3) + 0.2) / 1.91 * cos(v / 2.71) * WAVE_MULTIPLIER;
}

mat3 tbn(vec3 normal, vec3 up) {
  vec3 tangent = normalize(cross(up, normal));
  vec3 bitangent = cross(normal, tangent);
  
  return mat3(tangent, bitangent, normal);
}
