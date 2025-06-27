#version 330

// Can't moj_import in things used during startup, when resource packs don't exist.
#define ENABLE_BUTTON_GRADIENTS

layout(std140) uniform DynamicTransforms {
  mat4 ModelViewMat;
  vec4 ColorModulator;
  vec3 ModelOffset;
  mat4 TextureMat;
  float LineWidth;
};
layout(std140) uniform Projection {
  mat4 ProjMat;
};

in vec3 Position;
in vec2 UV0;
in vec4 Color;

out vec3 cscale;
out vec2 texCoord0;
out vec4 vertexColor;

void main() {
  vec4 candidate = ProjMat * ModelViewMat * vec4(Position, 1.0);
  texCoord0 = UV0;
  vertexColor = Color;

  #ifdef ENABLE_BUTTON_GRADIENTS
    const vec2[] corners = vec2[](vec2(0), vec2(0, 1), vec2(1), vec2(1, 0));
    vec2 corner = corners[gl_VertexID % 4];
    
    cscale = vec3(corner, 1);
  #endif

  gl_Position = candidate;
}
