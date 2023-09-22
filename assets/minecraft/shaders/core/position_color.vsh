#version 150

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

// Having this be flat makes the red horizon glow during sunrise/sunset invisible
// This is important because having it visible causes issues with the partial transparency in the sun texture
flat out vec4 vertexColor;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexColor = Color;
}
