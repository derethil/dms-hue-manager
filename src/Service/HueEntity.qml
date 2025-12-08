import QtQuick

QtObject {
    id: entity

    // Static properties
    required property string name
    required property string entityId
    required property string entityType

    required property var _service

    // State properties
    required property bool on
    required property real dimming

    property real lastOnDimming: dimming

    Component.onCompleted: {
        // API doesn't provide last brightness when off - default to 100 until first refresh where entity state is known
        entity.lastOnDimming = entity.on ? entity.dimming : 100;
    }

    function togglePower() {
        entity.on = !entity.on;

        // Save last brightness level when turning off so it can be restored later
        if (!entity.on) {
            entity.dimming = 0;
        } else {
            entity.dimming = entity.lastOnDimming;
        }

        _service.applyEntityPower(entity, entity.on);
    }

    function setBrightness(value: real) {
        if (entity.on) {
            entity.lastOnDimming = value;
        }
        entity.dimming = value;
        _service.applyEntityBrightness(entity, value);
    }
}
