// ============================================================
// glow_chart.frag — background for a chart with moving glow
// ============================================================
// Rendered UNDER the chart line. Creates a sense of "living energy":
//   • vertical gradient (dark at the top → bright at the bottom)
//   • moving light spot (sweep)
//   • grid for an "instrument" look
// ============================================================

#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2  uSize;
uniform float uTime;
uniform vec4  uBgTop;       // top color
uniform vec4  uBgBottom;    // bottom color (usually dark background)
uniform vec4  uAccent;      // accent color (glow, grid)
uniform float uGridDensity; // grid density (e.g., 8)

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord / uSize;

    // Base vertical gradient — brighter at the top (where the chart line is)
    vec3 col = mix(uBgBottom.rgb, uBgTop.rgb, smoothstep(0.0, 1.0, 1.0 - uv.y));

    // Sweep — moving light spot from left to right
    float sweepX = mod(uTime * 0.25, 1.4) - 0.2;
    float sweep = exp(-pow((uv.x - sweepX) * 4.0, 2.0));
    col += uAccent.rgb * sweep * 0.15;

    // Thin grid
    vec2 grid = abs(fract(uv * uGridDensity) - 0.5);
    float lineX = smoothstep(0.48, 0.5, grid.x);
    float lineY = smoothstep(0.48, 0.5, grid.y);
    float gridMask = max(lineX, lineY);
    col += uAccent.rgb * gridMask * 0.05;

    // Light vignette at the edges
    float vig = smoothstep(1.4, 0.5, distance(uv, vec2(0.5)));
    col *= vig;

    fragColor = vec4(col, 1.0);
}
