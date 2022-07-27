#version 150


/* ------------------------------- Settings -------------------------------- */

// Remove this line to disable the reddening of the skybox during sunrise/sunset.
// Very small impact on performance on most graphics cards
#define ENABLE_REDDENING

// Uncomment this line to enable the experimental procedural night sky
// Medium impact on performance on most graphics cards
// #define ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY

// Remove this line to disable the north star
// No noticeable impact on performance
// Requires ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY
#define ENABLE_NORTH_STAR

// Uncomment this line to enable auroras at night
// Major impact on performance on most graphics cards
// #define ENABLE_AURORAS

// Controls the colors of the auroras
// Requires ENABLE_AURORAS
#define AURORA_COLOR vec3(0.465, 2, 0.833)

/* ------------------------------------------------------------------------- */


uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform sampler2D SkyBoxDaySampler;
uniform sampler2D SkyBoxNightSampler;
uniform vec2 OutSize;

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

#ifdef ENABLE_REDDENING

  vec3 RGBToHSL(vec3 color) {
    vec3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)

    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = fmax - fmin;             //Delta RGB value

    hsl.z = (fmax + fmin) / 2.0; // Luminance

    if (delta == 0.0) { //This is a gray, no chroma...
      hsl.x = 0.0;  // Hue
      hsl.y = 0.0;  // Saturation

    } else {                                //Chromatic data...
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

#endif

/* ------------------------------------------------------------------------- */

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

#if defined(ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY) || defined(ENABLE_AURORAS)
  float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
  }
#endif

#ifdef ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY
  #define M_PI 3.141592653589793

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
    return noiseVal / 0.7;
  }

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
    return col*1.8;
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
  vec4 backgroundColor;
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

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
  if (vertexDistance <= fogStart) {
    return inColor;
  }

  float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;
  return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

void main() {
  float realDepth = linearizeDepth(texture(DepthSampler, texCoord).r);
  fragColor = texture(DiffuseSampler, texCoord);

  vec3 temp = fragColor.rgb - vec3(0.157, 0.024, 0.024);
  bool isNether = dot(temp, temp) < FUDGE;
  vec3 nd = normalize(direction);

  if (far > 50 && realDepth > far / 2 - 5) {

    vec3 daySkybox = sampleSkybox(SkyBoxDaySampler, direction);

    #ifdef ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY
      vec3 nightSkybox = vec3(0);

      if (timeOfDay < 0.1) {
        float sunAngle = atan(sunDir.y, sunDir.x);
        mat4 timeRotMat = rotationMatrix(vec3(0, 0, 1), sunAngle - M_PI / 6);
        vec3 ndr = (timeRotMat * vec4(nd, 1.0)).xyz;

        #ifdef ENABLE_NORTH_STAR
          vec3 nsp = normalize(normalize(vec3(0, 0.6, 1)) - nd);
        #endif

        nightSkybox =
          // Galactic disk
            starfield(rotate(ndr, vec3(1, 0, 0), 2.4), 96, 6, 0.75, 25) * 3
          // Nearby stars
          + starfield(rotate(ndr, vec3(0.7, 0.3, -0.6), 1.2), 32, 2, 1, 3)
          + starfield(rotate(ndr, vec3(-0.8, 0.2, -0.5), 0.3), 16, 2, 1, 9)
          + starfield(rotate(ndr, vec3(-0.9, 0.8, 0.4), 2.1), 40, 2, 1, 13) * 1.1
          // Distant stars/galaxies
          + starfield(rotate(ndr, vec3(1), 1.5), 160, 1, 1, 31)
          // Nebulae
          + vec3(0.2, 0.5, 0.9) * smoothstep(0.2, 1, flownoise(ndr * 2 + 46) * 0.5 + 0.5) * 0.4
          + vec3(0.8, 0.1, 0.9) * smoothstep(0.1, 1.1, flownoise(ndr * 2 + 14) * 0.5 + 0.5) * 0.1

          #ifdef ENABLE_NORTH_STAR
            + max(vec3(1 - abs(nsp.x * nsp.y * 150000)) * 2, 0) * smoothstep(0.0175, 0.00175, length(nsp.xy)) * vec3(0.5, 0.75, 1)
          #endif

          #ifdef ENABLE_AURORAS
            + aurora(nd, sunAngle * 1000) * 0.5 * smoothstep(-1.025, -0.9, dot(nd, sunDir))
          #endif
        ;
      }
    #else
      vec3 nightSkybox = sampleSkybox(SkyBoxNightSampler, (rotationMatrix(vec3(0, 0, 1), atan(sunDir.y, sunDir.x)) * vec4(nd, 1.0)).xyz);

      #ifdef ENABLE_AURORAS
        if (timeOfDay < 0.1) {
          float sunAngle = atan(sunDir.y, sunDir.x);
          nightSkybox += aurora(nd, sunAngle * 1000) * 0.5 * smoothstep(-1.025, -0.9, dot(nd, sunDir));
        }
      #endif
    #endif

    #ifdef ENABLE_REDDENING
      float hm = (1.5 + clamp(dot(nd, vec3(0, -1, 0)) * 2, -1.5, 0.5)) / 2;
      vec3 horizon = vec3(0.728308,0.04059,0.036865);
      float rm = max(0, (1 + dot(nd, normalize(sunDir))) / 2);
      rm *= rm * (max(0.75, 1 - abs(timeOfDay)) - 0.75) * 4;
      daySkybox = mix(daySkybox, mix(BlendColor(daySkybox, horizon), horizon, hm) / (1 - pow(smoothstep(-5, 3, dot(nd, sunDir)), 4) * vec3(1, 0.48, 0.24)), rm);
    #endif

    float factor = smoothstep(-0.1, 0.1, timeOfDay);

    vec3 skyColor = mix(nightSkybox, daySkybox, factor);

    vec4 screenPos = gl_FragCoord;
    screenPos.xy = (screenPos.xy / OutSize - vec2(0.5)) * 2.0;
    screenPos.zw = vec2(1.0);
    vec3 view = normalize((projInv * screenPos).xyz);
    float ndusq = clamp(dot(view, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
    ndusq = ndusq * ndusq;

    #ifdef ENABLE_REDDENING
      vec4 finalColor = linear_fog(vec4(skyColor, 1), pow(1.0 - ndusq, 6.0), 0.0, 1.2, mix(fogColor, vec4(1, 0.538316, 0.369141, 1), rm) / fogColor.a);
    #else
      vec4 finalColor = linear_fog(vec4(skyColor, 1), pow(1.0 - ndusq, 6.0), 0.0, 1.2, fogColor / fogColor.a);
    #endif

    fragColor = vec4(mix(
      finalColor.rgb,
      fragColor.rgb,
      fragColor.a
    ), 1);
  }
}
