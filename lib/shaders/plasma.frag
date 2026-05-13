// ============================================================
// PLASMA SHADER — Animated plasma effect
// ============================================================
// Concepts:
//   - UV coordinates: how to convert pixels to the [0, 1] range
//   - Time (uTime): how to animate the shader
//   - sin/cos: how to create smooth waves
//   - mix(): how to blend colors
// ============================================================

#version 460 core

// This include gives us FlutterFragCoord() — the correct way
// to get the pixel coordinates in Flutter shaders.
#include <flutter/runtime_effect.glsl>

// ── Uniforms ─────────────────────────────────────────────────
// Uniforms are input data from Dart. The order is IMPORTANT and:
// they are set by index (0, 1, 2...) via FragmentShader.
//
// Index 0..1  — uSize   (vec2: widget width and height in pixels)
// Index 2     — uTime   (float: time in seconds, for animation)
// Index 3..6  — uColor1 (vec4: RGBA first color)
// Index 7..10 — uColor2 (vec4: RGBA second color)
// Index 11..14— uColor3 (vec4: RGBA third color)
// ─────────────────────────────────────────────────────────────
uniform vec2 uSize;    // widget size
uniform float uTime;   // time in seconds (elapsed.inMilliseconds / 1000.0)
uniform vec4 uColor1;  // e.g., blue  (0.1, 0.3, 0.9, 1.0)
uniform vec4 uColor2;  // e.g., purple (0.8, 0.1, 0.6, 1.0)
uniform vec4 uColor3;  // e.g., cyan   (0.0, 0.8, 0.7, 1.0)

// Mandatory output pixel color
out vec4 fragColor;

void main() {
    // ── Step 1: UV coordinates ─────────────────────────────────
    // FlutterFragCoord() gives us the current pixel position in px.
    // Divide by uSize to get normalized coordinates:
    //   uv.x = 0.0 (left edge) ... 1.0 (right edge)
    //   uv.y = 0.0 (bottom) ... 1.0 (top)
    vec2 uv = FlutterFragCoord().xy / uSize;

    // ── Step 2: Plasma waves ──────────────────────────────
    // Sum several sin waves in different directions.
    // Each wave: sin(coordinate * frequency + time * speed)
    // Result in the range [-1, 1].
    float v = 0.0;

    // Horizontal wave
    v += sin(uv.x * 8.0 + uTime * 1.0);

    // Vertical wave (slightly slower)
    v += sin(uv.y * 8.0 + uTime * 0.8);

    // Diagonal wave
    v += sin((uv.x + uv.y) * 6.0 + uTime * 1.3);

    // Radial wave from the center (length computes distance)
    v += sin(length(uv - 0.5) * 14.0 - uTime * 2.0);

    // Normalize from [-4, 4] to [0, 1]
    // (4 waves in [-1,1] = total [-4, 4])
    v = (v + 4.0) / 8.0;

    // ── Step 3: Mapping to colors ──────────────────────────────
    // Divide the range [0, 1] into two segments and interpolate smoothly:
    //   [0.0 .. 0.5] → color1 → color2
    //   [0.5 .. 1.0] → color2 → color3
    vec4 color;
    if (v < 0.5) {
        // mix(a, b, t): returns a*(1-t) + b*t
        // At v=0.0 → color1, at v=0.5 → color2
        color = mix(uColor1, uColor2, v * 2.0);
    } else {
        // At v=0.5 → color2, at v=1.0 → color3
        color = mix(uColor2, uColor3, (v - 0.5) * 2.0);
    }

    fragColor = color;
}
