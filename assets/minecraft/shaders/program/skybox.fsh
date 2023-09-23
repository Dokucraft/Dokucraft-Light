#version 150


/* ------------------------------- Settings -------------------------------- */

// Controls how the atmosphere is rendered.
// 0: Uses a mostly static skybox during the day that may include things like clouds, depending on the texture used.
// 1: The clouds use a texture for their shapes and will be dynamically lit by the sun and moon. The color of the sky is based on a separate texture.
#define ATMOSPHERE 0

// Controls what night sky to render.
// 0: Use a skybox texture.
// 1: Generate a night sky procedurally without any textures.
// 2: Same as 1, but with slightly less color.
#define NIGHT_SKY 0

// Uncomment this line to enable a light layer of fog that is dynamically lit by the moon at night.
// #define ENABLE_NIGHT_FOG

// Remove this line to disable the north star
// No noticeable impact on performance
// Requires NIGHT_SKY being set to 1 or 2
#define ENABLE_NORTH_STAR

// Uncomment this line to enable auroras at night
// Major impact on performance on most graphics cards
// #define ENABLE_AURORAS

// Controls the colors of the auroras
// Requires ENABLE_AURORAS
#define AURORA_COLOR vec3(0.465, 2, 0.833)

// Remove the two slashes at the start of this line to draw a sun as a part of the sky.
// To disable the regular sun, make sure to enable the same setting in confix.txt.
// This does not currently use a texture. The shape of the sun is calculated based on the time of day.
// #define ENABLE_POST_SUN

// Controls the speed of the sun's animation.
// Requires ENABLE_POST_SUN
#define SUN_ANIM_SPEED 0.5

// Remove the two slashes at the start of this line to draw a moon as a part of the sky.
// This requires MoonSampler to be set up properly in program/skybox.json and in post/transparency.json
// For moon phases to work properly and to hide the regular moon, enable ENABLE_POST_MOON_PHASES in config.txt
// #define ENABLE_POST_MOON

// Use this to change the size of the moon.
// Requires ENABLE_POST_MOON
#define MOON_SCALE 0.3

/* ------------------------------------------------------------------------- */


uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform sampler2D SkyBoxNightSampler;
uniform vec2 OutSize;

#if ATMOSPHERE == 0
  uniform sampler2D SkyBoxDaySampler;
#elif ATMOSPHERE == 1
  uniform sampler2D CloudsSampler;
  uniform sampler2D SkyColorSampler;
#endif

#ifdef ENABLE_POST_MOON
  uniform sampler2D MoonSampler;
#endif

in vec2 texCoord;
in vec2 oneTexel;
in vec3 direction;
in float timeOfDay; // 1 - Noon, -1 - Midnight
in float near;
in float far;
in mat4 projInv;
in vec4 fogColor;
in vec3 up;
in vec3 sunDir;

/* Moon phases:
    0.0:  Full Moon
    0.25: Third Quarter
    0.5:  New Moon
    0.75: First Quarter
  There are 8 of them, and it wraps around at 1.0 so that 1.0 turns into 0.0
*/
in float moonPhase;

/* Weather:
  0.0: Clear
  1.0: Raining
*/
in float weather;

out vec4 fragColor;

const float FUDGE = 0.01;



