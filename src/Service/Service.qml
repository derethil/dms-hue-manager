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
    property var sceneToRoom: new Map()

    property bool preserveWidgetStateOnNextOpen: false

    property Component roomComponent: Room {}
    property Component lightComponent: Light {}

    readonly property alias commands: commands

    Commands {
        id: commands
        pluginId: service.pluginId
        openHuePath: service.openHuePath
        refresh: service.refresh
    }

    EventHandler {
        id: eventHandler
        service: service
        pluginId: service.pluginId
        refresh: service.refresh
        commands: service.commands
    }

    JqMaps {
        id: jqMaps
    }

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
                eventHandler.handleEventLine(data.trim());
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
        getEntities("room", `${openHuePath} get room -j | ${jqPath} '${jqMaps.rooms}'`);
    }

    function getLights() {
        getEntities("light", `${openHuePath} get light -j | ${jqPath} '${jqMaps.lights}'`);
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
            applyLightData(target, data);
        } else if (data.entityType === "room") {
            applyRoomData(target, data, isCreating);
        }
    }

    function applyLightData(target, data) {
        target.dimming = data.dimming.dimming;
        target.minDimming = data.dimming.minDimming * 100;
        target.room = data.room ?? null;

        if (data.color?.gamut !== null && data.color?.xy !== null) {
            target.colorData = data.color;
        }

        if (data.temperature?.valid !== null) {
            target.temperature = data.temperature ?? null;
        }
    }

    function applyRoomData(target, data, isCreating) {
        target.dimming = data.dimming;
        target.lights = data.lights || [];

        if (isCreating) {
            target.lastOnDimming = data.on ? data.dimming : 100;
        }

        if (data.scenes?.length > 0) {
            target.scenes = data.scenes;
            data.scenes.forEach(scene => {
                service.sceneToRoom.set(scene.id, data.id);
            });
        }
    }

    function setError(message) {
        console.error(`${pluginId}: ${message}`);
        service.isError = true;
        service.errorMessage = message;
    }
}
