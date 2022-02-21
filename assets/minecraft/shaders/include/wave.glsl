
const float WAVE_MULTIPLIER = 1.0;

float rsin(float v) {
  return (sin(v) + sin(2 * v) + sin(3 * v) + 2 * sin(3 * v - 3) - 0.15) / 2.22 * sin(v / 2.71) * WAVE_MULTIPLIER;
}

float rcos(float v) {
  return (cos(v) + cos(2 * v) + cos(3 * v) + 2 * cos(3 * v - 3) + 0.2) / 1.91 * cos(v / 2.71) * WAVE_MULTIPLIER;
}
