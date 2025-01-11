#version 330

in vec4 vertexColor;
flat in int isHorizon;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
  // This doesn't work for the chunk grid for some reason:
  // discardControlGLPos(gl_FragCoord.xy, glpos);

  // This gets rid of the entire bottom row of pixels, which does work for the chunk grid
  // The sunrise/sunset hemisphere horizon is removed to fix blending issues with the sun
  if (gl_FragCoord.y < 1 || vertexColor.a == 0.0 || isHorizon == 1) {
    discard;
  }

  fragColor = vertexColor * ColorModulator;
}
