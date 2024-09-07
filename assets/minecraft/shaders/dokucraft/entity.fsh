#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:utils.glsl>
#moj_import <minecraft:emissive_utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 shadeColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 glpos;

out vec4 fragColor;

void main() {
  discardControlGLPos(gl_FragCoord.xy, glpos);

  vec4 color = texture(Sampler0, texCoord0);
  #ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
      discard;
    }
  #endif

  color *= vertexColor * ColorModulator;

  #ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
  #endif

  float alpha = color.a * 255.0;
  color = make_emissive(color, shadeColor, alpha);
  color.a = remap_alpha(alpha) / 255.0;

  #ifndef EMISSIVE
    color *= lightMapColor;
  #endif

  fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
