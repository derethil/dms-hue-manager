pragma Singleton

import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: service

    // boilerplate

    readonly property string pluginId: "hueManager"
    property Component roomComponent: HueRoom {}
    property Component lightComponent: HueLight {}

    readonly property var defaults: ({
            openHuePath: "openhue",
            refreshInterval: 5000,
            useDeviceIcons: true
        })

    property string openHuePath: defaults.openHuePath
    property int refreshInterval: defaults.refreshInterval
    property bool useDeviceIcons: defaults.useDeviceIcons

    // service state

    property bool isReady: false

    property bool isError: false
    property string errorMessage: ""

    property bool isSettingUp: false
    property bool waitingForButton: false

    // OpenHue data

    property string bridgeIP: ""
    property var rooms: new Map()
    property var lights: new Map()

    // UI state

    property bool preserveWidgetStateOnNextOpen: false

    Process {
        id: setupProcess
        running: false
        command: [service.openHuePath, "setup"]

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();

                if (line.includes("Please push the button")) {
                    console.info(`${service.pluginId}: Detected button prompt during openhue setup`);
                    service.waitingForButton = true;
                    return;
                }

                if (line.includes("Successfully paired openhue")) {
                    console.info(`${service.pluginId}: OpenHue setup completed successfully.`);

                    service.waitingForButton = false;
                    service.isSettingUp = false;

                    refresh();
                    refreshTimer.start();
                    return;
                }

                if (line.includes("Unable to discover")) {
                    setError("OpenHue setup failed: Unable to discover Hue Bridge.");
                    service.waitingForButton = false;
                    service.isSettingUp = false;
                    return;
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                const line = data.trim();
                console.error(`${service.pluginId}: Setup error output:`, line);
            }
        }

        onStarted: {
            console.info(`${service.pluginId}: OpenHue is not configured, running setup.`);
            service.isSettingUp = true;
        }
    }

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
                    setupProcess.running = true;
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

        if (!service.isReady) {
            service.isReady = true;
        }
    }

    function getHueBridgeIP() {
        Proc.runCommand(`${pluginId}.openhueDiscover`, [openHuePath, "discover"], (output, exitCode) => {
            service.bridgeIP = exitCode === 0 ? output.trim() : "Unknown";
        }, 100);
    }

    function applyEntityData(target, data, isCreating = false) {
        // Common properties
        target.name = data.name;
        target.archetype = data.archetype;
        target.on = data.on;

        // Light-specific properties
        if (data.entityType === "light") {
            target.dimming = data.dimming.dimming;
            target.minDimming = data.dimming.minDimming * 100;
            target.room = data.room ?? null;

            if (data.color.gamut !== null && data.color.xy !== null) {
                target.colorData = data.color;
            }

            if (data.temperature.valid !== null) {
                target.temperature = data.temperature ?? null;
            }
        }

        // Room-specific properties
        if (data.entityType === "room") {
            target.dimming = data.dimming;
            target.lights = data.lights || [];

            if (isCreating) {
                target.lastOnDimming = data.on ? data.dimming : 100;
            }
        }
    }

    function createEntity(data) {
        const component = data.entityType === "room" ? roomComponent : lightComponent;

        const properties = {
            entityId: data.id,
            entityType: data.entityType,
            _service: service
        };

        applyEntityData(properties, data, true);

        return component.createObject(service, properties);
    }

    function updateEntity(entity, data) {
        applyEntityData(entity, data, false);
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
                    const newEntity = createEntity(entityData);
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
                dimming: {
                    dimming: .HueData.dimming.brightness,
                    minDimming: .HueData.dimming.min_dim_level
                },
                color: {
                    xy: .HueData.color.xy,
                    gamut: .HueData.color.gamut_type
                },
                temperature: {
                    value: .HueData.color_temperature.mirek,
                    schema: {
                        maximum: .HueData.color_temperature.mirek_schema.mirek_maximum,
                        minimum: .HueData.color_temperature.mirek_schema.mirek_minimum
                    },
                    valid: .HueData.color_temperature.mirek_valid
                },

                archetype: (.HueData.metadata.archetype // ""),

                room: {
                    id: .Parent.Parent.Id,
                    name: .Parent.Parent.Name
                }
            }]
        `;

        getEntities("light", `${openHuePath} get light -j | jq '${jqMap}'`);
    }

    function setError(message) {
        console.error(`${pluginId}: ${message}`);
        service.isError = true;
        service.errorMessage = message;
    }

    function executeEntityCommand(commandName, entity, args, errorMessage) {
        refreshTimer.restart();
        const fullArgs = [openHuePath, "set", entity.entityType, entity.entityId, ...args];

        Proc.runCommand(`${pluginId}.${commandName}`, fullArgs, (output, exitCode) => {
            if (output !== "" || exitCode !== 0) {
                ToastService.showError("Hue Manager Error", errorMessage);
                console.error(`${pluginId}: ${errorMessage}:`, output);
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
}
