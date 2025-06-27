#version 330

// Can't moj_import in things used during startup, when resource packs don't exist.
#define ENABLE_BUTTON_GRADIENTS
#define BUTTON_GRADIENT_COLOR_A vec3(0.996, 0.996, 0.992)
#define BUTTON_GRADIENT_COLOR_B vec3(0.65, 0.658, 0.619)

layout(std140) uniform DynamicTransforms {
  mat4 ModelViewMat;
  vec4 ColorModulator;
  vec3 ModelOffset;
  mat4 TextureMat;
  float LineWidth;
};

uniform sampler2D Sampler0;

in vec3 cscale;
in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;

void main() {
  vec4 color = vec4(0.0);

  #ifdef ENABLE_BUTTON_GRADIENTS
    color = texture(Sampler0, texCoord0);

    if (int(color.a * 255 + 0.5) == 252) {
      float cs = cscale.x / 2;

      if (color.g >= 0.99)
        cs += 0.5;

      if (color.b >= 0.99)
        cs = 0.5;

      cs = color.r >= 0.99 ? cs : 1 - cs;

      color.rgb = mix(BUTTON_GRADIENT_COLOR_A, BUTTON_GRADIENT_COLOR_B, clamp(cs, 0, 1));
    }

    color *= ColorModulator * vertexColor;
  #else
    color = texture(Sampler0, texCoord0) * ColorModulator * vertexColor;
  #endif

  if (color.a < 0.01 || ivec2(floor(color.ra * 255.0 + 0.5)) == ivec2(241, 16)) {
    discard;
  }
  fragColor = color;
}
