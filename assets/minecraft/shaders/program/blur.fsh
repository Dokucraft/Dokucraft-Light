#version 150

//=====================================================================================================================

/*
  Some menu effects may require a specific blur radius, and therefore can not support the accessibility setting that
  controls the blur radius. Removing this line disables the setting, so that it doesn't affect the radius anymore.
*/
#define ENABLE_ACCESSIBILITY_SETTING

//=====================================================================================================================

uniform sampler2D DiffuseSampler;

in vec2 texCoord;
in vec2 oneTexel;

uniform vec2 InSize;

uniform vec2 BlurDir;
uniform float Radius;
uniform float Alpha;

out vec4 fragColor;

void main() {
  vec3 blurred = vec3(0.0);
  float totalStrength = 0.0;
  // float totalAlpha = 0.0;
  for (float r = -Radius; r <= Radius; r += 1.0) {
    vec4 sampleValue = texture(DiffuseSampler, texCoord + oneTexel * BlurDir * r
      #ifdef ENABLE_ACCESSIBILITY_SETTING
        * Alpha
      #endif
    );

    // Accumulate average alpha
    // totalAlpha = totalAlpha + sampleValue.a;

    // Gaussian blur
    float strength = exp(-4.5 * r * r / (Radius * Radius));
    totalStrength = totalStrength + strength;
    blurred = blurred + sampleValue.rgb * strength;
  }
  fragColor = vec4(blurred / totalStrength, 1);
}
