#ifndef CONFIG
#define CONFIG


// ============================================================================
//  Menu background
// ============================================================================

// Controls the type of effect to apply to the menu background.
// 0: Gaussian blur
// 1: Gaussian blur + darken and desaturate
// 2: Sketch filter
#define MENU_BACKGROUND 1

// Extra options for menu background effect 1
#define MENU_BACKGROUND_SATURATION 0.5
#define MENU_BACKGROUND_BRIGHTNESS 0.8

// Remove or comment out this line to disable the paper texture effect.
#define SKETCH_PAPER_TEXTURE

// Remove or comment out this line to disable the stains.
#define SKETCH_STAINS

// Uncomment this line to enable a grid of dots.
// #define SKETCH_GRID_DOTS

// Uncomment this line to enable a grid of lines.
// #define SKETCH_GRID_LINES



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
//  3: Same as 2, but each blade of grass is placed randomly instead of being fixed to the pixel grid (worse for performance, but looks better)
#define GRASS_TYPE 0

// Controls the average width of the grass blades when using the low-poly grass blades effect
#define LOW_POLY_GRASS_WIDTH 0.0625

// Controls the average height of the grass blades when using the low-poly grass blades effect
#define LOW_POLY_GRASS_HEIGHT 0.325

// Controls the amount of grass blades per block when using the dense grass blades effect
// If it is a number, it will be squared. For example, 32 would yield 32^2 = 1024 blades per block
// Can be set to a 2D vector to control the X and Z axes separately, for example vec2(32, 16)
// The dense grass effect has a constant cost, meaning it does not get slower or faster to render depending on the number of blades to draw, it always performs the same. Doesn't matter if you draw 5 blades per block or a million per block
// When using grass type 3, this is more like an average than a precise count.
#define DENSE_GRASS_BLADES_PER_BLOCK 32

// Controls the coverage of the dense grass effect (0.0 to 1.0)
// At 0, there will be no grass blades, and at 1 the amount of grass blades will depend on the option above (DENSE_GRASS_BLADES_PER_BLOCK)
// Values between 0 and 1 will avoid drawing some of the blades, but not all. For example, at 0.5 only half of the grass blades will be drawn
// Values outside of this range will be clamped to the edges of the range (0 for values < 0, 1 for values > 1)
// Note: This has no effect on grass type 3.
#define DENSE_GRASS_COVERAGE 1.0

// Controls the radius threshold for the grass blades
// If the radius is lower than the threshold, the grass blade will not be drawn on the current shell
// The radius of each blade decreases with the shell's height, so increasing this threshold gets rid of the top shells for most grass blades
// This option is mainly for getting rid of the tiny dots on the top few layers of some grass blades
// Note: This has no effect on grass type 3.
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
//  Water and other translucent materials
// ============================================================================

// Remove this line to disable the Fresnel effect on translucent materials (water, stained/tinted glass, honey/slime block, etc.)
#define ENABLE_FRESNEL_EFFECT

// Removing this line will make the Fresnel effect perform better, but it will look slightly incorrect in some cases
#define ENABLE_FRAGMENT_FRESNEL

// Remove this line to disable the darkening effect on translucent materials when viewed from shallow angles.
// This effect compensates for the background behind the translucent material becoming harder to see because of the Fresnel effect.
// Without this enabled, translucent materials will look too bright when viewed from shallow angles.
#define ENABLE_FRESNEL_BRIGHTNESS_COMPENSATION

// Remove this line to disable the desaturation of the biome color on highlights on translucent materials (used to make the highlights on water look better)
#define ENABLE_DESATURATE_WATER_HIGHLIGHT

// Remove this line to disable the water tint correction.
// The tint correction adjusts the water tint to make it more similar to how the water used to look like before the tint was added.
#define ENABLE_WATER_TINT_CORRECTION

// Remove this line to disable the underwater fog color correction.
// The fog color correction adjusts the underwater fog color in most biomes to not be the default neon blue.
#define ENABLE_UNDERWATER_FOG_CORRECTION

// Uncomment this line to enable the procedural water surface texture.
// This requires a specific texture in place of the still water texture.
// #define ENABLE_PROCEDURAL_WATER_SURFACE

// Remove this line to remove the reduction of highlights on the procedural water surface texture when it is in less lit areas.
// Requires ENABLE_PROCEDURAL_WATER_SURFACE
#define ENABLE_PWS_REDUCE_SHADOW_HIGHLIGHTS



// ============================================================================
//  Overworld sky
// ============================================================================

// Controls how the atmosphere is rendered.
// 0: Uses a mostly static skybox during the day that may include things like clouds, depending on the texture used.
// 1: The clouds use a texture for their shapes and will be dynamically lit by the sun and moon. The color of the sky is based on a separate texture.
#define ATMOSPHERE 0

// Controls what night sky to render.
// 0: Use a skybox texture.
// 1: Generate a night sky procedurally without any textures.
// 2: Same as 1, but with slightly less color.
#define NIGHT_SKY 0

// Uncomment this line to enable a light layer of fog that is dynamically lit by the moon at night.
// #define ENABLE_NIGHT_FOG

// Remove this line to disable the north star
// No noticeable impact on performance
// Requires NIGHT_SKY being set to 1 or 2
#define ENABLE_NORTH_STAR

// Uncomment this line to enable auroras at night
// Major impact on performance on most graphics cards
// #define ENABLE_AURORAS

// Controls the colors of the auroras
// Requires ENABLE_AURORAS
#define AURORA_COLOR vec3(0.465, 2, 0.833)

// Remove the two slashes at the start of this line to draw the sun as a part of the sky.
// This disables the regular sun, which means the sun will not be visible without Fabulous graphics.
// This does not currently use a texture. The shape of the sun is calculated based on the time of day.
// #define ENABLE_POST_SUN

// Controls the speed of the sun's animation.
// Requires ENABLE_POST_SUN
#define SUN_ANIM_SPEED 0.5

// Remove the two slashes at the start of this line to draw the moon as a part of the sky.
// This disables the regular moon, which means the moon will not be visible without Fabulous graphics.
// This requires MoonSampler to be set up properly in shaders/dokucraft/sky_post.json and in post_effect/transparency.json
// #define ENABLE_POST_MOON

// Use this to change the size of the moon.
// Requires ENABLE_POST_MOON
#define MOON_SCALE 0.3

// Remove the two slashes at the start of this line to disable rendering of the default stars.
// The post-processing night skies draw their own stars, so the core stars should be disabled for those.
// #define DISABLE_CORE_STARS



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



#endif
