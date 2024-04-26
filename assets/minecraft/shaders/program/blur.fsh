#version 150

//=====================================================================================================================

/*
  Some menu effects may require a specific blur radius, and therefore can not support the accessibility setting that
  controls the blur radius. Uncommenting this line will override the accessibility setting with a constant value.
*/
// #define RADIUS_OVERRIDE 0.2

//=====================================================================================================================

uniform sampler2D DiffuseSampler;

in vec2 texCoord;
in vec2 oneTexel;

uniform vec2 InSize;

uniform vec2 BlurDir;
uniform float SampleRadius;

#ifndef RADIUS_OVERRIDE
  uniform float Radius;
#endif

out vec4 fragColor;

void main() {
  vec3 blurred = vec3(0.0);
  float totalStrength = 0.0;
  // float totalAlpha = 0.0;
  for (float r = -SampleRadius; r <= SampleRadius; r += 1.0) {
    vec4 sampleValue = texture(DiffuseSampler, texCoord + oneTexel * BlurDir * r
      #ifdef RADIUS_OVERRIDE
        * RADIUS_OVERRIDE
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
