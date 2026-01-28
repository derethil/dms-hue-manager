import QtQuick
import "../utils/Color.js" as ColorUtils

Entity {
    id: light

    property var room

    property var minDimming
    property var colorData: null
    property bool isColorCapable: colorData !== null
    property var temperature: null
    property bool isTemperatureCapable: temperature !== null

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

        if (light.isTemperatureCapable) {
            light.temperature = {
                value: light.temperature.value,
                schema: light.temperature.schema,
                valid: false
            };
        }

        light.color = newColor;
        _service.getRoom(room.id)?.disableScene();
        _service.commands.applyEntityColor(light, newColor);
    }

    function setTemperature(newTemperature: real) {
        if (!light.isTemperatureCapable) {
            console.warn("Cannot set temperature on non-temperature-capable light:", light.name);
            return;
        }

        light.temperature = {
            value: newTemperature,
            schema: light.temperature.schema,
            valid: true
        };

        _service.getRoom(room.id)?.disableScene();
        _service.commands.applyEntityTemperature(light, newTemperature);
    }
}
