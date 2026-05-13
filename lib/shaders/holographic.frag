// ============================================================
// HOLOGRAPHIC SHADER — Holographic/Rainbow Highlight
// ============================================================
// Concepts:
//   - HSV → RGB conversion: how the HSV color model works
//   - dot product: projection to determine the lighting angle
//   - atan() / normals: simulating light reflection
//   - Layering: base + shimmer + specular highlight
// ============================================================

#version 460 core

#include <flutter/runtime_effect.glsl>

// ── Uniforms ─────────────────────────────────────────────────
// Index 0..1  — uSize        (vec2)
// Index 2     — uTime        (float: seconds)
// Index 3..4  — uLightDir    (vec2: light direction, normalized vector)
//                              Controlled via GestureDetector!
//                              (0.0, 0.0) = neutral, (1.0, 0.0) = light from the right
// Index 5     — uShimmer     (float: rainbow intensity 0..1)
// Index 6..9  — uBaseColor   (vec4: base color of the card)
// ─────────────────────────────────────────────────────────────
uniform vec2 uSize;
uniform float uTime;
uniform vec2 uLightDir;   // tilt of the "card" relative to the light
uniform float uShimmer;   // strength of the holographic effect
uniform vec4 uBaseColor;  // base color (e.g., silver: 0.75, 0.75, 0.8, 1.0)

out vec4 fragColor;

// ── HSV → RGB ─────────────────────────────────────────────────
// H (Hue)        = hue, 0..1 = 0°..360°
// S (Saturation) = saturation, 0..1
// V (Value)      = value, 0..1
//
// Classic formula using mod/clamp without branching.
vec3 hsv2rgb(float h, float s, float v) {
    // For each R, G, B, compute the position on the "color wheel"
    // using offsets 0, 2/3, 1/3 (120° between channels)
    vec3 k = vec3(1.0, 2.0 / 3.0, 1.0 / 3.0);
    vec3 p = abs(fract(vec3(h) + k) * 6.0 - 3.0);

    // mix(v, v*s_curve, s): from gray (s=0) to saturated (s=1)
    return v * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), s);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // ── Step 1: Normal of the "card" surface ────────────────
    // Imagine the card as a curved surface.
    // Center (0.5, 0.5) has normal = (0, 0, 1) — facing directly at us.
    // Edges are slightly tilted. We simulate this by offsetting from the center.
    vec2 centered = (uv - 0.5) * 2.0;  // [-1, 1]

    // ── Step 2: Calculate "reflection angle" ────────────────────
    // dot(a, b) = |a| * |b| * cos(angle_between)
    // Project uv onto the light vector — gives a scalar value
    // indicating "how much this pixel is 'lit'"
    float lightProj = dot(centered, normalize(uLightDir + vec2(0.001)));

    // Add a small ripple on the surface (microstructure simulation)
    // — this creates the "shimmering" holographic effect
    float microRipple = 0.0;
    microRipple += sin(uv.x * 20.0 + uv.y * 15.0 + uTime * 0.5) * 0.03;
    microRipple += sin(uv.x * 35.0 - uv.y * 28.0 - uTime * 0.3) * 0.02;

    // ── Step 3: Hue — rainbow hue ──────────────────────────
    // Combine light projection + ripple + slow time animation
    float hue = fract(lightProj * 0.5 + microRipple + uTime * 0.05);

    // Saturation depends on angle: the "straighter" the light, the less rainbow
    // abs(lightProj): 0 = center (minimum), 1 = edges (maximum rainbow)
    float saturation = clamp(abs(lightProj) * 1.5 + 0.3, 0.0, 1.0);

    vec3 rainbow = hsv2rgb(hue, saturation * uShimmer, 1.0);

    // ── Step 4: Specular highlight ──────────
    // pow(x, n): the larger n, the sharper and brighter the highlight
    float specular = pow(max(0.0, lightProj * 0.5 + 0.5), 8.0) * 0.6;

    // ── Step 5: Assemble final color ───────────────────────
    // Layering: base → rainbow → specular
    vec3 base = uBaseColor.rgb;

    // screen blend: makes the overlay brighter without overexposing
    vec3 color = 1.0 - (1.0 - base) * (1.0 - rainbow * uShimmer);

    // Add white specular highlight on top
    color += vec3(specular);

    fragColor = vec4(clamp(color, 0.0, 1.0), uBaseColor.a);
}
