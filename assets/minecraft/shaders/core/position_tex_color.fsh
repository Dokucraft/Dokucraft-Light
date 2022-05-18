#version 150

#moj_import <utils.glsl>
#moj_import <../config.txt>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float GameTime;

in vec2 texCoord0;
in vec4 vertexColor;
in vec4 Pos;
in vec3 direction;

out vec4 fragColor;

#ifdef ENABLE_CUSTOM_END_SKY
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

  float star(vec2 uv, float maxVal, float crossIntensity, float distScale, float starScale) {
    float d = length(uv * starScale);
    return min((0.1 / d + max(0.0, 1.0 - abs(uv.x * uv.y * 600))*8 * crossIntensity) * smoothstep(1, 0.1, d * distScale), maxVal);
  }

  vec3 starfield(vec3 direction, int scsqrt, float bandPow, float maskOpacity, float maskOffset, float crossIntensity, float distScale, float twinkle, float time) {
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
      color = color * vec3(0.1, 0.2, 0.1) + vec3(0.9, 0.6, 0.9);
      col += vec3(star(gv - o - vec2(n, fract(n * 34.2)) + 0.5, 15, crossIntensity, distScale, 1 + (sin(time + n * 23.2)) * 0.5 * twinkle)) * size * color;
    }
    return col / 9 * pow(1.0 - abs(direction.y), bandPow) * (1 - maskOpacity * smoothstep(-0.25, 0.5, vec3(cnoise(normalize(direction + maskOffset) * 2))));
  }
#endif

