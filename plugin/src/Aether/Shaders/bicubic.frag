#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

layout(binding = 1) uniform sampler2D source;

// Catmull-Rom weights for the taps at -1, 0, +1 and +2 relative to floor(t). At t == 0 they
// collapse to (0, 1, 0, 0), which is what makes the filter an identity on the pixel grid.
vec4 weights(float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return vec4(-0.5 * t3 + t2 - 0.5 * t, 1.5 * t3 - 2.5 * t2 + 1.0, -1.5 * t3 + 2.0 * t2 + 0.5 * t, 0.5 * t3 - 0.5 * t2);
}

void main() {
    // The real texture size, not the item's size: a layer is rounded up to whole pixels while
    // the item can be fractional, and a size that disagrees with the texture drifts the texel
    // grid a fraction per pixel -- a periodic checkerboard over the whole panel.
    vec2 texSize = vec2(textureSize(source, 0));

    // Texel-space position with texel centres on whole numbers, then split into the whole part
    // and the fraction the kernel needs.
    vec2 t = qt_TexCoord0 * texSize - 0.5;
    vec2 base = floor(t);
    vec2 f = t - base;

    vec4 wx = weights(f.x);
    vec4 wy = weights(f.y);

    vec4 acc = vec4(0.0);
    for (int j = 0; j < 4; ++j) {
        float wyj = wy[j];
        for (int i = 0; i < 4; ++i) {
            vec2 samplePos = (base + vec2(float(i) - 1.0, float(j) - 1.0) + 0.5) / texSize;
            acc += texture(source, samplePos) * (wx[i] * wyj);
        }
    }

    // Catmull-Rom has negative lobes; on premultiplied alpha that can push a channel below zero
    // and ring around high-contrast edges.
    fragColor = max(acc, vec4(0.0)) * qt_Opacity;
}
