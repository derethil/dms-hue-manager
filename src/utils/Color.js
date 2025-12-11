/**
 * Converts Hue XY color values to an sRGB hex string.
 * @param {number} x - CIE x coordinate
 * @param {number} y - CIE y coordinate
 * @param {number} brightness - brightness (0–1)
 * @param {'A'|'B'|'C'} gamutType - Hue color gamut type
 */
function HueXYToHex(x, y, brightness = 1.0, gamutType = 'C') {
    const z = 1.0 - x - y;
    const Y = brightness;
    const X = (Y / y) * x;
    const Z = (Y / y) * z;

    const m = GAMUT_MATRICES[gamutType];
    if (!m) {
        console.warn(`hueManager: invalid gamut type '${gamutType}', defaulting to 'C'`);
    }

    // Convert XYZ to linear RGB using gamut matrix
    let r = X * m.r[0] + Y * m.r[1] + Z * m.r[2];
    let g = X * m.g[0] + Y * m.g[1] + Z * m.g[2];
    let b = X * m.b[0] + Y * m.b[1] + Z * m.b[2];

    // Apply gamut scaling (soft compression instead of clipping)
    [r, g, b] = normalizeGamut(r, g, b);

    // Apply gamma correction
    r = gammaCorrect(r);
    g = gammaCorrect(g);
    b = gammaCorrect(b);

    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

/**
 * Scales RGB channels to fit into [0,1] range
 * without losing relative hue balance.
 */
function normalizeGamut(r, g, b) {
    const maxChannel = Math.max(r, g, b);
    const minChannel = Math.min(r, g, b);

    if (maxChannel > 1 || minChannel < 0) {
        const scale = 1 / Math.max(maxChannel, 1);
        r *= scale;
        g *= scale;
        b *= scale;

        if (minChannel < 0) {
            const lift = -minChannel;
            r += lift;
            g += lift;
            b += lift;
        }
    }

    // Final clamp
    return [
        Math.min(Math.max(r, 0), 1),
        Math.min(Math.max(g, 0), 1),
        Math.min(Math.max(b, 0), 1),
    ];
}

function gammaCorrect(v) {
    return v <= 0.0031308 ? 12.92 * v : 1.055 * Math.pow(v, 1 / 2.4) - 0.055;
}

function toHex(value) {
    return Math.round(value * 255).toString(16).padStart(2, '0');
}

// Conversion matrices for Hue color gamuts (Wide RGB D65 basis)
const GAMUT_MATRICES = {
    A: {
        r: [1.64173, -0.32466, -0.23688],
        g: [-0.66366, 1.61533, 0.01688],
        b: [0.01172, -0.00801, 0.98839],
    },
    B: {
        r: [1.612, -0.203, -0.302],
        g: [-0.509, 1.412, 0.066],
        b: [0.026, -0.072, 0.962],
    },
    C: {
        r: [1.613203, -0.681814, -0.129553],
        g: [-0.481816, 1.586499, -0.082051],
        b: [0.017600, -0.069057, 1.081680],
    },
};

