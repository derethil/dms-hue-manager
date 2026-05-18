import QtQuick
import qs.Common
import qs.Services

QtObject {
    id: commands

    required property string pluginId
    required property string openHuePath
    required property var refresh

    property var _queue: []
    property bool _dispatching: false

    function _dispatch() {
        if (_dispatching || _queue.length === 0) {
            return;
        }

        _dispatching = true;

        const item = _queue.shift();

        Proc.runCommand(item.key, item.args, (output, exitCode) => {
            item.onComplete(output, exitCode);
            _dispatching = false;
            _dispatch();
        }, 100);
    }

    function _enqueue(key, args, onComplete) {
        const idx = _queue.findIndex(i => i.key === key);

        const item = {
            key,
            args,
            onComplete
        };

        if (idx >= 0) {
            _queue[idx] = item;
        } else {
            _queue.push(item);
        }

        _dispatch();
    }

    function executeEntityCommand(commandName, entity, args, errorMessage) {
        const fullArgs = [openHuePath, "set", entity.entityType, entity.entityId, ...args];
        const key = `${pluginId}.${commandName}.${entity.entityId}`;

        _enqueue(key, fullArgs, (output, exitCode) => {
            if (output !== "" || exitCode !== 0) {
                ToastService.showError("Hue Manager Error", errorMessage);
                console.error(`${pluginId}: ${errorMessage}:`, output);
                Qt.callLater(refresh);
            }
        });
    }

    function executeSceneCommand(commandName, args, errorMessage) {
        const fullArgs = [openHuePath, "set", "scene", ...args];
        const sceneId = args[0];
        const key = `${pluginId}.${commandName}.${sceneId}`;

        _enqueue(key, fullArgs, (output, exitCode) => {
            if (!output.trim().includes("activated") || exitCode !== 0) {
                ToastService.showError("Hue Manager Error", errorMessage);
                console.error(`${pluginId}: ${errorMessage}:`, output.trim());
                Qt.callLater(refresh);
            }
        });
    }

    function applyEntityPower(entity, turnOn) {
        const state = turnOn ? "--on" : "--off";
        executeEntityCommand("setEntityPower", entity, [state], `Failed to toggle ${entity.entityType} ${entity.entityId}`);
    }

    function applyEntityBrightness(entity, brightness) {
        const brightnessValue = Math.round(brightness);
        executeEntityCommand("setEntityBrightness", entity, ["--brightness", brightnessValue.toString()], `Failed to set ${entity.entityType} brightness ${entity.entityId}`);
    }

    function applyEntityColor(entity, color) {
        executeEntityCommand("setEntityColor", entity, ["--rgb", color], `Failed to set ${entity.entityType} color ${entity.entityId}`);
    }

    function applyEntityTemperature(entity, temperature) {
        const tempValue = Math.round(temperature);
        executeEntityCommand("setEntityTemperature", entity, ["--temperature", tempValue.toString()], `Failed to set ${entity.entityType} temperature ${entity.entityId}`);
    }

    function applyRoomAccent(room, color) {
        executeEntityCommand("setRoomAccent", room, ["--on", "--rgb", color], `Failed to set room ${room.name} colour`);
    }

    function applyActivateScene(scene) {
        executeSceneCommand("activateScene", [scene.id], `Failed to activate scene ${scene.id}`);
    }
}
