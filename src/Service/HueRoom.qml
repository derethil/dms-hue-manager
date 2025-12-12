import QtQuick

HueEntity {
    id: room

    property var lastOnDimming: dimming
    property var lights: []
    property var scenes: []

    Component.onCompleted: {
        // API doesn't provide brightness for rooms when off - default to 100 until first refresh where entity state is known
        if (room.isDimmable) {
            room.lastOnDimming = room.on ? room.dimming : 100;
        }
    }

    function togglePower() {
        room.on = !room.on;

        // Save last brightness level when turning off so it can be restored later
        if (room.isDimmable) {
            if (!room.on) {
                room.lastOnDimming = room.dimming;
                room.dimming = 0;
            } else {
                room.dimming = room.lastOnDimming;
            }
        }

        _service.applyEntityPower(room, room.on);
    }

    function setBrightness(value: real) {
        if (!room.isDimmable) {
            console.warn("Cannot set brightness on non-dimmable room:", room.name);
            return;
        }

        // Update lastOnDimming when adjusting brightness while on
        if (room.on) {
            room.lastOnDimming = value;
        }

        room.dimming = value;
        _service.applyEntityBrightness(room, value);
    }
}
