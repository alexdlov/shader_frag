// ============================================================
// AURORA SHADER — Northern Lights
// ============================================================
// Concepts:
//   - Value noise: pseudo-random noise via sin+fract (no textures!)
//   - Smoothstep interpolation for smoothing noise
//   - exp(): exponential decay for "light bands"
//   - Layering: multiple independent bands
// ============================================================

#version 460 core

#include <flutter/runtime_effect.glsl>

// ── Uniforms ─────────────────────────────────────────────────
// Index 0..1  — uSize   (vec2)
// Index 2     — uTime   (float: time in seconds)
// Index 3..6  — uSky    (vec4: sky/background color, dark blue)
// Index 7..10 — uColor1 (vec4: first aurora color, green/cyan)
// Index 11..14— uColor2 (vec4: second aurora color, purple/violet)
// Index 15    — uIntensity (float: overall brightness, 0.5..2.0)
// ─────────────────────────────────────────────────────────────
uniform vec2 uSize;
uniform float uTime;
uniform vec4 uSky;        // dark sky: (0.02, 0.02, 0.08, 1.0)
uniform vec4 uColor1;     // green: (0.1, 0.9, 0.5, 1.0)
uniform vec4 uColor2;     // purple: (0.6, 0.1, 0.9, 1.0)
uniform float uIntensity; // brightness: 1.0

out vec4 fragColor;

// ── Helper functions ───────────────────────────────────

// hash() — pseudo-random number from a 2D point.
// fract(sin(dot(...)) * large_number) — classic GLSL trick.
// dot(p, vec2(127.1, 311.7)) mixes x and y into one number,
// sin() creates chaos, fract() takes the fractional part → [0, 1).
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// valueNoise() — smooth noise (Value Noise).
// Divide space into cells, each corner has a random value.
// Interpolate smoothly between corners using smoothstep.
float valueNoise(vec2 p) {
    vec2 i = floor(p);   // cell index
    vec2 f = fract(p);   // position within cell [0,1]

    // Cubic smoothing (instead of linear interpolation)
    // f*f*(3-2f) = smoothstep curve, removes "steps"
    f = f * f * (3.0 - 2.0 * f);

    // Values at the 4 corners of the cell
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // Bilinear interpolation with smooth transition
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Flip Y: in shaders y=0 is usually at the bottom, but we prefer top
    uv.y = 1.0 - uv.y;

    // ── Step 1: Horizontal distortion ──────────────────────
    // Noise "pushes" the vertical position of the band left-right.
    // This creates organic curves, not straight bands.
    float warp = valueNoise(vec2(uv.x * 2.5, uTime * 0.15)) * 0.25;

    // Use the distorted y-coordinate for all bands
    float y = uv.y + warp;

    // ── Step 2: Multiple aurora bands ────────────────────────
    // exp(-abs(band) * sharpness) — Gaussian curve.
    // Maximum (1.0) at band=0, quickly falls off to the sides.
    // Multiply by noise → band flickers and sways.

    float aurora = 0.0;

    // Band 1: y ≈ 0.35, bright, slow
    float b1 = exp(-abs(y - 0.35) * 9.0);
    b1 *= valueNoise(vec2(uv.x * 3.0 + uTime * 0.25, 0.0));

    // Band 2: y ≈ 0.50, wider, moves in opposite direction
    float b2 = exp(-abs(y - 0.50) * 7.0);
    b2 *= valueNoise(vec2(uv.x * 2.0 - uTime * 0.20, 1.5));

    // Band 3: y ≈ 0.65, narrow, fast
    float b3 = exp(-abs(y - 0.65) * 12.0);
    b3 *= valueNoise(vec2(uv.x * 4.0 + uTime * 0.35, 3.0));

    aurora = b1 + b2 + b3;
    aurora = clamp(aurora * uIntensity, 0.0, 1.0);

    // ── Step 3: Aurora color ───────────────────────────────────
    // Color changes horizontally over time — bands "breathe" color
    float colorShift = valueNoise(vec2(uv.x * 1.5 + uTime * 0.08, 5.0));
    vec4 auroraColor = mix(uColor1, uColor2, colorShift);

    // ── Step 4: Background + vertical sky gradient ──────────────
    // Sky is slightly darker at the top (like a real night sky)
    vec4 sky = mix(uSky, uSky * 0.4, uv.y);

    fragColor = mix(sky, auroraColor, aurora);
}
