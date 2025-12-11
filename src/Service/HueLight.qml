import QtQuick
import "../utils/Color.js" as ColorUtils

HueEntity {
    id: light

    property var colorData: null
    property var temperature: null
    property var room

    property var minDimming

    property bool isColorCapable: colorData !== null

    property var color: {
        if (!light.isColorCapable) {
            return null;
        }

        return ColorUtils.HueXYToHex(light.colorData.xy.x, light.colorData.xy.y, light.dimming / 100, light.colorData.gamut);
    }

    function setColor(newColor: string) {
        if (!light.isColorCapable) {
            console.warn("Cannot set color on non-color-capable light:", light.name);
            return;
        }

        if (light.temperature) {
            light.temperature = {
                value: light.temperature.value,
                schema: light.temperature.schema,
                valid: false
            };
        }

        light.color = newColor;
        _service.applyEntityColor(light, newColor);
    }

    function setTemperature(newTemperature: real) {
        if (!light.temperature) {
            console.warn("Cannot set temperature on non-temperature-capable light:", light.name);
            return;
        }

        light.temperature = {
            value: newTemperature,
            schema: light.temperature.schema,
            valid: true
        };

        _service.applyEntityTemperature(light, newTemperature);
    }
}
