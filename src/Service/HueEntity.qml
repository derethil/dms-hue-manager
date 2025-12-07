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

    function togglePower() {
        entity.on = !entity.on;
        _service.applyEntityPower(entity, entity.on);
    }

    function setBrightness(value: real) {
        entity.dimming = value;
        _service.applyEntityBrightness(entity, value);
    }
}
