#version 330

#moj_import <minecraft:fog.glsl>

in vec3 Position;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;
uniform vec4 ColorModulator;

out mat4 ProjInv;
out float isSky;
flat out int isStars;
out float vertexDistance;

#define BOTTOM -32.0
#define SCALE 0.01
#define VOIDHEIGHT -16.0
#define SKYHEIGHT 16.0
#define SKYRADIUS 512.0
#define FUDGE 0.004

void main() {
  vec3 scaledPos = Position;
  isSky = 0.0;
  isStars = int(
    abs(Position.y - VOIDHEIGHT) > FUDGE &&
    abs(ColorModulator.r - 0.5) < FUDGE &&
    abs(ColorModulator.r - ColorModulator.g) < FUDGE &&
    abs(ColorModulator.r - ColorModulator.b) < FUDGE
  );

  // the sky is transformed so that it always covers the entire camera view. Guarantees that we can write to control pixels in fsh.
  // sky disk is by default 16.0 units above with radius of 512.0 around the camera at all times.
  if (abs(scaledPos.y - SKYHEIGHT) < FUDGE && (length(scaledPos.xz) <= FUDGE || abs(length(scaledPos.xz) - SKYRADIUS) < FUDGE)) {
    isSky = 1.0;

    // Make sky into a cone by bringing down edges of the disk.
    if (length(scaledPos.xz) > 1.0) {
      scaledPos.y = BOTTOM;
    }

    // Make it big so it does not interfere with void plane.
    scaledPos.xyz *= SCALE;

    // rotate to z axis
    scaledPos = scaledPos.xzy;
    scaledPos.z *= -1;

    // ignore model view so the cone follows the camera angle.
    gl_Position = ProjMat * vec4(scaledPos, 1.0);
  } else {
    gl_Position = ProjMat * ModelViewMat * vec4(scaledPos, 1.0);
  }

  ProjInv = inverse(ProjMat * ModelViewMat);
  vertexDistance = fog_distance(Position, FogShape);
}
