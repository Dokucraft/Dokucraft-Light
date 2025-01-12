#version 330

#moj_import <dokucraft:config.glsl>
#moj_import <dokucraft:flavor.glsl>

in vec4 Position;

uniform mat4 ProjMat;
uniform vec2 InSize;
uniform vec2 OutSize;

uniform sampler2D MainSampler;

out vec2 texCoord;
out vec2 oneTexel;
out vec3 direction;
out float timeOfDay;
out float near;
out float far;
out mat4 projInv;
out vec4 fogColor;
out vec3 skyColor;
out vec3 up;
out vec3 sunDir;
out float moonPhase;
out float weather;

#define FPRECISION 4000000.0
#define PROJNEAR 0.05

vec2 getControl(int index, vec2 screenSize) {
  return vec2(floor(screenSize.x / 2.0) + float(index) * 2.0 + 0.5, 0.5) / screenSize;
}

int intmod(int i, int base) {
  return i - (i / base * base);
}

vec3 encodeInt(int i) {
  int s = int(i < 0) * 128;
  i = abs(i);
  int r = intmod(i, 256);
  i = i / 256;
  int g = intmod(i, 256);
  i = i / 256;
  int b = intmod(i, 128);
  return vec3(float(r) / 255.0, float(g) / 255.0, float(b + s) / 255.0);
}

int decodeInt(vec3 ivec) {
  ivec *= 255.0;
  int s = ivec.b >= 128.0 ? -1 : 1;
  return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}

vec3 encodeFloat(float i) {
  return encodeInt(int(i * FPRECISION));
}

float decodeFloat(vec3 ivec) {
  return decodeInt(ivec) / FPRECISION;
}

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

void main() {
  vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
  gl_Position = vec4(outPos.xy, 0.2, 1.0);

  oneTexel = 1.0 / InSize;

  texCoord = Position.xy / OutSize;

  vec2 start = getControl(0, OutSize);
  vec2 inc = vec2(2.0 / OutSize.x, 0.0);

  mat4 ModelViewMat = mat4(decodeFloat(texture(MainSampler, start + 16.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 17.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 18.0 * inc).xyz), 0.0,
              decodeFloat(texture(MainSampler, start + 19.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 20.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 21.0 * inc).xyz), 0.0,
              decodeFloat(texture(MainSampler, start + 22.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 23.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 24.0 * inc).xyz), 0.0,
              0.0, 0.0, 0.0, 1.0);

  mat4 ProjMat = mat4(tan(decodeFloat(texture(MainSampler, start + 3.0 * inc).xyz)), decodeFloat(texture(MainSampler, start + 6.0 * inc).xyz), 0.0, 0.0,
      decodeFloat(texture(MainSampler, start + 5.0 * inc).xyz), tan(decodeFloat(texture(MainSampler, start + 4.0 * inc).xyz)), decodeFloat(texture(MainSampler, start + 7.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 8.0 * inc).xyz),
      decodeFloat(texture(MainSampler, start + 9.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 10.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 11.0 * inc).xyz),  decodeFloat(texture(MainSampler, start + 12.0 * inc).xyz),
      decodeFloat(texture(MainSampler, start + 13.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 14.0 * inc).xyz), decodeFloat(texture(MainSampler, start + 15.0 * inc).xyz), 0.0);

  sunDir = normalize((inverse(ModelViewMat) * vec4(
    decodeFloat(texture(MainSampler, start).xyz),
    decodeFloat(texture(MainSampler, start + inc).xyz),
    decodeFloat(texture(MainSampler, start + 2.0 * inc).xyz),
    1.0
  )).xyz);

  up = vec3(0, 1, 0);

  fogColor = texture(MainSampler, start + inc * 25);
  #ifdef ENABLE_UNDERWATER_FOG_CORRECTION
    vec3 fcHSV = rgbToHsv(fogColor.rgb);
    float t = clamp(
      smoothstep(0.1, 0, hueDistance(0.667, fcHSV.x)) *
      smoothstep(0.5, 1, fcHSV.y) *
      fcHSV.z,
      0, 1
    );

    fogColor.rgb = mix(fogColor.rgb, fogColor.rgb * underwaterFogTransform, t) * mix(1, 0.75, pow(fogColor.a, 5) * t);
  #endif

  skyColor = texture(MainSampler, start + inc * 27).rgb;
  timeOfDay = dot(sunDir, vec3(0, 1, 0));

  near = PROJNEAR;
  far = ProjMat[3][2] * near / (ProjMat[3][2] + 2.0 * near);
  float fov = atan(1 / ProjMat[1][1]);

  projInv = inverse(ProjMat * ModelViewMat);

  vec2 squareUV = (texCoord - 0.5) / (OutSize.yy / OutSize.xy);

  direction = (projInv * vec4(outPos.xy * (far - near), far + near, far - near)).xyz;

  vec4 idx26 = texture(MainSampler, start + 26.0 * inc);
  moonPhase = idx26.x;
  weather = idx26.y;
}
