#version 150

in vec3 Position;
in vec2 UV0;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;

out vec2 texCoord0;
out vec4 vertexColor;
out vec4 Pos;
out vec3 direction;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    Pos = ModelViewMat * vec4(1);

    direction = IViewRotMat * Position;

    texCoord0 = UV0;
    vertexColor = Color;
}
