#version 150


/* ------------------------------- Settings -------------------------------- */

// Remove this line to disable the reddening of the skybox during sunrise/sunset.
#define ENABLE_REDDENING

// Uncomment this line to enable the experimental procedural night sky
// #define ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY

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

#ifdef ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY
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

  vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
  vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
  vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

  float cnoise(vec3 P){
    vec3 Pi0 = floor(P);
    vec3 Pi1 = Pi0 + vec3(1.0);
    Pi0 = mod(Pi0, 289.0);
    Pi1 = mod(Pi1, 289.0);
    vec3 Pf0 = fract(P);
    vec3 Pf1 = Pf0 - vec3(1.0);
    vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    vec4 iy = vec4(Pi0.yy, Pi1.yy);
    vec4 iz0 = Pi0.zzzz;
    vec4 iz1 = Pi1.zzzz;

    vec4 ixy = permute(permute(ix) + iy);
    vec4 ixy0 = permute(ixy + iz0);
    vec4 ixy1 = permute(ixy + iz1);

    vec4 gx0 = ixy0 / 7.0;
    vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
    gx0 = fract(gx0);
    vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
    vec4 sz0 = step(gz0, vec4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);

    vec4 gx1 = ixy1 / 7.0;
    vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
    gx1 = fract(gx1);
    vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
    vec4 sz1 = step(gz1, vec4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);

    vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
    vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
    vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
    vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
    vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
    vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
    vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
    vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

    vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
    g000 *= norm0.x;
    g010 *= norm0.y;
    g100 *= norm0.z;
    g110 *= norm0.w;
    vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
    g001 *= norm1.x;
    g011 *= norm1.y;
    g101 *= norm1.z;
    g111 *= norm1.w;

    float n000 = dot(g000, Pf0);
    float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
    float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
    float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
    float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
    float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
    float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
    float n111 = dot(g111, Pf1);

    vec3 fade_xyz = fade(Pf0);
    vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
    vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
    return 2.2 * n_xyz;
  }

  float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
  }

  float star(vec2 uv) {
    float d = length(uv);
    return min((0.1 / d /* + max(0.0, 1.0 - abs(uv.x * uv.y * 5000))*2 */) * smoothstep(1, 0.1, d), 15);
  }

  vec3 starfield(vec3 direction, int scsqrt) {
    float l = max(max(abs(direction.x), abs(direction.y)), abs(direction.z));
    vec3 dir = direction / l;
    vec3 absDir = abs(dir);

    vec2 uv;
    if (absDir.x >= absDir.y && absDir.x > absDir.z) {
      if (dir.x > 0) {
        uv = (dir.zy * vec2(1, -1) + 1) / 2;
      } else {
        uv = (-dir.zy + 1) / 2;
      }
    } else if (absDir.y >= absDir.z) {
      if (dir.y > 0) {
        uv = (dir.xz * vec2(-1, 1) + 1) / 2;
      } else {
        uv = (-dir.xz + 1) / 2;
      }
    } else {
      if (dir.z > 0) {
        uv = (-dir.xy + 1) / 2;
      } else {
        uv = (dir.xy * vec2(1, -1) + 1) / 2;
      }
    }

    vec2 scaledUV = uv * scsqrt;
    // scaledUV = floor(scaledUV * 16) / 16; // Pixelization filter
    vec2 gv = fract(scaledUV) - 0.5;
    vec2 id = floor(scaledUV);
    vec3 col = vec3(0);
    float mask = smoothstep(0, 0.5/scsqrt, 0.5 - max(abs(0.5 - uv.x), abs(0.5 - uv.y)));

    for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
      vec2 o = vec2(x, y);
      vec2 oid = id + o;
      if (oid.x >= 0 && oid.x < scsqrt && oid.y >= 0 && oid.y < scsqrt) {
        float n = hash21(oid);
        float size = fract(n * 745.32);
        vec3 color = sin(vec3(0.2, 0.3, 0.9) * fract(n * 2345.7) * 109.2) * 0.5 + 0.5;
        color = color * vec3(0.4, 0.2, 0.1) + vec3(0.4, 0.6, 0.9);
        col += vec3(star(gv - o - vec2(n, fract(n * 34.2)) + 0.5)) * size * color * mask;
      }
    }

    return smoothstep(-0.25, 0.5, vec3(cnoise(normalize(direction)*2))) * col / 9;
  }
#endif


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

    #ifdef ENABLE_EXPERIMENTAL_PROCEDURAL_NIGHT_SKY
      mat4 timeRotMat = rotationMatrix(vec3(0, 0, 1), atan(sunDir.y, sunDir.x));
      vec3 ndr = (timeRotMat * vec4(normalize(direction), 1.0)).xyz;
      vec3 nightSkybox =
        // Nearby stars
        starfield(rotate(ndr, vec3(-0.8, 0.2, -0.5), 0.3), 16) +
        starfield(rotate(ndr, vec3(0.7, 0.3, -0.6), 1.2), 32) +
        starfield(rotate(ndr, vec3(-0.9, 0.8, 0.4), 2.1), 40) +
        // Distant stars
        starfield(rotate(ndr, vec3(1), 1.5), 160) * 0.4 +
        starfield(rotate(ndr, vec3(-1, 1, -1), 1), 160) * vec3(0.4, 0.1, 0.4) +
        // Nebulae
        vec3(0.2, 0.5, 0.9) * smoothstep(0.2, 1, cnoise(ndr * 2 + 12) * 0.5 + 0.5) * 0.5 +
        vec3(0.8, 0.1, 0.9) * smoothstep(0.1, 1.1, cnoise(ndr * 2 + 14) * 0.5 + 0.5) * 0.1;
    #else
      vec3 nightSkybox = sampleSkybox(SkyBoxNightSampler, direction);
    #endif

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
