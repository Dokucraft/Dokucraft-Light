#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <dokucraft:config.glsl>

#ifdef ENABLE_CUSTOM_SKY
  #moj_import <minecraft:utils.glsl>
#endif

uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
flat in vec4 vertexColor;

#ifdef ENABLE_CUSTOM_SKY
  in vec4 glpos;
#endif

out vec4 fragColor;

void main() {
  #ifdef ENABLE_CUSTOM_SKY
    discardControlGLPos(gl_FragCoord.xy, glpos);
  #endif

  fragColor = linear_fog(vertexColor, vertexDistance, FogStart, FogEnd, FogColor);
}
