// ============================================================
// ENERGY SHADER — Radial rotating rays, power burst effect
// ============================================================
// Uniforms index map:
//   0..1  — uSize        (vec2)
//   2     — uTime        (float: seconds)
//   3     — uSpeed       (float: rotation speed, 1.0 = normal)
//   4     — uRayCount    (float: rays count, 8.0)
//   5..8  — uCoreColor   (vec4: inner core / highlight color)
//   9..12 — uRayColor    (vec4: ray outer color)
//   13    — uIntensity   (float: overall brightness 0.5..2.0)
//   14..17— uBgColor     (vec4: background color)
// ============================================================

#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uSpeed;
uniform float uRayCount;
uniform vec4 uCoreColor;
uniform vec4 uRayColor;
uniform float uIntensity;
uniform vec4 uBgColor;

out vec4 fragColor;

const float PI  = 3.14159265359;
const float TAU = 6.28318530718;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Aspect-ratio correction
    float aspect = uSize.x / uSize.y;
    vec2 centered = uv - 0.5;
    centered.x *= aspect;

    float dist  = length(centered);
    float angle = atan(centered.y, centered.x); // [-PI, PI]

    // ── Primary rotating rays ─────────────────────────────────
    // Map angle into [0, 1] per ray segment, with rotation over time.
    // mod(..., 1.0) wraps around continuously as the widget rotates.
    float a1 = mod((angle + uTime * uSpeed) / (TAU / uRayCount) + 0.5, 1.0);
    // Triangle wave: peaks at 0.5, valleys at 0.0 and 1.0
    float ray1 = pow(max(0.0, 1.0 - abs(a1 - 0.5) * 5.0), 2.5);

    // ── Counter-rotating secondary rays (half count, 40% brightness) ─
    float a2 = mod((angle - uTime * uSpeed * 0.6) / (TAU / (uRayCount * 0.5)) + 0.5, 1.0);
    float ray2 = pow(max(0.0, 1.0 - abs(a2 - 0.5) * 5.0), 3.0) * 0.4;

    float rays = (ray1 + ray2) * uIntensity;

    // ── Radial fade ───────────────────────────────────────────
    // exp(-dist * k): rays bright near center, fade outward
    // smoothstep: suppress rays right at the center (singularity)
    float radialFade = exp(-dist * 2.5);
    float coreHide   = smoothstep(0.0, 0.04, dist);
    float rayGlow    = rays * radialFade * coreHide;

    // ── Core pulse ────────────────────────────────────────────
    // Small pulsing orb at center — the "power source"
    float corePulse = exp(-dist * 16.0) * (0.7 + 0.3 * sin(uTime * 5.0));

    float total = clamp(rayGlow + corePulse * uIntensity, 0.0, 1.0);

    // ── Color: blend core → ray color by distance ─────────────
    vec4 energyColor = mix(uCoreColor, uRayColor, clamp(dist * 4.0, 0.0, 1.0));

    fragColor = mix(uBgColor, energyColor, total);
}
