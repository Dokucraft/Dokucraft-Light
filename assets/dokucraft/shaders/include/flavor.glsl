#ifndef FLAVOR
#define FLAVOR

// Color of the outline on items when hovering over them in the GUI
#define HOVER_OUTLINE_COLOR vec4(0.988, 0.988, 0.988, 1.0)

// Loading screen background color
#define LOADING_BG_DARK_COLOR vec3(0.161, 0.122, 0.094)
#define LOADING_BG_COLOR vec3(0.161, 0.122, 0.094)

// Fix for the gradients on the top/bottom of buttons
#define ENABLE_BUTTON_GRADIENTS
#define BUTTON_GRADIENT_COLOR_A vec3(0.996, 0.996, 0.992)
#define BUTTON_GRADIENT_COLOR_B vec3(0.65, 0.658, 0.619)

// Grass color multiplier for shader grass effects
#define GRASS_COLOR_MULTIPLIER 1

// Procedural water surface colors
#define PROCEDURAL_WATER_COLOR_1 vec3(0.224, 0.537, 0.835)
#define PROCEDURAL_WATER_COLOR_2 vec3(0.479, 0.813, 0.984)
#define PROCEDURAL_WATER_COLOR_3 vec3(0.647, 0.961, 0.996)
#define PROCEDURAL_WATER_COLOR_4 vec3(0.882, 0.996, 0.996)

// Water tint correction weights
#define WATER_TINT_RED   vec3( 1.0,   0.4,   0.6)
#define WATER_TINT_GREEN vec3( 0.0,   1.0,   0.4)
#define WATER_TINT_BLUE  vec3(-1.0,   1.0,   0.7)

// Underwater fog correction weights
#define UNDERWATER_FOG_RED   vec3( 1.0,   0.0,   0.0)
#define UNDERWATER_FOG_GREEN vec3( 0.0,   1.0,   0.2)
#define UNDERWATER_FOG_BLUE  vec3( 0.0,   0.0,   0.2)

// Colors used in the sketch menu background effect.
#define SKETCH_PAPER_COLOR vec3(0.909, 0.878, 0.819)
#define SKETCH_INK_COLOR vec3(0.231, 0.145, 0)


#endif
