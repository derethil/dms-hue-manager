function dimColorByBrightness(color, entity) {
    const brightness = entity.isDimmable ? entity.dimming : (entity.on ? 100 : 0);
    const minBrightness = 0.4;
    const factor = minBrightness + (brightness / 100) * (1 - minBrightness);
    return Qt.rgba(color.r * factor, color.g * factor, color.b * factor, color.a);
}