/* --------------------------- Color Blend Mode ---------------------------- */
/*
** Copyright (c) 2012, Romain Dura romain@shazbits.com
** 
** Permission to use, copy, modify, and/or distribute this software for any 
** purpose with or without fee is hereby granted, provided that the above 
** copyright notice and this permission notice appear in all copies.
** 
** THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
** WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
** MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
** SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES 
** WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN 
** ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR 
** IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

vec3 RGBToHSL(vec3 color) {
  vec3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)

  float fmin = min(min(color.r, color.g), color.b); //Min. value of RGB
  float fmax = max(max(color.r, color.g), color.b); //Max. value of RGB
  float delta = fmax - fmin; //Delta RGB value

  hsl.z = (fmax + fmin) / 2.0; // Luminance

  if (delta == 0.0) { // This is a gray, no chroma...
    hsl.x = 0.0; // Hue
    hsl.y = 0.0; // Saturation

  } else { //Chromatic data...
    if (hsl.z < 0.5)
      hsl.y = delta / (fmax + fmin); // Saturation
    else
      hsl.y = delta / (2.0 - fmax - fmin); // Saturation
    
    float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
    float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
    float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

    if (color.r == fmax)
      hsl.x = deltaB - deltaG; // Hue
    else if (color.g == fmax)
      hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
    else if (color.b == fmax)
      hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

    if (hsl.x < 0.0)
      hsl.x += 1.0; // Hue
    else if (hsl.x > 1.0)
      hsl.x -= 1.0; // Hue
  }

  return hsl;
}

float HueToRGB(float f1, float f2, float hue) {
  if (hue < 0.0)
    hue += 1.0;
  else if (hue > 1.0)
    hue -= 1.0;
  float res;
  if ((6.0 * hue) < 1.0)
    res = f1 + (f2 - f1) * 6.0 * hue;
  else if ((2.0 * hue) < 1.0)
    res = f2;
  else if ((3.0 * hue) < 2.0)
    res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
  else
    res = f1;
  return res;
}

vec3 HSLToRGB(vec3 hsl) {
  vec3 rgb;
  
  if (hsl.y == 0.0) {
    rgb = vec3(hsl.z); // Luminance
  } else {
    float f2;

    if (hsl.z < 0.5)
      f2 = hsl.z * (1.0 + hsl.y);
    else
      f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);

    float f1 = 2.0 * hsl.z - f2;

    rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
    rgb.g = HueToRGB(f1, f2, hsl.x);
    rgb.b = HueToRGB(f1, f2, hsl.x - (1.0/3.0));
  }

  return rgb;
}

vec3 BlendColor(vec3 base, vec3 blend) {
  vec3 blendHSL = RGBToHSL(blend);
  return HSLToRGB(vec3(blendHSL.r, blendHSL.g, RGBToHSL(base).b));
}

/* ------------------------------------------------------------------------- */

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

float hash21(vec2 p) {
  vec3 p3  = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
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

#if NIGHT_SKY >= 1

  float star(vec2 uv, float maxVal) {
    float d = length(uv);
    return min((0.1 / d /* + max(0.0, 1.0 - abs(uv.x * uv.y * 5000))*2 */) * smoothstep(1, 0.1, d), maxVal);
  }

  vec3 starfield(vec3 direction, int scsqrt, float bandPow, float maskOpacity, float maskOffset) {
    float l = length(direction.xz);
    vec3 dir = direction / l;
    vec2 uv = vec2(atan(dir.z, dir.x), dir.y) / M_PI * scsqrt;
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    int scsqrt2 = scsqrt * 2;
    vec3 col = vec3(0);
    for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
      vec2 o = vec2(x, y);
      float n = hash21(mod(id + o, scsqrt2));
      float size = fract(n * 745.32);
      vec3 color = sin(vec3(0.2, 0.3, 0.9) * fract(n * 2345.7) * 109.2) * 0.5 + 0.5;
      color = color * vec3(0.4, 0.2, 0.1) + vec3(0.4, 0.6, 0.9);
      col += vec3(star(gv - o - vec2(n, fract(n * 34.2)) + 0.5, 15)) * size * color;
    }
    return col / 9 * pow(1.0 - abs(direction.y), bandPow) * (1 - maskOpacity * smoothstep(-0.25, 0.5, vec3(flownoise(normalize(direction + maskOffset) * 2))));
  }
#endif

/* ------------------------------ Auroras ---------------------------------- */
// Auroras by nimitz 2017 (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Modified to get the time from the sun direction, remove the unnecessary
// ray origin vector, and to return a vec3 instead of vec4.

