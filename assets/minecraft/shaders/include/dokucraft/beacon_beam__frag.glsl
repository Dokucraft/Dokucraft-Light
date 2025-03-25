#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <dokucraft:config.glsl>

#ifdef ENABLE_CUSTOM_SKY
	#moj_import <minecraft:utils.glsl>
#endif

uniform sampler2D Sampler0;

uniform mat4 ProjMat;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec4 vertexColor;
in vec2 texCoord0;

#ifdef ENABLE_CUSTOM_SKY
	in vec4 glpos;
#endif

out vec4 fragColor;

void main() {
	#ifdef ENABLE_CUSTOM_SKY
  	discardControlGLPos(gl_FragCoord.xy, glpos);
	#endif

	vec4 color = texture(Sampler0, texCoord0);
	color *= vertexColor * ColorModulator;
	float fragmentDistance = -ProjMat[3].z / ((gl_FragCoord.z) * -2.0 + 1.0 - ProjMat[2].z);
	fragColor = linear_fog(color, fragmentDistance, FogStart, FogEnd, FogColor);
}
