#version 150

in vec4 vertexColor;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
  // This doesn't work for the chunk grid for some reason:
  // discardControlGLPos(gl_FragCoord.xy, glpos);

  // This gets rid of the entire bottom row of pixels, which does work for the chunk grid
  if (gl_FragCoord.y < 1) {
    discard;
  }

  vec4 color = vertexColor;
  if (color.a == 0.0 || (color.a < 0.9 && color.rgb != vec3(1,0,0))) {
    discard;
  }
  fragColor = color * ColorModulator;
}