#ifdef ENABLE_AURORAS
  mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}
  mat2 m2 = mat2(0.95534, 0.29552, -0.29552, 0.95534);
  float tri(in float x){return clamp(abs(fract(x)-.5),0.01,0.49);}
  vec2 tri2(in vec2 p){return vec2(tri(p.x)+tri(p.y),tri(p.y+tri(p.x)));}

  float triNoise2d(in vec2 p, float spd, float time) {
    float z=1.8;
    float z2=2.5;
    float rz = 0.0;
    p *= mm2(p.x*0.06);
    vec2 bp = p;
    for (float i = 0.0; i < 5.0; i++) {
      vec2 dg = tri2(bp*1.85)*.75;
      dg *= mm2(time*spd);
      p -= dg/z2;
      bp *= 1.3;
      z2 *= .45;
      z *= .42;
      p *= 1.21 + (rz-1.0)*.02;
      rz += tri(p.x+tri(p.y))*z;
      p*= -m2;
    }
    return clamp(1./pow(rz*29., 1.3),0.,.55);
  }

  #define INV_AURORA_COLOR vec3(1) / AURORA_COLOR
  vec3 aurora(vec3 direction, float time) {
    vec3 col = vec3(0);
    vec3 avgCol = vec3(0);

    for (float i = 0.0; i < 50.0; i++) {
      float of = 0.006*hash21(gl_FragCoord.xy)*smoothstep(0.,15., i);
      float pt = (.8+pow(i,1.4)*.002)/(direction.y*2.+0.4) - of;
      vec3 bpos = pt*direction;
      avgCol = mix(avgCol, (sin(1.-INV_AURORA_COLOR+i*0.043)*0.5+0.5)*triNoise2d(bpos.zx, 0.06, time), 0.5);
      col += avgCol*exp2(-i*0.065 - 2.5)*smoothstep(0.,5., i);
    }

    col *= clamp(direction.y*15.+.4,0.,1.);
    return max(vec3(0), col*1.8);
  }
#endif

/* ------------------------------------------------------------------------- */


float linearizeDepth(float depth) {
  return (2.0 * near * far) / (far + near - depth * (far - near));    
}

vec3 sampleSkybox(sampler2D skyboxSampler, vec3 direction) {
  float l = max(max(abs(direction.x), abs(direction.y)), abs(direction.z));
  vec3 dir = direction / l;
  vec3 absDir = abs(dir);

  vec2 skyboxUV;
  if (absDir.x >= absDir.y && absDir.x > absDir.z) {
    if (dir.x > 0) {
      skyboxUV = vec2(0, 0.5) + (dir.zy * vec2(1, -1) + 1) / 2 / vec2(3, 2);
    } else {
      skyboxUV = vec2(2.0 / 3, 0.5) + (-dir.zy + 1) / 2 / vec2(3, 2);
    }
  } else if (absDir.y >= absDir.z) {
    if (dir.y > 0) {
      skyboxUV = vec2(1.0 / 3, 0) + (dir.xz * vec2(-1, 1) + 1) / 2 / vec2(3, 2);
    } else {
      skyboxUV = vec2(0, 0) + (-dir.xz + 1) / 2 / vec2(3, 2);
    }
  } else {
    if (dir.z > 0) {
      skyboxUV = vec2(1.0 / 3, 0.5) + (-dir.xy + 1) / 2 / vec2(3, 2);
    } else {
      skyboxUV = vec2(2.0 / 3, 0) + (dir.xy * vec2(1, -1) + 1) / 2 / vec2(3, 2);
    }
  }
  return texture(skyboxSampler, skyboxUV).rgb;
}

#ifdef ENABLE_POST_MOON
  vec2 getMoonUV(vec3 direction) {
    float l = max(max(abs(direction.x), abs(direction.y)), abs(direction.z));
    vec3 dir = direction / l;

    vec2 moonUV;
    if (dir.x > 0) {
      moonUV = vec2(0);
    } else {
      moonUV = (-dir.zy + 1) / 2;
    }
    return clamp((moonUV - vec2(0.5)) / MOON_SCALE + vec2(0.5), vec2(0), vec2(1));
  }
#endif

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
  if (vertexDistance <= fogStart) {
    return inColor;
  }

  float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;
  return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

