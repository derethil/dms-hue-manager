pragma Singleton

import QtQuick
import qs.Common
import qs.Services

Item {
    id: service

    property Component entityComponent: HueEntity {}

    readonly property string pluginId: "hueManager"

    readonly property var defaults: ({
            openHuePath: "openhue"
        })

    property bool isError: false
    property string errorMessage: ""

    property string openHuePath: defaults.openHuePath

    property string bridgeIP: ""
    property var rooms: []

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: true
        running: false
        onTriggered: service.refresh()
    }

    Component.onCompleted: {
        initialize();
    }

    function initialize() {
        loadSettings();
        checkOpenHueAvailable(available => {
            if (!available)
                return;
            checkIsOpenHueSetup(configured => {
                if (!configured)
                    return;
                refresh();
                refreshTimer.start();
            });
        });
    }

    function loadSettings() {
        const load = key => PluginService.loadPluginData(pluginId, key) || defaults[key];
        openHuePath = load("openHuePath");
    }

    // initial checks

    function checkOpenHueAvailable(onComplete) {
        Proc.runCommand(`${pluginId}.whichOpenhue`, ["which", openHuePath], (output, exitCode) => {
            if (exitCode !== 0) {
                setError("OpenHue is not installed. Please install it to use this plugin.");
                ToastService.showError("OpenHue Not Found", "Please install openhue-cli or set the OpenHue Path option to use Hue Manager");
                onComplete(false);
                return;
            }
            onComplete(true);
        }, 100);
    }

    function checkIsOpenHueSetup(onComplete) {
        Proc.runCommand(`${pluginId}.openhueGet`, [openHuePath, "get"], (output, exitCode) => {
            if (output.trim().includes("please run the 'setup' command")) {
                setError("OpenHue is not set up. Please set up your Hue Bridge with 'openhue setup'.");
                ToastService.showError("OpenHue Setup Required", "Please run 'openhue setup' to configure your Hue Bridge");
                onComplete(false);
                return;
            }
            onComplete(true);
        }, 100);
    }

    // hue operations

    function refresh() {
        getHueBridgeIP();
        getRooms();
    }

    function getHueBridgeIP() {
        Proc.runCommand(`${pluginId}.openhueDiscover`, [openHuePath, "discover"], (output, exitCode) => {
            service.bridgeIP = exitCode === 0 ? output.trim() : "Unknown";
        }, 100);
    }

    function createEntityObject(data) {
        return entityComponent.createObject(service, {
            entityId: data.id,
            name: data.name,
            entityType: data.entityType,
            on: data.on,
            dimming: data.dimming,
            _service: service
        });
    }

    function updateEntity(entity, data) {
        entity.name = data.name;
        entity.on = data.on;
        entity.dimming = data.dimming;
        if (data.on) {
            entity.lastOnDimming = data.dimming;
        }
    }

    function getRooms() {
        const command = `${openHuePath} get room -j | jq '[.[] | {name: .Name, dimming: .GroupedLight.HueData.dimming.brightness, on: .GroupedLight.HueData.on.on, id: .Id, entityType: "room"}]'`;
        Proc.runCommand(`${pluginId}.openhueRooms`, ["sh", "-c", command], (output, exitCode) => {
            if (exitCode === 0) {
                try {
                    const rawRooms = JSON.parse(output.trim());
                    const updatedRooms = [];

                    rawRooms.forEach(roomData => {
                        const existing = service.rooms.find(r => r.entityId === roomData.id);
                        if (existing) {
                            updateEntity(existing, roomData);
                            updatedRooms.push(existing);
                        } else {
                            updatedRooms.push(createEntityObject(roomData));
                        }
                    });

                    service.rooms.forEach(room => {
                        if (!updatedRooms.includes(room)) {
                            room.destroy();
                        }
                    });

                    service.rooms = updatedRooms;
                } catch (e) {
                    console.error("HueManager: Failed to parse rooms JSON:", e);
                    service.rooms = [];
                }
            } else {
                console.error("HueManager: Failed to get rooms:", output);
            }
        }, 100);
    }

    function setError(message) {
        service.isError = true;
        service.errorMessage = message;
    }

    function applyEntityPower(entity, turnOn) {
        refreshTimer.restart();
        const state = turnOn ? "--on" : "--off";
        Proc.runCommand(`${pluginId}.setEntityPower`, [openHuePath, "set", entity.entityType, entity.entityId, state], (output, exitCode) => {
            if (output !== "") {
                ToastService.showError("Hue Manager Error", `Failed to toggle ${entity.entityType} ${entity.entityId}`);
                console.error(`HueManager: Failed to toggle ${entity.entityType} ${entity.entityId}:`, output);
                Qt.callLater(refresh);
            }
        }, 100);
    }

    function applyEntityBrightness(entity, brightness) {
        refreshTimer.restart();
        const brightnessValue = Math.round(brightness);
        Proc.runCommand(`${pluginId}.setEntityBrightness`, [openHuePath, "set", entity.entityType, entity.entityId, "--brightness", brightnessValue.toString()], (output, exitCode) => {
            if (output !== "") {
                ToastService.showError("Hue Manager Error", `Failed to set ${entity.entityType} brightness ${entity.entityId}`);
                console.error(`HueManager: Failed to set ${entity.entityType} brightness ${entity.entityId}:`, output);
                Qt.callLater(refresh);
            }
        }, 100);
    }
}
