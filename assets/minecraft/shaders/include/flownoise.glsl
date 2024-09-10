#moj_import <minecraft:hash12.glsl>

vec2 flownoise_gradient(vec2 intPos, float t) {
  float rand = hash12(intPos);
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
        dot(flownoise_gradient(i + vec2(0, 0), p.z), f - vec2(0, 0)),
        dot(flownoise_gradient(i + vec2(1, 0), p.z), f - vec2(1, 0)),
        blend.x),
      mix(
        dot(flownoise_gradient(i + vec2(0, 1), p.z), f - vec2(0, 1)),
        dot(flownoise_gradient(i + vec2(1, 1), p.z), f - vec2(1, 1)),
        blend.x),
    blend.y
  );
  return noiseVal / 0.7;
}

float flownoise_tile(vec3 p, vec2 o, vec2 ts) {
  vec2 t = mod(p.xy, ts) / ts;
  vec3 o3 = vec3(o, 0);
  return mix(
    mix(
      flownoise(o3 + p),
      flownoise(o3 + p - vec3(ts.x, 0, 0)),
      t.x
    ),
    mix(
      flownoise(o3 + p - vec3(0, ts.y, 0)),
      flownoise(o3 + p - vec3(ts, 0)),
      t.x
    ),
    t.y
  );
}
