#version 150
#define NOTES_COUNT 12

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

out float vertexDistance;
out vec2 texCoord0;
out vec4 vertexColor;
out vec4 lightColor;
out vec4 glpos;

float getHue(vec3 rgb) {
  vec3 hsv = vec3(0.0);
  hsv.z = max(rgb.r, max(rgb.g, rgb.b));
  float min = min(rgb.r, min(rgb.g, rgb.b));
  float c = hsv.z - min;

  vec3 delta = (hsv.z - rgb) / c;
  delta.rgb -= delta.brg;
  delta.rg += vec2(2.0, 4.0);
  if (rgb.r >= hsv.z) {
    hsv.x = delta.b;
  } else if (rgb.g >= hsv.z) {
    hsv.x = delta.r;
  } else {
    hsv.x = delta.g;
  }
  hsv.x = fract(hsv.x / 6.0);

  return hsv.x;
}

void main() {
  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

  vertexDistance = fog_distance(Position, FogShape);
  texCoord0 = UV0;
  vertexColor = Color;
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);

  vec2 texSize = textureSize(Sampler0, 0);
  vec2 uv = floor(UV0 * texSize);

  const vec2[4] corners = vec2[4](vec2(1, 1), vec2(1, 0), vec2(0), vec2(0, 1));
  vec2 corner = corners[gl_VertexID % 4];

  vec4 testColor = floor(texelFetch(Sampler0, ivec2(uv - corner), 0) * 255);

  if (testColor == vec4(0, 0, 255, 26) && Color != vec4(1)) { // Note
    uv -= vec2(48, 32) * corner;

    int id = int(24 - round(getHue(Color.rgb) * 24)) % NOTES_COUNT; // Red note - C
    uv += vec2(id % 4, id / 4 % 3) * 16;

    gl_Position += vec4((corner * 2 - 1), 1, 0) * vec4(0.1, -0.1, 0, 0) * ProjMat; // Expand Note
    texCoord0 = uv / texSize;
  }

  glpos = gl_Position;
}
