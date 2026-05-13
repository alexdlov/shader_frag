// ============================================================
// frosted_glass.frag — glass with blur + grain
// ============================================================
// Concepts:
//
//   • sampler2D — texture passed from Dart via
//     FragmentShader.setImageSampler(index, ui.Image).
//     This is the only uniform type NOT passed via setFloat().
//     In Dart code: shader.setImageSampler(0, capturedImage)
//
//   • texture(sampler, uv) — sampling a texture by UV [0,1]:
//     returns the interpolated pixel color at the uv point.
//
//   • Multi-tap blur — take N samples with offsets and average →
//     simulates blur without a separate render pass.
//     9 samples (center ×4 + cardinal ×2 + diagonal ×1)
//     provide a good approximation of Gaussian blur.
//
//   • Procedural grain — fract(sin(dot(uv, seed)) * big)
//     generates pseudo-random grain without additional textures.
//     Changes over uTime → grain is "alive".
//
// Uniform index map (floats):
//   0..1 — uSize        (vec2: logical widget size)
//   2    — uTime        (float: seconds, for grain animation)
//   3    — uBlurRadius  (float: blur radius in pixels)
//   4    — uNoise       (float: grain intensity, 0.0..0.10)
//   5..8 — uTint        (vec4: panel tint color/opacity)
// Samplers:
//   0    — uScene       (sampler2D: captured widget background)
// ============================================================

#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2      uSize;
uniform float     uTime;
uniform float     uBlurRadius;
uniform float     uNoise;
uniform vec4      uTint;
uniform sampler2D uScene;   // captured background texture

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Offset in UV space corresponding to uBlurRadius pixels
    vec2 d = uBlurRadius / uSize;

    // ── 9-tap weighted blur (approximation of Gaussian) ─────────
    // Weights: center=4, cardinal=2, diagonal=1. Sum = 16.
    // clamp(uv + offset, 0, 1) — prevents sampling outside the edge
    vec3 col = vec3(0.0);

    col += texture(uScene, uv).rgb                                         * 4.0;
    col += texture(uScene, clamp(uv + vec2( d.x,  0.0 ), 0.0, 1.0)).rgb  * 2.0;
    col += texture(uScene, clamp(uv + vec2(-d.x,  0.0 ), 0.0, 1.0)).rgb  * 2.0;
    col += texture(uScene, clamp(uv + vec2( 0.0,  d.y ), 0.0, 1.0)).rgb  * 2.0;
    col += texture(uScene, clamp(uv + vec2( 0.0, -d.y ), 0.0, 1.0)).rgb  * 2.0;
    col += texture(uScene, clamp(uv + vec2( d.x,  d.y) * 0.707, 0.0, 1.0)).rgb;
    col += texture(uScene, clamp(uv + vec2(-d.x,  d.y) * 0.707, 0.0, 1.0)).rgb;
    col += texture(uScene, clamp(uv + vec2( d.x, -d.y) * 0.707, 0.0, 1.0)).rgb;
    col += texture(uScene, clamp(uv + vec2(-d.x, -d.y) * 0.707, 0.0, 1.0)).rgb;

    col /= 16.0;

    // ── Tint: mix panel tint color with blurred background ────────
    col = mix(col, uTint.rgb, uTint.a * 0.38);

    // ── Brightness lift: frosted glass slightly brighter than background ─────
    col = mix(col, vec3(1.0), 0.05);

    // ── Procedural grain noise (animated) ───────────────
    // fract(sin(dot(...)) * bigNum) → pseudo-random value [0,1)
    // Multiply uv by uSize to get a unique value per pixel
    // uTime * 137.5 → grain changes every frame (alive texture)
    float grain = fract(
        sin(dot(uv * uSize + uTime * 137.5, vec2(127.1, 311.7))) * 43758.5453
    );
    grain = (grain - 0.5) * uNoise;   // center: [-N/2, +N/2]

    col = clamp(col + grain, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
