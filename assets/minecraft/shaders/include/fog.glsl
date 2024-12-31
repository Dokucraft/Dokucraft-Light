#version 330

#moj_import <dokucraft:config.glsl>
#moj_import <dokucraft:flavor.glsl>

#ifdef ENABLE_UNDERWATER_FOG_CORRECTION
  const mat3 underwaterFogTransform = mat3(
    UNDERWATER_FOG_RED,
    UNDERWATER_FOG_GREEN,
    UNDERWATER_FOG_BLUE
  );

  vec3 rgbToHsv(vec3 rgb) {
    float minVal = min(min(rgb.r, rgb.g), rgb.b);
    float maxVal = max(max(rgb.r, rgb.g), rgb.b);
    float delta = maxVal - minVal;
    float h = 0.0;
    float s = (maxVal > 0.0) ? delta / maxVal : 0.0;
    if (delta > 0.0) {
      if (maxVal == rgb.r) {
        h = (rgb.g - rgb.b) / delta;
      } else if (maxVal == rgb.g) {
        h = 2.0 + (rgb.b - rgb.r) / delta;
      } else {
        h = 4.0 + (rgb.r - rgb.g) / delta;
      }
      h = mod(h / 6.0, 1.0);
    }
    return vec3(h, s, maxVal);
  }

  float hueDistance(float hue1, float hue2) {
    hue1 = mod(hue1, 1.0);
    hue2 = mod(hue2, 1.0);
    float delta = abs(hue1 - hue2);
    return min(delta, 1.0 - delta);
  }
#endif

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
  if (vertexDistance <= fogStart) {
    return inColor;
  }

  float fogValue = (vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0) * fogColor.a;

  #ifdef ENABLE_UNDERWATER_FOG_CORRECTION
    vec3 fcHSV = rgbToHsv(fogColor.rgb);
    float t = clamp(
      smoothstep(0.1, 0, hueDistance(0.667, fcHSV.x)) *
      smoothstep(0.5, 1, fcHSV.y) *
      fcHSV.z,
      0, 1
    );

    return vec4(mix(
      inColor.rgb,
      mix(fogColor.rgb, fogColor.rgb * underwaterFogTransform, t) * mix(1, 0.75, pow(fogValue, 5) * t),
      fogValue
    ), inColor.a);
  #else
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue), inColor.a);
  #endif
}

float linear_fog_fade(float vertexDistance, float fogStart, float fogEnd) {
  if (vertexDistance <= fogStart) {
    return 1.0;
  } else if (vertexDistance >= fogEnd) {
    return 0.0;
  }

  return smoothstep(fogEnd, fogStart, vertexDistance);
}

float fog_distance(vec3 pos, int shape) {
  if (shape == 0) {
    return length(pos);
  } else {
    float distXZ = length(pos.xz);
    float distY = abs(pos.y);
    return max(distXZ, distY);
  }
}
