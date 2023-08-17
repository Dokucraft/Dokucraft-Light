#version 150

#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

out vec4 vertexColor;
out vec4 vertexPos;
out vec4 glpos;
out vec2 texCoord0;
out float vertexDistance;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexPos = vec4(0);
    if (textureSize(Sampler0, 0) == ivec2(128) && UV2 != ivec2(210, 240)) {
      vertexPos = vec4((ModelViewMat * vec4(Position, 1.0)).xyz, 1.0);
    }

    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;

    glpos = gl_Position;
}
