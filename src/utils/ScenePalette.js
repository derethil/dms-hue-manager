.import "Color.js" as ColorUtils

function colors(scene) {
    const result = [];
    for (const entry of scene.preview || []) {
        let color = null;
        if (Number.isFinite(entry.xy?.x) && Number.isFinite(entry.xy?.y) && entry.xy.y > 0)
            color = ColorUtils.HueXYToHex(entry.xy.x, entry.xy.y, 1, 'C');
        else if (Number.isFinite(entry.temperature) && entry.temperature > 0)
            color = temperatureColor(entry.temperature);
        if (color && result.indexOf(color) === -1)
            result.push(color);
    }
    if (result.length > 3)
        return [result[0], result[Math.floor(result.length / 2)], result[result.length - 1]];
    return result;
}

function temperatureColor(mirek) {
    // Approximate screen swatches for Hue's 2000–6500 K white-temperature range.
    const temperature = Math.max(20, Math.min(66, 10000 / mirek));
    const channels = [255,
        99.4708025861 * Math.log(temperature) - 161.1195681661,
        138.5177312231 * Math.log(temperature - 10) - 305.0447927307];
    return '#' + channels.map(channel => Math.round(Math.max(0, Math.min(255, channel))).toString(16).padStart(2, '0')).join('');
}