void main() {
  vec4 color = texture(Sampler0, texCoord0) * vertexColor;
  if(Pos.z == -1999)
  {
    vec2 texCord = abs(texCoord0);
    ivec2 block = ivec2(texCord);
    int variate;

    vec2 offset = vec2(0);
    
    //Grass
    if (block.y < 1) offset = vec2(0.2);

    //Dirt/Stone
    if (block.y == 3)
    {
      variate = ((block.x * block.x + 6) % 10) / 5;
      offset = vec2(0.2 * clamp(variate, 0, 1), 0);
    }

    //Stone + ores
    if(block.y > 3 && block.y < 70)
    {
      offset = vec2(0.2, 0); //Stone

      if (int(block.y * 3 + sin(block.x * 5.1) * 2.4) % 10 == 0) offset = vec2(0.6); //Coal

      if(int(block.y * 6.5 + sin(block.x * 3.0 + 2.3) * 32.1) % 25 == 0) offset = vec2(0.4); //Copper
      
      if(block.y >= 6 && int(block.y * 5.5 + sin(block.x * 2.0 + 4.3) * 30.1) % 15 == 0) offset = vec2(0.4, 0.6); //Iron

      if(block.y >= 39)
      {
        if(int(block.y * 8.5 + sin(block.x * 4.05 + 2.7) * 24.7) % 20 == 0) offset = vec2(0.2, 0.6); //Gold
        
        if(int(block.y * 6.2 + sin(block.x * 1.05 + 2.8) * 21.7) % 30 == 0) offset = vec2(0.2, 0.4); //Lapis
        
        if(block.y >= 55)
        {
          if(int(block.y * 4.5 + sin(block.x * 2.05 + 2.8) * 23.7) % 25 == 0) offset = vec2(0, 0.4); //Redstone

          if(int(block.y * 1.5 + sin(block.x * 1.05 + 4) * 21.6) % 23 == 0) offset = vec2(0, 0.6); //Diamonds!

          variate = ((block.x * block.x + 6 * block.y) % 10) / 5;
          if(block.y >= 68 && clamp(variate, 0, 1) == 1) offset = vec2(0.4, 0.2); //Deepslate
        }

      }
      
    } 
    if(block.y >= 70 && block.y <= 134)// offset = vec2(0.4, 0);
    {
      offset = vec2(0.4, 0.2); //Plain deepslate

      if(int(block.y * 5.5 + sin(block.x * 2.0 + 4.3) * 30.1) % 20 == 0) offset = vec2(0.4, 0.8); //Iron

      if(int(block.y * 8.5 + sin(block.x * 4.05 + 2.7) * 24.7) % 24 == 0) offset = vec2(0.2, 0.8); //Deepslate Gold
    
      if(int(block.y * 6.2 + sin(block.x * 1.05 + 2.8) * 21.7) % 35 == 0) offset = vec2(0.8); //Deepslate Lapis
      
      if(int(block.y * 4.5 + sin(block.x * 2.05 + 2.8) * 23.7) % 27 == 0) offset = vec2(0.8, 0.6); //Deepslate Redstone

      if(int(block.y * 1.5 + sin(block.x * 1.05 + 4) * 21.6) % 30 == 0) offset = vec2(0, 0.8); //Deepslate Diamonds

      variate = ((block.x * block.x + 6 * block.y + 5) % 10) / 5;
      if(block.y >= 132 && clamp(variate, 0, 1) == 1) offset = vec2(0, 0.2); //Bedrock (How did we get here?)
      if(block.y == 134) offset = vec2(0, 0.2);
    }
    if(block.y > 134) offset = vec2(0.4, 0);
    
    color = texture(Sampler0, (texCord - block) / 5.0 + offset) * vertexColor;
  }
  
  if (color.a < 0.1) {
    discard;
  }

  #ifdef ENABLE_CUSTOM_END_SKY
    if (floor(vertexColor.r * 255 + 0.5) == 40) {
      float gt = GameTime * 80;
      vec3 nd = normalize(direction);
      float f = smoothstep(0.1, 0.9, dot(vec3(0,1,0), nd) * ((cnoise(nd * 2 + 11 + gt) + cnoise(nd * 6 + 11 - gt) * 0.5 + cnoise(nd * 12 + 11 + vec3(0, gt, 0)) * 0.25) / 3.5 + 0.5));
      float riftMask = smoothstep(0.7, 0.6, f * 2);
      vec3 riftND = rotate(rotate(nd, vec3(1, 0, 0), gt / 5), vec3(0, 0, 1), M_PI / 2);

      #ifdef ENABLE_END_SKY_RIFT_GLOW
        float riftGlow = riftMask * f * 2;
      #endif

      fragColor = vec4(

        #ifdef ENABLE_END_SKY_RIFT_GLOW
          END_SKY_RIFT_COLOR * (riftGlow + pow(riftGlow + 0.2, 16) * END_SKY_RIFT_EDGE_COLOR)
        #else
          vec3(0)
        #endif

        #ifdef ENABLE_END_SKY_STARS_OUTSIDE_RIFT
          + ( // Outside of rift
              starfield(rotate(nd, vec3(1, 0, 0), 2.4), 48, 1, 1, 25, 0, 1, 0, 0)
            + starfield(rotate(nd, vec3(1, 0, 0), 2.4 + M_PI / 2), 32, 1, 1, 12, 0, 1, 0, 0)
            + vec3(0.8, 0.1, 0.9) * smoothstep(0.1, 1.1, cnoise(nd * 2 + 14) * 0.5 + 0.5) * 0.1
          ) * riftMask
        #endif

        #ifdef ENABLE_END_SKY_STARS_INSIDE_RIFT
          + ( // Inside rift
              starfield(riftND, 130, 1, 1, 25, 0, 1, 0, 0) * vec3(0.2, 2, 3)
            + starfield(riftND, 32, 1, 1, 25, 1, 3, 1, gt * 60) * vec3(1, 2, 3)
            + vec3(0.2, 0.5, 0.9) * smoothstep(0.2, 1, cnoise(riftND * 2 + 63) * 0.5 + 0.5) * 0.4
          ) * (1 - riftMask)
        #endif

      , 1);
    } else {
      fragColor = color * ColorModulator;
    }
  #else
    fragColor = color * ColorModulator;
  #endif
}
