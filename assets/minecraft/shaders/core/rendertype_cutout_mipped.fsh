#version 150

#moj_import <fog.glsl>
#moj_import <utils.glsl>
#moj_import <emissive_utils.glsl>
#moj_import <../config.txt>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;
in vec4 normal;
in vec4 glpos;

#if GRASS_TYPE > 0
  flat in int type;
#endif

#if GRASS_TYPE == 2
  in vec3 shellGrassUV;
#endif

out vec4 fragColor;

#if GRASS_TYPE == 2
  float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
  }
#endif

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);

  #if GRASS_TYPE == 1
    if (type == 1) {
      fragColor = linear_fog(vertexColor, vertexDistance, FogStart, FogEnd, FogColor);
      return;
    }
  #elif GRASS_TYPE == 2
    if (type == 1) {
      vec2 px = floor(shellGrassUV.xy);
      vec2 o = vec2(
        hash12(px + 47.183),
        hash12(px + 189.215)
      ) * 0.5 + 0.25;
      float n = hash12(px);
      vec2 co = o - fract(shellGrassUV.xy);
      float c = max(0, 1.0 - mix(max(abs(co.x), abs(co.y)), length(co), shellGrassUV.z / n) * 2);
      if (n * c < shellGrassUV.z) {
        discard;
      }
      vec4 col = texture(Sampler0, texCoord0);
      fragColor = linear_fog(vertexColor * vec4(vec3(mix(0.65, 1, col.r)), 1), vertexDistance, FogStart, FogEnd, FogColor);
      return;
    }
  #endif

  vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
  float alpha = textureLod(Sampler0, texCoord0, 0.0).a * 255.0;
  color = make_emissive(color, lightColor, vertexDistance, alpha);
  if (color.a < 0.5) discard;
  fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
