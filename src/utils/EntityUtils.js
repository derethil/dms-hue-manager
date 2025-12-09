function dimColorByBrightness(color, brightness) {
    const minBrightness = 0.4;
    const factor = minBrightness + (brightness / 100) * (1 - minBrightness);
    return Qt.rgba(color.r * factor, color.g * factor, color.b * factor, color.a);
}