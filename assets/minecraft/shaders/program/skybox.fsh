#version 150


/* ------------------------------- Settings -------------------------------- */

// Remove this line to disable the reddening of the skybox during sunrise/sunset.
#define ENABLE_REDDENING

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

  if (far > 50 && realDepth > far / 2 - 5) {

    vec3 daySkybox = sampleSkybox(SkyBoxDaySampler, direction);
    vec3 nightSkybox = sampleSkybox(SkyBoxNightSampler, direction);

    #ifdef ENABLE_REDDENING
      float hm = (1.5 + clamp(dot(normalize(direction), vec3(0, -1, 0)) * 2, -1.5, 0.5)) / 2;
      vec3 horizon = vec3(0.728308,0.04059,0.036865);
      float rm = max(0, (1 + dot(normalize(direction), normalize(sunDir))) / 2);
      rm *= rm * (max(0.75, 1 - abs(timeOfDay)) - 0.75) * 4;
      daySkybox = mix(daySkybox, mix(BlendColor(daySkybox, horizon), horizon, hm), rm);
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
