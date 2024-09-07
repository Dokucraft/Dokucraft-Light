#version 330

#moj_import <dokucraft:config.glsl>

uniform sampler2D MainSampler;

in vec2 texCoord;
in vec2 oneTexel;

uniform vec2 BlurDir;
uniform float SampleRadius;

#if MENU_BACKGROUND < 2
  uniform float Radius;
#endif

out vec4 fragColor;

void main() {
  vec3 blurred = vec3(0.0);
  float totalStrength = 0.0;
  // float totalAlpha = 0.0;
  for (float r = -SampleRadius; r <= SampleRadius; r += 1.0) {
    vec4 sampleValue = texture(MainSampler, texCoord + oneTexel * BlurDir * r
      #if MENU_BACKGROUND == 2
        * 0.2
      #else
        * Radius * 0.1
      #endif
    );

    // Accumulate average alpha
    // totalAlpha = totalAlpha + sampleValue.a;

    // Gaussian blur
    float strength = exp(-4.5 * r * r / (SampleRadius * SampleRadius));
    totalStrength = totalStrength + strength;
    blurred = blurred + sampleValue.rgb * strength;
  }
  fragColor = vec4(blurred / totalStrength, 1);
}
