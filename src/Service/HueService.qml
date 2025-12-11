pragma Singleton

import QtQuick
import qs.Common
import qs.Services

Item {
    id: service

    property Component roomComponent: HueRoom {}
    property Component lightComponent: HueLight {}

    readonly property string pluginId: "hueManager"

    readonly property var defaults: ({
            openHuePath: "openhue",
            refreshInterval: 5000,
            useDeviceIcons: true
        })

    property bool isError: false
    property string errorMessage: ""

    property string openHuePath: defaults.openHuePath
    property int refreshInterval: defaults.refreshInterval
    property bool useDeviceIcons: defaults.useDeviceIcons

    property string bridgeIP: ""
    property var rooms: new Map()
    property var lights: new Map()

    Connections {
        target: PluginService
        function onPluginDataChanged(pluginId) {
            if (pluginId === service.pluginId) {
                service.loadSettings();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: service.refreshInterval
        repeat: true
        running: false
        onTriggered: service.refresh()
    }

    onRefreshIntervalChanged: {
        if (refreshTimer.running) {
            refreshTimer.restart();
        }
    }

    Component.onCompleted: {
        initialize();
    }

    function initialize() {
        loadSettings();
        checkOpenHueAvailable(available => {
            if (!available) {
                console.error(`${pluginId}: OpenHue is not available.`);
                return;
            }
            checkIsOpenHueSetup(configured => {
                if (!configured) {
                    console.error(`${pluginId}: OpenHue is not configued.`);
                    return;
                }
                refresh();
                refreshTimer.start();
            });
        });
    }

    function loadSettings() {
        const load = key => PluginService.loadPluginData(pluginId, key) || defaults[key];
        openHuePath = load("openHuePath");
        refreshInterval = parseInt(load("refreshInterval"));
        useDeviceIcons = load("useDeviceIcons");
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
        getLights();
    }

    function getHueBridgeIP() {
        Proc.runCommand(`${pluginId}.openhueDiscover`, [openHuePath, "discover"], (output, exitCode) => {
            service.bridgeIP = exitCode === 0 ? output.trim() : "Unknown";
        }, 100);
    }

    function createEntityObject(data) {
        const component = data.entityType === "room" ? roomComponent : lightComponent;

        const properties = {
            entityId: data.id,
            name: data.name,
            entityType: data.entityType,
            archetype: data.archetype,
            on: data.on,
            dimming: data.dimming,
            _service: service
        };

        if (data.entityType === "light") {
            properties.room = {
                id: data.roomId,
                name: data.roomName
            };
        }

        if (data.entityType === "room") {
            properties.lastOnDimming = data.on ? data.dimming : 100;
            properties.lights = data.lights || [];
        }

        return component.createObject(service, properties);
    }

    function updateEntity(entity, data) {
        entity.name = data.name;
        entity.archetype = data.archetype;
        entity.on = data.on;
        entity.dimming = data.dimming;

        if (entity.entityType === "light") {
            entity.room = {
                id: data.roomId,
                name: data.roomName
            };
        }

        if (entity.entityType === "room") {
            entity.lights = data.lights || [];
        }
    }

    function getEntities(entityType, command) {
        const property = `${entityType}s`;

        Proc.runCommand(`${pluginId}.get_${property}`, ["sh", "-c", command], (output, exitCode) => {
            if (exitCode !== 0) {
                console.error(`${pluginId}: Failed to get ${entityType}s:`, output);
                return;
            }

            let rawEntities;
            try {
                rawEntities = JSON.parse(output.trim());
            } catch (e) {
                console.error(`${pluginId}: Failed to parse ${entityType}s JSON:`, e);
                return;
            }

            const currentMap = service[property];
            const updatedEntities = new Map(); // force quickshell reactivity by reassignment instead of mutating

            rawEntities.forEach(entityData => {
                const existing = currentMap.get(entityData.id);
                if (existing) {
                    updateEntity(existing, entityData);
                    updatedEntities.set(entityData.id, existing);
                } else {
                    const newEntity = createEntityObject(entityData);
                    updatedEntities.set(entityData.id, newEntity);
                }
            });

            currentMap.forEach((entity, id) => {
                if (!updatedEntities.has(id)) {
                    entity.destroy();
                }
            });

            service[property] = updatedEntities;
        }, 100);
    }

    function getRooms() {
        const jqMap = `
            [.[] | {
                id: .Id,
                name: .Name,
                entityType: "room",

                on: .GroupedLight.HueData.on.on,
                dimming: .GroupedLight.HueData.dimming.brightness,

                archetype: (.HueData.metadata.archetype // ""),

                lights: [.Devices[]? | select(.Light != null) | {id: .Light.Id, name: .Light.Name}]
            }]
        `;

        getEntities("room", `${openHuePath} get room -j | jq '${jqMap}'`);
    }

    function getLights() {
        const jqMap = `
            [.[] | {
                id: .Id,
                name: .Name,
                entityType: "light",

                on: .HueData.on.on,
                dimming: .HueData.dimming.brightness,

                archetype: (.HueData.metadata.archetype // ""),

                roomId: .Parent.Parent.Id,
                roomName: .Parent.Parent.Name
            }]
        `;

        getEntities("light", `${openHuePath} get light -j | jq '${jqMap}'`);
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
                console.error(`${pluginId}: Failed to toggle ${entity.entityType} ${entity.entityId}:`, output);
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
                console.error(`${pluginId}: Failed to set ${entity.entityType} brightness ${entity.entityId}:`, output);
                Qt.callLater(refresh);
            }
        }, 100);
    }
}
