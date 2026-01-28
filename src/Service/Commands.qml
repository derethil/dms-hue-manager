import QtQuick
import qs.Common
import qs.Services

QtObject {
    id: commands

    required property string pluginId
    required property string openHuePath
    required property var refresh

    function executeEntityCommand(commandName, entity, args, errorMessage) {
        const fullArgs = [openHuePath, "set", entity.entityType, entity.entityId, ...args];

        Proc.runCommand(`${pluginId}.${commandName}`, fullArgs, (output, exitCode) => {
            if (output !== "" || exitCode !== 0) {
                ToastService.showError("Hue Manager Error", errorMessage);
                console.error(`${pluginId}: ${errorMessage}:`, output);
                Qt.callLater(refresh);
            }
        }, 100);
    }

    function executeSceneCommand(commandName, args, errorMessage) {
        const fullArgs = [openHuePath, "set", "scene", ...args];

        Proc.runCommand(`${pluginId}.${commandName}`, fullArgs, (output, exitCode) => {
            if (!output.trim().includes("activated") || exitCode !== 0) {
                ToastService.showError("Hue Manager Error", errorMessage);
                console.error(`${pluginId}: ${errorMessage}:`, output.trim());
                Qt.callLater(refresh);
            }
        }, 100);
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

    function applyActivateScene(scene) {
        executeSceneCommand("activateScene", [scene.id], `Failed to activate scene ${scene.id}`);
    }
}
