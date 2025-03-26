#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <dokucraft:config.glsl>

in vec3 Position;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec4 ColorModulator;
uniform int FogShape;

out float vertexDistance;
flat out vec4 vertexColor;

#ifdef ENABLE_CUSTOM_SKY
  out vec4 glpos;
#endif

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

  #ifdef ENABLE_CUSTOM_SKY
    glpos = gl_Position;
  #endif

  vertexDistance = fog_distance(Position, FogShape);
  vertexColor = Color * ColorModulator * texelFetch(Sampler2, UV2 / 16, 0);
}
