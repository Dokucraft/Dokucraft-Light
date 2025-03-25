#version 330

#moj_import <dokucraft:flavor.glsl>

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;

bool approxEqualLow(float a, float b) {
  return (a < b+0.001 && a > b-0.001);
}

bool approxEqual(float a, float b) {
  return (a < b+0.00001 && a > b-0.00001);
}

bool approxEqualV3(vec3 a, vec3 b) {
  return (lessThan(a, b+0.0001)==bvec3(true) && lessThan(b-0.0001,a)==bvec3(true));
}

void main() {
  vertexColor = Color;

  vec3 offset = vec3(0.0);
  vec3 posWithoutOffset = (ProjMat * vec4(Position, 1.0)).xyz;

  //is on a screen corner?
  if(approxEqualLow(min(abs(posWithoutOffset.x),1.0), 1.0) && approxEqualLow(min(abs(posWithoutOffset.y),1.0), 1.0)) {
    //is first? & on z0
    if(gl_VertexID > -1 && gl_VertexID < 4 && Position.z == 0.0) {
      //is a color that the bg could be? //dark
      if(Color.r < 0.001 && Color.g < 0.001 && Color.b < 0.001) {
        vertexColor.rgb = LOADING_BG_DARK_COLOR;
      }

      //is a color that the bg could be? //red
      else if(approxEqualV3(Color.rgb, vec3(0.93725,0.19608,0.23922))) {
        vertexColor.rgb = LOADING_BG_COLOR;
      }
    }
  }

  gl_Position = ProjMat * ModelViewMat * vec4(Position + offset, 1.0);
}
