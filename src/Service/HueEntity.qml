import QtQuick
import "../utils/EntityUtils.js" as EntityUtils

QtObject {
    id: entity

    // Static properties
    required property string name
    required property string entityId
    required property string entityType
    property string archetype: ""

    required property var _service

    // State properties
    required property bool on

    property var dimming: null

    // Computed properties
    readonly property bool isDimmable: dimming !== null

    readonly property string icon: EntityUtils.getEntityIcon(entity, _service.useDeviceIcons)

    function togglePower() {
        entity.on = !entity.on;
        _service.applyEntityPower(entity, entity.on);
    }

    function setBrightness(value: real) {
        if (!entity.isDimmable) {
            console.warn("Cannot set brightness on non-dimmable entity:", entity.name);
            return;
        }

        entity.dimming = value;
        _service.applyEntityBrightness(entity, value);
    }
}
