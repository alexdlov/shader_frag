// ============================================================
// hourglass.frag — animated sand timer with texture sampler
// ============================================================
// Visual features:
//   • Real sand texture passed as sampler2D from Dart
//   • Rounded sand pile at bottom (angle-of-repose feel)
//   • Funnel depression on top surface as sand drains
//   • Teardrop sand grain particles + base stream
//   • Glass rim highlights (inner bright + outer soft)
//   • Directional diffuse on glass wall
//   • Chamber ambient glow + outer halo
//   • Depth-based shading inside sand body
//
// Uniform index map: (unchanged — no Dart changes needed)
//   0..1  — uSize       (vec2: widget size in pixels)
//   2     — uTime       (float: elapsed seconds)
//   3     — uProgress   (float: 0.0 = top full, 1.0 = top empty)
//   4     — uRunning    (float: 1.0 = flowing, 0.0 = paused)
//   5..8  — uSandColor  (vec4 RGBA)
//   9..12 — uGlassColor (vec4 RGBA)
//   13..16— uBgColor    (vec4 RGBA)
// Samplers:
//   0     — uSandTexture (sampler2D: generated sand PNG)
//   1     — uGlassFrameTexture (sampler2D: pre-rendered glass frame)
// ============================================================

#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2  uSize;
uniform float uTime;
uniform float uProgress;
uniform float uRunning;
uniform vec4  uSandColor;
uniform vec4  uGlassColor;
uniform vec4  uBgColor;
uniform sampler2D uSandTexture;
uniform sampler2D uGlassFrameTexture;

out vec4 fragColor;

// ── Noise ────────────────────────────────────────────────────
float hash21(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p.yx + 19.19);
    return fract(p.x * p.y);
}

float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}

// ── Hourglass inner half-width at UV y ───────────────────────
// Quartic: smooth neck (zero derivative), wider chambers ~74% of widget width
float innerHalfW(float y, float aspect) {
    float t = clamp(abs(y - 0.5) * 2.0, 0.0, 1.0);
    float s = t * t * t * t;
    return min((0.016 + 0.320 * s) / aspect, 0.370);
}

vec3 sampleSand(vec2 uv, float depth, float sparkle) {
    vec3 tex = texture(uSandTexture, fract(uv)).rgb;
    vec3 warm = mix(tex, uSandColor.rgb, 0.18);
    warm *= mix(1.10, 0.58, pow(depth, 0.72));
    warm += vec3(1.0, 0.82, 0.42) * sparkle;
    return warm;
}

