import QtQuick

HueEntity {
    id: room

    property var lastOnDimming: dimming
    property var lights: []

    property var scenes: []
    property var activeScene: null

    onScenesChanged: {
        const newActiveScene = room.scenes.find(scene => scene.active) ?? null;
        room.activeScene = newActiveScene;
    }

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
            console.warn(`${_service.pluginId}: Cannot set brightness on non-dimmable room: ${room.name}`);
            return;
        }

        // Update lastOnDimming when adjusting brightness while on
        if (room.on) {
            room.lastOnDimming = value;
        }

        room.dimming = value;

        _service.applyEntityBrightness(room, value);
    }

    function activateScene(sceneId) {
        const scene = scenes.find(s => s.id === sceneId);

        console.warn("SCENE ID", sceneId);
        console.warn("FOUND SCENE", JSON.stringify(scene));

        if (!scene) {
            console.warn(`${_service.pluginId}: Scene with ID ${sceneId} not found in room ${room.name}`);
            return;
        }

        room.scenes.forEach(s => s.active = (s.id === sceneId));
        room.activeScene = scene;

        _service.applyActivateScene(scene);
    }

    function disableScene() {
        room.scenes.forEach(s => s.active = false);
        room.activeScene = null;
    }
}
