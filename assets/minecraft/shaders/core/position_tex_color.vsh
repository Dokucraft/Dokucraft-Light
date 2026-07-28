#version 330
#extension GL_ARB_separate_shader_objects : require

// Can't moj_import in things used during startup, when resource packs don't exist.
#define ENABLE_BUTTON_GRADIENTS

layout(std140) uniform DynamicTransforms {
  mat4 ModelViewMat;
  mat4 TextureMat;
  vec4 ColorModulator;
  vec3 ModelOffset;
};
layout(std140) uniform Projection {
  mat4 ProjMat;
};

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;

layout(location = 0) out vec2 texCoord0;
layout(location = 1) out vec4 vertexColor;
layout(location = 2) out vec3 cscale;

void main() {
  vec4 candidate = ProjMat * ModelViewMat * vec4(Position, 1.0);
  texCoord0 = UV0;
  vertexColor = Color;

  #ifdef ENABLE_BUTTON_GRADIENTS
    const vec2[] corners = vec2[](vec2(0), vec2(0, 1), vec2(1), vec2(1, 0));
    vec2 corner = corners[gl_VertexIndex % 4];
    
    cscale = vec3(corner, 1);
  #endif

  gl_Position = candidate;
}
