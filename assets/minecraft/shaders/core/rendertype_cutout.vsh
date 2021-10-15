#version 150

#moj_import <light.glsl>

const float PHI = 1.61803398875;
const float SWAYING_AMOUNT = 0.1;
const float SWAYING_SPEED = 1000.0;
const float EPSILON = 0.001;

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;
uniform sampler2D Sampler0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;
uniform float GameTime;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

mat3 tbn(vec3 normal, vec3 up) {
  vec3 tangent = normalize(cross(up, normal));
  vec3 bitangent = cross(normal, tangent);
  
  return mat3(tangent, bitangent, normal);
}

void main() {
  vec3 position = Position + ChunkOffset;
  float animation = GameTime * 4000.0;

  float xs = 0.0;
  float ys = 0.0;
  float zs = 0.0;
  int alpha = int(textureLod(Sampler0, UV0, 0).a * 255 + 0.5);
  /*
    Fix for Optifine breaking some things
      Optifine clamps alpha values <=16 to 0, so don't use alpha values below 17 in shaders
      These alpha values were changed:
        1  -> 18
        2  -> 19
        3  -> 20
        4  -> 21
        11 -> 22
  */
  if (alpha == 18 || alpha == 253 ) {
    xs = sin(position.x + position.y + animation) * -1.0;
    zs = cos(position.z + position.y + animation) * -1.0;
  } else if (alpha == 19 || alpha == 252 ) {
    xs = sin(position.x + position.y + animation) * -2.0;
    zs = cos(position.z + position.y + animation) * -2.0;
  } else if (alpha == 20 || alpha == 254 ) {
    xs = sin(position.x + position.y + animation) * -0.5;
    zs = cos(position.z + position.y + animation) * -0.5;
  } else if (alpha == 21 || alpha == 251 ) { // half intensity sway for the connection between the upper and lower halves of the fern
    xs = sin(position.x + position.y + animation) * -0.25;
    zs = cos(position.z + position.y + animation) * -0.25;
  } else if (alpha == 22) { // very weak, delayed sway used for the bottom of the torch fire
    xs = sin(position.x + position.y + animation - 1.0) * -0.5;
    zs = cos(position.z + position.y + animation - 1.0) * -0.5;
  }

  gl_Position = ProjMat * ModelViewMat * (vec4(position, 1.0) + vec4(xs / 32.0, ys, zs / 32.0, 0.0));
  if (alpha == 141 || alpha == 24) {

    float time = (1.0 + fract(dot(floor(Position), vec3(1))) / 2.0) * GameTime * SWAYING_SPEED + dot(floor(Position), vec3(1)) * 1234.0;
    vec3 newForward = normalize(vec3(
      sin(time) * SWAYING_AMOUNT,
      sin(time * PHI) * SWAYING_AMOUNT,
      -1 + sin(time * 3.14) * SWAYING_AMOUNT
    ));

    vec3 relativePos = fract(Position);
    if (relativePos.y > EPSILON) {
      relativePos += vec3(xs / 32.0, ys, zs / 32.0);
      relativePos -= vec3(0.5, 1, 0.5);
      relativePos = tbn(newForward, vec3(0, 1, 0)) * relativePos;
      vec3 newPos = relativePos + vec3(0.5, 1, 0.5);
      gl_Position = ProjMat * ModelViewMat * vec4(floor(Position) + newPos + ChunkOffset, 1.0);
    }
    
  }

  vertexDistance = length((ModelViewMat * vec4(Position + ChunkOffset, 1.0)).xyz);
  vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
  lightColor = minecraft_sample_lightmap(Sampler2, UV2);
  texCoord0 = UV0;
  normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
  glpos = gl_Position;
}
