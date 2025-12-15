pragma Singleton

import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: service

    readonly property string pluginId: "hueManager"

    readonly property var defaults: ({
            openHuePath: "openhue",
            jqPath: "jq",
            useDeviceIcons: true
        })

    property string openHuePath: defaults.openHuePath
    property string jqPath: defaults.jqPath
    property bool useDeviceIcons: defaults.useDeviceIcons

    property bool isReady: false
    property bool isError: false
    property string errorMessage: ""
    property bool isSettingUp: false
    property bool waitingForButton: false

    property string bridgeIP: ""
    property var rooms: new Map()
    property var lights: new Map()

    property bool preserveWidgetStateOnNextOpen: false

    property Component roomComponent: HueRoom {}
    property Component lightComponent: HueLight {}

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
                    Qt.callLater(() => {
                        eventStream.running = true;
                    });
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

    Process {
        id: eventStream
        running: false
        command: ["sh", "-c", `${service.openHuePath} get events | stdbuf -oL ${service.jqPath} -c`]

        stdout: SplitParser {
            onRead: data => {
                handleEventLine(data.trim());
            }
        }

        stderr: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line) {
                    console.error(`${service.pluginId}: Event stream error:`, line);
                }
            }
        }

        onExited: exitCode => {
            console.warn(`${service.pluginId}: Event stream exited with code ${exitCode}`);
        }

        onStarted: {
            console.info(`${service.pluginId}: Event stream started`);
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

    Component.onCompleted: {
        initialize();
    }

    function initialize() {
        loadSettings();
        checkDependencies(available => {
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
                Qt.callLater(() => {
                    eventStream.running = true;
                });
            });
        });
    }

    function loadSettings() {
        const load = key => PluginService.loadPluginData(pluginId, key) ?? defaults[key];
        openHuePath = load("openHuePath");
        jqPath = load("jqPath");
        useDeviceIcons = load("useDeviceIcons");
    }

    function checkDependencies(onComplete) {
        Proc.runCommand(`${pluginId}.whichOpenhue`, ["which", openHuePath], (output, exitCode) => {
            if (exitCode !== 0) {
                setError("OpenHue is not installed. Please install it to use this plugin.");
                ToastService.showError("OpenHue Not Found", "Please install openhue-cli or set the OpenHue Path option to use Hue Manager");
                onComplete(false);
                return;
            }
            onComplete(true);
        }, 100);

        Proc.runCommand(`${pluginId}.whichJq`, ["which", jqPath], (output, exitCode) => {
            if (exitCode !== 0) {
                setError("jq is not installed. Please install it to use this plugin.");
                ToastService.showError("jq Not Found", "Please install jq or set the jq Path option to use Hue Manager");
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

    function refresh() {
        console.log(`${pluginId}: Calling refresh()`);
        getHueBridgeIP();
        getRooms();
        getLights();

        if (!service.isReady) {
            console.log(`${pluginId}: Setting isReady to true`);
            service.isReady = true;
        }
    }

    function getHueBridgeIP() {
        Proc.runCommand(`${pluginId}.openhueDiscover`, [openHuePath, "discover"], (output, exitCode) => {
            service.bridgeIP = exitCode === 0 ? output.trim() : "Unknown";
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

                scenes: [
                    .Scenes[]? |
                    {
                        id: .Id,
                        name: .Name,
                        active: (.HueData.status.active != "inactive")
                    }
                ],

                archetype: (.HueData.metadata.archetype // ""),

                lights: [
                    .Devices[]? |
                    select(.Light != null) |
                    {
                        id: .Light.Id,
                        name: .Light.Name
                    }
                ]
            }]
        `;

        getEntities("room", `${openHuePath} get room -j | ${jqPath} '${jqMap}'`);
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

        getEntities("light", `${openHuePath} get light -j | ${jqPath} '${jqMap}'`);
    }

    function getRoom(roomId) {
        return service.rooms.get(roomId) ?? null;
    }

    function getLight(lightId) {
        return service.lights.get(lightId) ?? null;
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
            const updatedEntities = new Map();

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

    function handleEventLine(line) {
        if (!line)
            return;

        var message;
        try {
            message = JSON.parse(line);
        } catch (e) {
            console.error(`${pluginId}: Failed to parse event JSON:`, e);
            return;
        }

        if (!message.events || !Array.isArray(message.events)) {
            return;
        }

        message.events.forEach(event => {
            if (event.type === "update" && event.data) {
                event.data.forEach(entityData => {
                    handleEntityUpdate(entityData);
                });
            }
        });
    }

    function handleEntityUpdate(eventData) {
        let entity;

        if (eventData.type === "light") {
            entity = service.lights.get(eventData.id);
        } else if (eventData.type === "grouped_light" && eventData.owner.rtype === "room") {
            entity = service.rooms.get(eventData.owner.rid);
        } else {
            return;
        }

        if (!entity) {
            console.warn(`${pluginId}: Received event for unknown ${eventData.type}:`);
            console.info(`${pluginId}: Triggering full refresh to sync new entities`);
            Qt.callLater(refresh);
            return;
        }

        applyEventDataToEntity(entity, eventData);
    }

    function applyEventDataToEntity(entity, eventData) {
        if (eventData.on !== undefined && eventData.on.on !== undefined) {
            entity.on = eventData.on.on;
        }

        if (eventData.dimming !== undefined && eventData.dimming.brightness !== undefined) {
            let brightness = eventData.dimming.brightness;

            if (entity.entityType === "light") {
                entity.dimming = brightness;
            } else if (entity.entityType === "room") {
                entity.dimming = brightness;
                if (entity.on && brightness > 0) {
                    entity.lastOnDimming = brightness;
                }
            }
        }

        if (entity.entityType === "light") {
            if (eventData.color !== undefined && eventData.color.xy !== undefined) {
                entity.colorData = {
                    xy: eventData.color.xy,
                    gamut: entity.colorData?.gamut || eventData.color.gamut_type || 'C'
                };
            }

            if (eventData.color_temperature !== undefined && eventData.color_temperature.mirek !== undefined) {
                let mirek = eventData.color_temperature.mirek;
                let valid = eventData.color_temperature.mirek_valid;

                entity.temperature = {
                    value: mirek,
                    schema: entity.temperature?.schema || {
                        maximum: eventData.color_temperature.mirek_schema?.mirek_maximum || 500,
                        minimum: eventData.color_temperature.mirek_schema?.mirek_minimum || 153
                    },
                    valid: valid !== undefined ? valid : true
                };
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

    function applyEntityData(target, data, isCreating = false) {
        target.name = data.name;
        target.archetype = data.archetype;
        target.on = data.on;

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

        if (data.entityType === "room") {
            target.dimming = data.dimming;
            target.lights = data.lights || [];

            if (isCreating) {
                target.lastOnDimming = data.on ? data.dimming : 100;
            }

            if (data.scenes.length > 0) {
                target.scenes = data.scenes;
            }
        }
    }

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

    function setError(message) {
        console.error(`${pluginId}: ${message}`);
        service.isError = true;
        service.errorMessage = message;
    }
}
