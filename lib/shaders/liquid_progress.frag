// ============================================================
// liquid_progress.frag — liquid progress bar
// ============================================================
// Renders a "liquid" fill with a wavy surface.
//
// Concepts:
//   • sin wave on the surface → organic liquid shape
//   • smoothstep() → anti-aliasing edges without if-branches
//   • exp(-x²) → Gaussian bell — foam / highlight
//   • Depth fade → internal gradient (surface brighter, bottom darker)
//
// Uniform index map:
//   0..1  — uSize         (vec2: logical widget size in pixels)
//   2     — uTime         (float: time in seconds)
//   3     — uProgress     (float: fill level 0.0 = empty, 1.0 = full)
//   4..7  — uFillColor    (vec4: RGBA liquid color)
//   8..11 — uBgColor      (vec4: RGBA background color)
//   12    — uWaveAmp      (float: wave amplitude, typically 0.015..0.04)
// ============================================================

#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2  uSize;
uniform float uTime;
uniform float uProgress;   // 0.0 = empty, 1.0 = full
uniform vec4  uFillColor;
uniform vec4  uBgColor;
uniform float uWaveAmp;    // wave amplitude in UV units

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    // Note: uv.y = 0 at top, 1 at bottom (Flutter screen coords)

    // ── Liquid surface: two sin waves overlaid ───────────────
    // Primary wave: slower, wider undulation
    float wave = sin(uv.x * 7.5 + uTime * 2.3) * uWaveAmp
               + sin(uv.x * 14.2 - uTime * 1.9) * (uWaveAmp * 0.45);

    // Surface Y in UV space: fill from bottom → surface at (1 - progress)
    // Modulated by wave for organic shape
    float surface = (1.0 - uProgress) + wave;

    // ── Anti-aliased edge ────────────────────────────────────
    // smoothstep over 2-pixel zone: no hard cuts, GPU-friendly
    float pixH  = 2.0 / uSize.y;
    float filled = smoothstep(surface - pixH, surface + pixH, uv.y);

    // ── Fresnel/foam line at the surface ─────────────────────
    // exp(-dist²) creates a bright narrow band exactly at the surface.
    // Gives the "refraction highlight" characteristic of water.
    float distPx = (uv.y - surface) * uSize.y; // distance to surface in px
    float foam   = exp(-distPx * distPx * 0.07) * step(0.0, uv.y - surface);

    // ── Depth gradient: surface is brightest, deeper = darker ─
    float liquidDepth = clamp((uv.y - surface) / max(uProgress, 0.01), 0.0, 1.0);
    float depthFade   = mix(1.0, 0.58, liquidDepth);

    // ── Compose ──────────────────────────────────────────────
    vec3 liquidRgb = uFillColor.rgb * depthFade
                   + foam * 0.30; // foam lightens the surface line

    vec3 col = mix(uBgColor.rgb, liquidRgb, filled);

    fragColor = vec4(col, 1.0);
}
