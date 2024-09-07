#version 330

float check_alpha(float textureAlpha, float targetAlpha) {
	float targetLess = targetAlpha - 0.01;
	float targetMore = targetAlpha + 0.01;
	if (textureAlpha > targetLess && textureAlpha < targetMore) return 1.0;
	else return 0.0;
}

vec4 make_emissive(vec4 inputColor, vec4 lightColor, float inputAlpha) {
	if (check_alpha(inputAlpha, 250.0) == 1.0) return inputColor;
	else if (check_alpha(inputAlpha, 249.0) == 1.0) return inputColor;
	else return inputColor * lightColor;
}

float remap_alpha(float inputAlpha) {
	if (check_alpha(inputAlpha, 250.0) == 1.0) return 255.0;
	else if (check_alpha(inputAlpha, 249.0) == 1.0) return 190.0;
	else return inputAlpha;
}