float linearstep(float edge0, float edge1, float x) {
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

#if ATMOSPHERE == 1
  vec2 sampleCloudNorm(vec2 uv, vec3 px) {
    float v = texture(CloudsSampler, uv).r;
    float u = texture(CloudsSampler, uv - px.zy).r;
    float d = texture(CloudsSampler, uv + px.zy).r;
    float l = texture(CloudsSampler, uv - px.xz).r;
    float r = texture(CloudsSampler, uv + px.xz).r;
    return vec2(
      sqrt(clamp(v - d, 0, 1)) - sqrt(clamp(v - u, 0, 1)),
      sqrt(clamp(v - l, 0, 1)) - sqrt(clamp(v - r, 0, 1))
    );
  }
#endif

#ifdef ENABLE_POST_SUN
  float rayOpacity(vec2 dir, vec2 ref, float time, float seedA, float seedB) {
    float ca = dot(normalize(dir), ref);
    return clamp((0.48 + 0.16 * sin( ca * seedA + time)) + (0.29 + 0.23 * cos(-ca * seedB + time)), 0.0, 1.0);
  }

  vec4 postSun(vec3 color, vec3 nd, float ddsd, float sunAngle) {
    vec3 wsd = (rotationMatrix(vec3(0, 0, -1), M_PI - atan(sunDir.y, sunDir.x)) * vec4(nd, 1.0)).xyz;
    vec2 sunUV;
    if (wsd.x > 0) {
      sunUV = vec2(0);
    } else {
      sunUV = (-wsd.zy + 1) / 2 - vec2(0.5);
    }

    float raysX = rayOpacity(sunUV, vec2(1, 0), sunAngle * 350 * SUN_ANIM_SPEED, 36.2214, 21.1139);
    float raysY = rayOpacity(sunUV, vec2(0, 1), sunAngle * 350 * SUN_ANIM_SPEED, 26.1953, 34.9584);
    float sa = atan(sunUV.y, sunUV.x);
    vec2 raysMask = abs(sunUV);
    float rays = mix(raysX, raysY, clamp(pow(1 - (raysMask.y - raysMask.x) * 2, 10), 0, 1)) + 0.17 * (
      sin(sa * 7 + sunAngle * 250 * SUN_ANIM_SPEED) +
      sin(sa * 5 - sunAngle * 169 * SUN_ANIM_SPEED) +
      2
    );

    float distSun = dot(wsd, vec3(-1, 0, 0)) * 0.995;
    float sunOpacity = smoothstep(0.995, 0.99999, distSun) + pow(rays, smoothstep(1, 0.97, distSun)) * smoothstep(0.97, 1, distSun) + pow(smoothstep(0.998, 1.0015, ddsd), 2);
    return vec4(mix(vec3(1, 0.1, 0), vec3(2), sunOpacity), sunOpacity * sunOpacity * (1.0 - weather));
  }
#endif

#ifdef ENABLE_NIGHT_FOG
  vec4 nightFog(vec3 nd, vec3 ndr, float m) {
    float distHorizon = 1.0 - abs(dot(nd, vec3(0, 1, 0)));
    float distMoon = max(0, dot(ndr, vec3(-1, 0, 0)));
    return vec4(
      // Base fog
        vec3(0.243, 0.325, 0.392)
      // Moonlit fog
      + mix(vec3(0.156, 0.274, 0.38), vec3(0.737, 0.76, 0.745), distMoon) * distMoon * distMoon * m
      , mix(0.1, 0.9, distHorizon)
    );
  }
#endif

vec3 stormyWeather(vec3 ndr, float sunAngle, float screenNoise) {
  return fogColor.rgb + vec3((
    flownoise(ndr * 3) * 0.5 +
    flownoise((rotate(ndr, vec3(0.5, 0.5, 0), sunAngle * 3) + vec3(0, 0, -timeOfDay * 5)) * 5) * 0.25 +
    flownoise((rotate(ndr, vec3(0.5, 0, 0.5), -sunAngle * 3) + vec3(0, timeOfDay * 5, 0)) * 8) * 0.125 +
    flownoise((rotate(ndr, vec3(0, 0.5, 0.5), sunAngle * 3) + vec3(timeOfDay * 5, 0, 0)) * 12) * 0.0625 +
    screenNoise * 0.0625
    - 0.5
  ) * 0.1);
}

void main() {
  float realDepth = linearizeDepth(texture(DepthSampler, texCoord).r);
  fragColor = texture(DiffuseSampler, texCoord);

  vec3 temp = fragColor.rgb - vec3(0.157, 0.024, 0.024);
  bool isNether = dot(temp, temp) < FUDGE;
  vec3 nd = normalize(direction);

  if (far > 50 && realDepth > far / 2 - 5) {

    vec3 stars = vec3(0);
    vec4 moon = vec4(0);
    vec4 atmosphere = vec4(0);
    vec3 auroras = vec3(0);
    vec4 clouds = vec4(0);
    vec3 cloudsAdditive = vec3(0);

    float dayLight = smoothstep(-0.1, 0.1, timeOfDay);
    float sunAngle = atan(sunDir.y, sunDir.x);
    mat4 timeRotMat = rotationMatrix(vec3(0, 0, 1), sunAngle - M_PI / 6);
    vec3 ndr = (timeRotMat * vec4(nd, 1.0)).xyz;
    float screenNoise = hash21(gl_FragCoord.xy);

    #ifdef ENABLE_POST_MOON
      vec2 moonUV = getMoonUV((rotationMatrix(vec3(0, 0, 1), atan(sunDir.y, sunDir.x)) * vec4(nd, 1.0)).xyz);
      moon = texture(MoonSampler, moonUV);

      // Moon radius in UV space: 0.95 / 2 = 0.475
      vec2 moonNormXY = (moonUV - vec2(0.5)) / 0.475;
      vec3 moonNorm = normalize(vec3(moonNormXY, 1.0 - length(moonNormXY)));
      vec3 fakeSunDir = rotate(vec3(0, 0, 1), vec3(0.5, 0.5, 0), M_PI * 2 * moonPhase);

      // Add shading to the moon based on moon phase
      float fullMoonMod = -0.2 * abs(0.5 - moonPhase);
      moon.rgb *= smoothstep(-0.2 + fullMoonMod, 0.4 + fullMoonMod, dot(moonNorm, fakeSunDir));
    #endif

    if (timeOfDay < 0.1) { // Night time
      #if NIGHT_SKY == 0
        stars = sampleSkybox(SkyBoxNightSampler, (rotationMatrix(vec3(0, 0, 1), atan(sunDir.y, sunDir.x)) * vec4(nd, 1.0)).xyz).rgb;

        #ifdef ENABLE_NIGHT_FOG
        atmosphere = nightFog(nd, ndr,
          #ifdef ENABLE_POST_MOON
            (fakeSunDir.z + 2.0) / 3.0
          #else
            0.8
          #endif
        );
      #endif

      #elif NIGHT_SKY == 1 || NIGHT_SKY == 2
        #ifdef ENABLE_NORTH_STAR
          vec3 nsp = normalize(normalize(vec3(0, 0.57, 1)) - nd);
        #endif

        stars =
          // Galactic disk
            starfield(rotate(ndr, vec3(1, 0, 0), 2.4), 96, 6, 0.75, 25) * 3
          // Nearby stars
          + starfield(rotate(ndr, vec3(0.7, 0.3, -0.6), 1.2), 32, 2, 1, 3)
          + starfield(rotate(ndr, vec3(-0.8, 0.2, -0.5), 0.3), 16, 2, 1, 9)
          + starfield(rotate(ndr, vec3(-0.9, 0.8, 0.4), 2.1), 40, 2, 1, 13) * 1.1
          // Distant stars/galaxies
          + starfield(rotate(ndr, vec3(1), 1.5), 160, 1, 1, 31)
          // Nebulae
          #if NIGHT_SKY == 1
            + vec3(0.2, 0.5, 0.9) * smoothstep(0.2, 1, flownoise(ndr * 2 + 46) * 0.5 + 0.5) * 0.4
            + vec3(0.8, 0.1, 0.9) * smoothstep(0.1, 1.1, flownoise(ndr * 2 + 14) * 0.5 + 0.5) * 0.1
          #elif NIGHT_SKY == 2
            + vec3(0.2, 0.5, 0.9) * smoothstep(0.2, 1, flownoise(ndr * 2 + 46) * 0.5 + 0.5) * 0.08
            + vec3(0.8, 0.1, 0.9) * smoothstep(0.1, 1.1, flownoise(ndr * 2 + 14) * 0.5 + 0.5) * 0.02
          #endif

          #ifdef ENABLE_NORTH_STAR
            + max(vec3(1 - abs(nsp.x * nsp.y * 150000)) * 2, 0) * smoothstep(0.0175, 0.00175, length(nsp.xy)) * vec3(0.5, 0.75, 1)
          #endif
        ;
      #endif

      #ifdef ENABLE_NIGHT_FOG
        atmosphere = nightFog(nd, ndr,
          #ifdef ENABLE_POST_MOON
            (fakeSunDir.z + 2.0) / 3.0
          #else
            0.5
          #endif
        );
      #endif

      #ifdef ENABLE_AURORAS
        auroras = aurora(nd, sunAngle * 1000) * 0.5
          #ifndef ENABLE_POST_MOON
            * smoothstep(-1.025, -0.9, dot(nd, sunDir))
          #endif
        ;
      #endif
    }

    float hm = (1.5 + clamp(dot(nd, vec3(0, -1, 0)) * 2, -1.5, 0.5)) / 2;
    vec3 horizon = vec3(0.728308,0.04059,0.036865);
    float rm = max(0, (1 + dot(nd, normalize(sunDir))) / 2);
    rm *= rm * (max(0.75, 1 - abs(timeOfDay)) - 0.75) * 4;

    #if ATMOSPHERE == 0
      atmosphere = mix(
        atmosphere,
        vec4(
          sampleSkybox(SkyBoxDaySampler, (vec4(direction, 1) * rotationMatrix(vec3(0, 1, 0), 1.3)).xyz),
          dayLight
        ),
        dayLight
      );

      // Rainy weather
      if (weather > 0) {
        atmosphere.rgb = mix(atmosphere.rgb, stormyWeather(ndr, sunAngle, screenNoise), weather);
        atmosphere.a = max(dayLight, weather);
      }

      // Make the sky more red near the sun during sunrise/sunset
      atmosphere.rgb = mix(
        atmosphere.rgb,
        mix(
          BlendColor(atmosphere.rgb, horizon),
          horizon,
          hm
        ) / (1 - pow(smoothstep(-5, 3, dot(nd, sunDir)), 4) * vec3(1, 0.48, 0.24)),
        rm
      );

      #ifdef ENABLE_POST_SUN
        vec4 sun = postSun(atmosphere.rgb, nd, dot(nd, sunDir), sunAngle);
        atmosphere.rgb = mix(atmosphere.rgb, sun.rgb, sun.a);
      #endif

    #elif ATMOSPHERE == 1
      float ddsd = dot(nd, sunDir);
      float skyTopMask = smoothstep(1.0, 0.8, nd.y);
      vec2 cloudsUV = vec2(atan(nd.z, nd.x) / (M_PI * 2), abs((nd.y - 1.35) / 1.6));
      float texValue = texture(CloudsSampler, cloudsUV).r;
      vec3 pxSize = vec3(vec2(1.0) / textureSize(CloudsSampler, 0), 0);
      vec3 cloudNorm = vec3(vec2(
        sampleCloudNorm(cloudsUV + vec2(-1, -1) * pxSize.xy, pxSize) * 0.0625 +
        sampleCloudNorm(cloudsUV + vec2(-1,  0) * pxSize.xy, pxSize) * 0.125 +
        sampleCloudNorm(cloudsUV + vec2(-1,  1) * pxSize.xy, pxSize) * 0.0625 +
        sampleCloudNorm(cloudsUV + vec2( 0, -1) * pxSize.xy, pxSize) * 0.125 +
        sampleCloudNorm(cloudsUV,                            pxSize) * 0.25 +
        sampleCloudNorm(cloudsUV + vec2( 0,  1) * pxSize.xy, pxSize) * 0.125 +
        sampleCloudNorm(cloudsUV + vec2( 1, -1) * pxSize.xy, pxSize) * 0.0625 +
        sampleCloudNorm(cloudsUV + vec2( 1,  0) * pxSize.xy, pxSize) * 0.125 +
        sampleCloudNorm(cloudsUV + vec2( 1,  1) * pxSize.xy, pxSize) * 0.0625
      ), 0);
      cloudNorm.z = sqrt(1.0 - dot(cloudNorm.xy, cloudNorm.xy));
      vec3 dirR = normalize(cross(nd, vec3(0, 1, 0)));
      vec3 dirD = normalize(cross(nd, dirR));
      cloudNorm = normalize(mat3(dirD, -dirR, -nd) * cloudNorm);

      // Adding a tiny bit of noise here lessens the color banding in the gradient
      float fAtmos = nd.y + screenNoise * 0.02;
      atmosphere = mix(atmosphere, vec4(mix(
        mix(
          texelFetch(SkyColorSampler, ivec2(0, 2), 0).rgb,
          texelFetch(SkyColorSampler, ivec2(0, 1), 0).rgb,
          linearstep(0, 0.5, fAtmos)
        ),
        texelFetch(SkyColorSampler, ivec2(0, 0), 0).rgb,
        linearstep(0.5, 1, fAtmos)
        ), max(weather, dayLight)
      ), max(weather, dayLight));

      // Rainy weather
      if (weather > 0) {
        atmosphere.rgb = mix(atmosphere.rgb, stormyWeather(ndr, sunAngle, screenNoise), weather);
      }

      // Make the sky more red near the sun during sunrise/sunset
      atmosphere.rgb = mix(
        atmosphere.rgb,
        mix(
          BlendColor(atmosphere.rgb, horizon),
          horizon,
          hm
        ) / (1 - pow(smoothstep(-5, 3, dot(nd, sunDir)), 4) * vec3(1, 0.48, 0.24)),
        rm
      );

      #ifdef ENABLE_POST_SUN
        vec4 sun = postSun(atmosphere.rgb, nd, ddsd, sunAngle);
        atmosphere.rgb = mix(atmosphere.rgb, sun.rgb, sun.a);
      #endif

      float cndsd = dot(cloudNorm, sunDir);

      vec3 dayCloudsColor = mix(
        texelFetch(SkyColorSampler, ivec2(1, 0), 0).rgb,
        texelFetch(SkyColorSampler, ivec2(1, 1), 0).rgb,
        smoothstep(0.5, -1.2, cndsd) * texValue * texValue * texValue
      );
      vec3 nightCloudsColor = mix(
        texelFetch(SkyColorSampler, ivec2(2, 0), 0).rgb,
        texelFetch(SkyColorSampler, ivec2(2, 1), 0).rgb,
        smoothstep(-0.5, 1.2, cndsd) * texValue * texValue * texValue
      );

      float fSunsetClouds = smoothstep(0.9, -0.9, cndsd);
      vec3 sunsetCloudsColor = mix(
        mix(
          texelFetch(SkyColorSampler, ivec2(3, 0), 0).rgb,
          texelFetch(SkyColorSampler, ivec2(3, 1), 0).rgb,
          linearstep(0, 0.5, fSunsetClouds)
        ),
        texelFetch(SkyColorSampler, ivec2(3, 2), 0).rgb,
        linearstep(0.5, 1, fSunsetClouds)
      );

      clouds = vec4(
        mix(
          mix(nightCloudsColor, dayCloudsColor, dayLight),
          sunsetCloudsColor,
          smoothstep(-0.35, 0, timeOfDay) * smoothstep(0.25, 0, timeOfDay) * smoothstep(-1 + 0.6 * (1 - dayLight), 1, dot(nd, sunDir))
        ),
        mix(smoothstep(0, 0.8, texValue), texValue, dayLight) * skyTopMask * (1.0 - weather)
        #ifdef ENABLE_POST_SUN
          * (1.0 - sun.a * sun.a * sun.a)
        #endif
      );

      // Light up the edges of clouds near the sun, moon and auroras
      cloudsAdditive = vec3((
        // Sun
          dayLight * smoothstep(0.0, 1.0, ddsd) * 0.8
        // Moon + auroras
        + (1.0 - dayLight) * (
          smoothstep(0.0, -1.0, ddsd)
          #ifdef ENABLE_POST_MOON
            * (fakeSunDir.z + 2.0) / 6.0
          #else
            * 0.45
          #endif
          + auroras
        )
      ) * smoothstep(0.05, 0.5, texValue) * smoothstep(0.9, 0, texValue) * skyTopMask) * (1.0 - weather);
    #endif

    vec4 screenPos = gl_FragCoord;
    screenPos.xy = (screenPos.xy / OutSize - vec2(0.5)) * 2.0;
    screenPos.zw = vec2(1.0);
    vec3 view = normalize((projInv * screenPos).xyz);
    float ndusq = clamp(dot(view, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
    ndusq = ndusq * ndusq;

    vec4 finalColor = linear_fog(vec4(
      mix(
        mix(
          mix(stars, moon.rgb, moon.a),
          atmosphere.rgb, atmosphere.a - 0.3 * moon.a * moon.a * dayLight
        ) + auroras * (1.0 - dayLight),
        clouds.rgb, clouds.a
      ) + cloudsAdditive, 1
    ), pow(1.0 - ndusq, 6.0), 0.0, 1.0, mix(fogColor, vec4(0.827, 0.447, 0.27, 1), rm));

    fragColor = vec4(mix(
      finalColor.rgb,
      fragColor.rgb,
      fragColor.a
    ), 1);
  }
}
