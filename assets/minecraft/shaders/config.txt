
// ============================================================================
//  Waving & swinging animations
// ============================================================================

// Remove this line to disable the waving animation for things like plants, leaves, and fire
#define ENABLE_WAVING

// Controls how much things like plants, leaves, and fire wave
#define WAVE_MULTIPLIER 1.0

// Remove this line to disable the swinging animation for hanging lanterns
#define ENABLE_LANTERN_SWING

// Controls how much hanging lanterns swing
#define LANTERN_SWING_MULTIPLIER 1.0



// ============================================================================
//  Grass
// ============================================================================

// This controls the type of grass to draw on the regular grass block (does not affect short/tall grass)
// This requires custom models and textures, just enabling an effect here will not do anything other than slow down rendering slightly
// Possible values:
//  0: Disable the extra processing to slightly speed up rendering
//  1: Enable the low-poly grass blades effect
//  2: Enable the dense grass blades effect (shell texturing)
#define GRASS_TYPE 0

// Controls the average width of the grass blades when using the low-poly grass blades effect
#define LOW_POLY_GRASS_WIDTH 0.0625

// Controls the average height of the grass blades when using the low-poly grass blades effect
#define LOW_POLY_GRASS_HEIGHT 0.325

// Controls the amount of grass blades per block when using the dense grass blades effect
// If it is a number, it will be squared. For example, 32 would yield 32^2 = 1024 blades per block
// Can be set to a 2D vector to control the X and Z axes separately, for example vec2(32, 16)
// The dense grass effect has a constant cost, meaning it does not get slower or faster to render depending on the number of blades to draw, it always performs the same. Doesn't matter if you draw 5 blades per block or a million per block
#define DENSE_GRASS_BLADES_PER_BLOCK 32

// Controls the coverage of the dense grass effect (0.0 to 1.0)
// At 0, there will be no grass blades, and at 1 the amount of grass blades will depend on the option above (DENSE_GRASS_BLADES_PER_BLOCK)
// Values between 0 and 1 will avoid drawing some of the blades, but not all. For example, at 0.5 only half of the grass blades will be drawn
// Values outside of this range will be clamped to the edges of the range (0 for values < 0, 1 for values > 1)
#define DENSE_GRASS_COVERAGE 1.0

// Controls the radius threshold for the grass blades
// If the radius is lower than the threshold, the grass blade will not be drawn on the current shell
// The radius of each blade decreases with the shell's height, so increasing this threshold gets rid of the top shells for most grass blades
// This option is mainly for getting rid of the tiny dots on the top few layers of some grass blades
#define DENSE_GRASS_RADIUS_THRESHOLD 0.2



// ============================================================================
//  Parallax subsurface
// ============================================================================

// Remove this line to disable the parallax subsurface effect (used on blue/packed ice, diamond blocks, diamond ore, etc.) - Also disables all other PSS settings
// Disabling it may improve performance on lower-end graphics cards
#define ENABLE_PARALLAX_SUBSURFACE

// Remove this line to disable the SSE shallow angle artifact fix
// The fix makes the surface more visible when viewed at very shallow angles, disabling it will make the subsurface always visible, which can lead to some strange effects in certain cases
// The performance impact of this should be tiny, you probably won't notice the difference
#define ENABLE_PSS_SHALLOW_ANGLE_FIX

// Remove this line to disable the chromatic aberration effect in the subsurface
// Disabling it may improve performance on lower-end graphics cards
#define ENABLE_PSS_CHROMATIC_ABERRATION



// ============================================================================
//  Translucent materials
// ============================================================================

// Remove this line to disable the Fresnel effect on translucent materials (water, stained/tinted glass, honey/slime block, etc.)
#define ENABLE_FRESNEL_EFFECT

// Removing this line will make the Fresnel effect perform better, but it will look slightly incorrect in some cases
#define ENABLE_FRAGMENT_FRESNEL

// Remove this line to disable the desaturation of the biome color on highlights on translucent materials (used to make the highlights on water look better)
#define ENABLE_DESATURATE_TRANSLUCENT_HIGHLIGHT_BIOME_COLOR

// Remove this line to disable the darkening effect on translucent materials when viewed from shallow angles.
// This effect compensates for the background behind the translucent material becoming harder to see because of the Fresnel effect.
// Without this enabled, translucent materials will look too bright when viewed from shallow angles.
#define ENABLE_FRESNEL_BRIGHTNESS_COMPENSATION



// ============================================================================
//  Overworld sky
// ============================================================================

// Remove the two slashes at the start of this line to disable the regular sun drawn using core shaders.
// Removing the regular sun means the sun can be drawn in the post shader instead, which allows it to use various extra effects.
// To draw the sun using post shaders, enable the option for it in program/skybox.fsh.
// #define DISABLE_CORE_SUN

// Remove the two slashes at the start of this line to allow the post shaders to check what the current moon phase is.
// Enabling this will completely remove the regular moon. To get the moon back, enable it in the settings in the program/skybox.fsh shader.
// Incompatible with Optifine's Custom Sky feature.
// #define ENABLE_POST_MOON_PHASES



// ============================================================================
//  Better lava
// ============================================================================

// Remove the two slashes at the start of this line to enable better lava.
// Better lava also requires the lava_still_alt.png texture to be renamed to lava_still.png
// This effect randomizes the texture on each block of lava and varies the glow of it over time and position
// #define ENABLE_BETTER_LAVA

// Only change this value if you add or remove lava texture variants
#define LAVA_VARIANT_COUNT 5



// ============================================================================
//  Mob effects
// ============================================================================

// Uncomment this line to enable support for all custom mob effect visuals.
// #define ENABLE_MOB_EFFECTS

// Uncomment any of the lines below to enable specific custom mob effect visuals. Requires ENABLE_MOB_EFFECTS.
// #define ENABLE_DARKNESS_EFFECT
// #define ENABLE_SPEED_EFFECT
// #define ENABLE_WITHER_EFFECT
