#version 150

#moj_import <../config.txt>

in vec3 Position;
in vec2 UV0;

uniform sampler2D Sampler0;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out mat4 ProjInv;
out vec3 cscale;
out vec3 c1;
out vec3 c2;
out vec3 c3;
out vec2 texCoord0;
out vec4 vertexColor;
out float isSun;
out float isNeg;
out vec2 ScrSize;

#ifdef ENABLE_POST_MOON_PHASES
  flat out float moonPhase;
#endif

#define SUNSIZE 60
#define SUNDIST 110
#define OVERLAYSCALE 2.0

void main() {
  vec4 candidate = ProjMat * ModelViewMat * vec4(Position, 1.0);
  ProjInv = mat4(0.0);
  cscale = vec3(0.0);
  c1 = vec3(0.0);
  c2 = vec3(0.0);
  c3 = vec3(0.0);
  isSun = 0.0;
  vec2 tsize = textureSize(Sampler0, 0);

  // test if sun or moon. Position.y limit excludes worldborder.
  if (Position.y < SUNDIST  && Position.y > -SUNDIST && (ModelViewMat * vec4(Position, 1.0)).z > -SUNDIST) {

    // only the sun has a 64x64 texture
    if (tsize.x == 64 && tsize.y == 64) {
      isSun = 1.0;
      candidate = vec4(-2.0 * OVERLAYSCALE, -OVERLAYSCALE, 0.0, 1.0);

      // modify position of sun so that it covers the entire screen and store c1, c2, c3 so player space position of sun can be extracted in fsh.
      // this is the key to get everything working since it guarantees that we can access sun info in the control pixels in fsh.
      if (UV0.x < 0.5) {
        c1 = Position;
        cscale.x = 1.0;
      } else {
        candidate.x = OVERLAYSCALE;
        if (UV0.y < 0.5) {
          c2 = Position;
          cscale.y = 1.0;
        } else {
          candidate.y = 2.0 * OVERLAYSCALE;
          c3 = Position;
          cscale.z = 1.0;
        }
      }
      ProjInv = inverse(ProjMat * ModelViewMat);
    } else { // Moon
      isSun = 0.5;

      #ifdef ENABLE_POST_MOON_PHASES
        candidate = vec4(-2.0 * OVERLAYSCALE, -OVERLAYSCALE, 0.0, 1.0);

        int vidm4 = gl_VertexID % 4;
        if (vidm4 == 2) {
          moonPhase = UV0.x / 2.0 + UV0.y;
          candidate.x = OVERLAYSCALE;
          candidate.y = 2.0 * OVERLAYSCALE;
        } else if (vidm4 == 1) {
          candidate.x = OVERLAYSCALE;
        }
      #endif
    }
  }

  gl_Position = candidate;
  texCoord0 = UV0;
  isNeg = float(UV0.y < 0);
  ScrSize = 2 / vec2(ProjMat[0][0], -ProjMat[1][1]);
}
