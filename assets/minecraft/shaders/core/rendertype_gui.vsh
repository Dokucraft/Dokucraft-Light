#version 150

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out vec2 uv;
flat out int customType;

bool approxEqual(float a, float b) {
  return (a < b+0.00001 && a > b-0.00001);
}

void main() {
  customType = 0;
  vertexColor = Color;

  // Tooltip outline
  if(approxEqual(Color.a, 0.31373)) {
    int pid = gl_VertexID / 4;
    int vid = gl_VertexID % 4;
    customType = 1;
    /*
      pid = 5: Left
      pid = 6: Right
      pid = 7: Top
      pid = 8: Bottom
    */
    uv.x = int(
      (pid == 5 && (vid == 0 || vid == 3)) ||
      (pid == 6 && (vid == 1 || vid == 2)) ||
      (pid == 7 && (vid == 2 || vid == 3)) ||
      (pid == 8 && (vid == 0 || vid == 1))
    );
  } else if ( // Tooltip background
    approxEqual(Color.a, 0.94118) &&
    approxEqual(Color.r, 0.06275) &&
    approxEqual(Color.b, 0.06275)
  ) {
    customType = 2;
  }

  gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
}
