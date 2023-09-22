#version 150

flat in vec4 vertexColor;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
  // This doesn't work for the chunk grid for some reason:
  // discardControlGLPos(gl_FragCoord.xy, glpos);

  // This gets rid of the entire bottom row of pixels, which does work for the chunk grid
  if (gl_FragCoord.y < 1 || vertexColor.a == 0.0) {
    discard;
  }

  fragColor = vertexColor * ColorModulator;
}