void main() {
    vec2  fragCoord = FlutterFragCoord().xy;
    vec2  uv        = fragCoord / uSize;

    float aspect = uSize.x / uSize.y;
    float pW     = 1.5 / uSize.x;
    float pH     = 1.5 / uSize.y;
    float cx     = uv.x - 0.5;   // signed distance from center
    float dx     = abs(cx);       // unsigned distance from center
    float topY   = 0.075;
    float botY   = 0.925;
    float bodyY  = smoothstep(topY - pH * 3.0, topY + pH * 3.0, uv.y)
                 * smoothstep(botY + pH * 3.0, botY - pH * 3.0, uv.y);

    // ── Glass walls ──────────────────────────────────────────
    float innerH = innerHalfW(uv.y, aspect);
    float wallW  = 0.013 / aspect;
    float outerH = innerH + wallW;

    float innerMask = smoothstep(innerH + pW, innerH - pW, dx) * bodyY;
    float outerMask = smoothstep(outerH + pW, outerH - pW, dx) * bodyY;
    float wallMask  = outerMask - innerMask;

    // End caps
    float capW = min(innerHalfW(0.0, aspect) + wallW * 1.8, 0.395);
    float capH = 0.014;
    float capT = smoothstep(capH + pH, capH - pH, abs(uv.y - topY))
               * smoothstep(capW + pW, capW - pW, dx);
    float capB = smoothstep(capH + pH, capH - pH, abs(uv.y - botY))
               * smoothstep(capW + pW, capW - pW, dx);
    float capMask = clamp(capT + capB, 0.0, 1.0);

    float neckW = innerHalfW(0.5, aspect); // half-width at neck

    // ── Sand surfaces ─────────────────────────────────────────
    // Top: surface descends from topY to the neck.
    float wAmp   = 0.0055 * uRunning;
    float wave   = sin(cx * uSize.x * 0.14 + uTime * 2.3) * wAmp
                 + sin(cx * uSize.x * 0.07 - uTime * 1.6) * wAmp * 0.42;

    // Funnel depression around center: deepens at mid-progress
    float fR     = neckW * 3.5;
    float funnel = uProgress * (1.0 - uProgress) * 0.022
                 * exp(-(cx * cx) / (fR * fR));

    float topSurfBase = mix(topY + 0.030, 0.475, uProgress);
    float topSurf     = topSurfBase + funnel + wave;

    // Bottom: rounded mound + shallow settled base.
    float floorY      = botY - 0.014;
    float chamberW    = innerHalfW(botY - 0.030, aspect);
    float pileH       = uProgress * 0.315;
    float peakY       = floorY - pileH;
    float pileRadius  = mix(neckW * 1.55, chamberW * 0.84, smoothstep(0.06, 0.70, uProgress));
    float moundT      = smoothstep(0.0, pileRadius, dx);
    float moundSurf   = mix(peakY, floorY, moundT);
    float baseSurf    = floorY - uProgress * 0.020;
    float botSurf     = min(moundSurf, baseSurf);

    // ── Sand masks ───────────────────────────────────────────
    float topSandM = smoothstep(topSurf - pH, topSurf + pH, uv.y)
                   * step(uv.y, 0.494)
                   * step(topY + 0.010, uv.y);
    float botSandM = smoothstep(botSurf - pH * 2.5, botSurf + pH * 0.5, uv.y)
                   * step(0.506, uv.y)
                   * step(uv.y, botY);
    float sandMask = clamp(topSandM + botSandM, 0.0, 1.0) * innerMask;

    // ── Sand texture ──────────────────────────────────────────
    float depth;
    if (uv.y < 0.50) {
        depth = clamp((uv.y - topSurfBase) / max(0.50 - topSurfBase, 0.001), 0.0, 1.0);
    } else {
        depth = clamp((uv.y - botSurf) / max(1.0 - botSurf, 0.001), 0.0, 1.0);
    }

    vec2 bodyTexUv = vec2(
        uv.x * 2.7 + 0.17 * sin(uv.y * 6.0),
        uv.y * 2.2 + uProgress * 0.22
    );
    float sparkleSeed = hash21(floor(fragCoord / 2.5));
    float sparkle = smoothstep(0.965, 1.0, sparkleSeed) * 0.12;

    // Glint / foam on top sand surface
    float foamDist = abs(uv.y - topSurf) * uSize.y;
    float foam     = exp(-foamDist * foamDist * 0.11)
                   * step(topSurf - 0.006, uv.y)
                   * step(uv.y, 0.498)
                   * innerMask
                   * (0.3 + 0.7 * uRunning);

    // Rim light on bottom cone edge
    float coneDist = abs(uv.y - botSurf) * uSize.y;
    float coneRim  = exp(-coneDist * coneDist * 0.12)
                   * step(0.493, uv.y) * innerMask * 0.60;

    vec3 sandRgb = sampleSand(bodyTexUv, depth, sparkle)
                 + foam    * uSandColor.rgb * 0.22
                 + coneRim * uSandColor.rgb * 0.14;

    // ── Falling grain stream ──────────────────────────────────
    float streamMask = 0.0;
    if (uRunning > 0.5 && uProgress < 0.997) {
        float streamW  = neckW * 0.38;
        float streamBt = botSurf - 0.012;
        float inStreamY = step(0.499, uv.y) * step(uv.y, streamBt);

        // Thin base column
        float base = smoothstep(streamW + pW, streamW - pW, dx) * 0.16;

        // Animated grain particles — row A
        float speed  = 9.5;
        float cellSz = 6.0;
        float yFall  = uv.y * uSize.y / cellSz - uTime * speed;
        float cellId = floor(yFall);
        float fracY  = fract(yFall);

        float rXa  = (hash11(cellId * 1.37)       - 0.5) * streamW * 1.15;
        float rSza = hash11(cellId * 2.71 + 0.5)  * 0.45 + 0.55;
        float rBra = hash11(cellId * 3.14 + 1.0)  * 0.40 + 0.60;
        float gDxa = abs(cx - rXa);
        float gRa  = (0.0052 / aspect) * rSza;
        float gDya = (fracY - 0.28) * 1.5;
        float distA = sqrt(gDxa * gDxa + gDya * gDya * 0.5);
        float grainA = smoothstep(gRa, gRa * 0.1, distA) * rBra;

        // Row B (half-cell offset for denser fill)
        float fracYb  = fract(yFall + 0.5);
        float cellIdb = floor(yFall + 0.5);
        float rXb  = (hash11(cellIdb * 1.97 + 5.0) - 0.5) * streamW * 0.95;
        float rSzb = hash11(cellIdb * 4.11 + 2.5) * 0.35 + 0.45;
        float rBrb = hash11(cellIdb * 5.77 + 3.7) * 0.40 + 0.50;
        float gDxb = abs(cx - rXb);
        float gRb  = (0.0044 / aspect) * rSzb;
        float gDyb = (fracYb - 0.28) * 1.5;
        float distB = sqrt(gDxb * gDxb + gDyb * gDyb * 0.5);
        float grainB = smoothstep(gRb, gRb * 0.1, distB) * rBrb;

        streamMask = clamp(base + grainA + grainB, 0.0, 1.0) * inStreamY;
    }

    // ── Glass wall rendering ──────────────────────────────────
    float wallFrac = clamp((dx - innerH) / max(wallW, 0.001), 0.0, 1.0);

    // Inner rim: bright highlight at inner glass edge
    float innerRim = exp(-wallFrac * wallFrac * 12.0) * 0.90;
    // Outer rim: soft ambient at outer edge
    float outerRim = exp(-(1.0 - wallFrac) * (1.0 - wallFrac) * 18.0) * 0.28;

    // Directional diffuse (light from top-left)
    float diffuse = clamp(-cx * 2.4 + (0.42 - uv.y) * 1.0, 0.0, 1.0) * 0.42 + 0.58;

    vec3 glassRgb = uGlassColor.rgb * diffuse
                  + vec3(0.85, 0.95, 1.0) * (innerRim * 0.70 + outerRim * 0.25);

    // ── Chamber ambient ───────────────────────────────────────
    vec3 chamberCol = uBgColor.rgb * 0.76 + uGlassColor.rgb * 0.06;

    // ── Outer halo around the glass ───────────────────────────
    float haloD = max(0.0, dx - outerH);
    float halo  = exp(-haloD * uSize.x * 10.0)
                * (1.0 - outerMask)
                * step(capH * 1.5, uv.y)
                * step(uv.y, 1.0 - capH * 1.5)
                * 0.20;

    // ── Compose ───────────────────────────────────────────────
    vec3 col = uBgColor.rgb;

    col += uGlassColor.rgb * halo;

    float chamberMask = innerMask * (1.0 - sandMask);
    col = mix(col, chamberCol, chamberMask * 0.26);

    float sideStreak = exp(-pow((dx - innerH * 0.74) / max(0.010 / aspect, 0.001), 2.0))
                     * chamberMask * 0.18;
    col += uGlassColor.rgb * sideStreak;

    col = mix(col, sandRgb, sandMask);

    vec2 streamTexUv = vec2(0.50 + cx / max(neckW, 0.001) * 0.10, uv.y * 5.0 - uTime * 2.8);
    vec3 streamRgb = sampleSand(streamTexUv, 0.0, 0.10);
    col = mix(col, streamRgb, streamMask * (1.0 - sandMask) * innerMask);

    col = mix(col, glassRgb, wallMask * uGlassColor.a * 0.40);
    col = mix(col, uGlassColor.rgb * diffuse + vec3(0.9, 0.95, 1.0) * 0.20,
              capMask * uGlassColor.a * 0.40);

    // Main frame material comes from pre-rendered glass texture.
    // Mask by procedural shape so texture follows updated geometry.
    vec4 frameTex  = texture(uGlassFrameTexture, uv);
    float frameShape = clamp(wallMask + capMask, 0.0, 1.0);
    float frameAlpha = min(frameTex.a, frameShape);
    vec3 frameRgb  = mix(frameTex.rgb, uGlassColor.rgb, 0.22);
    frameRgb += vec3(0.08, 0.12, 0.16) * smoothstep(0.70, 1.0, frameTex.r) * 0.25;
    col = mix(col, frameRgb, frameAlpha);

    fragColor = vec4(col, 1.0);
}
