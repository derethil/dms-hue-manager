import QtQuick

QtObject {
    id: eventHandler

    required property var service
    required property string pluginId
    required property var refresh
    required property var commands

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

        const eventTypeHandlers = {
            "update": handleEntityUpdate,
            "add": handleEntityAdd,
            "delete": handleEntityDelete
        };

        message.events.forEach(event => {
            if (!event.data || !Array.isArray(event.data) || eventTypeHandlers[event.type] === undefined) {
                return;
            }

            const handler = eventTypeHandlers[event.type];
            event.data.forEach(entityData => handler(entityData));
        });
    }

    function handleEntityUpdate(eventData) {
        let entity;

        if (eventData.type === "light") {
            entity = service.lights.get(eventData.id);
        } else if (eventData.type === "grouped_light" && eventData.owner.rtype === "room") {
            entity = service.rooms.get(eventData.owner.rid);
        } else if (eventData.type === "scene") {
            handleSceneUpdate(eventData);
            return;
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

    function handleSceneUpdate(eventData) {
        const roomId = service.sceneToRoom.get(eventData.id);
        const room = service.rooms.get(roomId);
        const sceneIndex = room?.scenes.findIndex(s => s.id === eventData.id) ?? -1;

        if (!roomId || !room || sceneIndex === -1) {
            console.warn(`${pluginId}: Received scene event for unknown scene ${eventData.id}`);
            console.info(`${pluginId}: Triggering full refresh to sync scene changes`);
            Qt.callLater(refresh);
            return;
        }

        const updatedScenes = [...room.scenes];

        if (eventData.metadata?.name !== undefined) {
            updatedScenes[sceneIndex].name = eventData.metadata.name;
        }

        if (eventData.status?.active !== undefined) {
            updatedScenes[sceneIndex].active = (eventData.status.active !== "inactive");
        }

        room.scenes = updatedScenes;
        console.info(`${pluginId}: Updated scene ${eventData.id} in room ${room.name}`);
    }

    function handleEntityAdd(eventData) {
        if (eventData.type === "scene" || eventData.type === "light" || eventData.type === "room") {
            console.info(`${pluginId}: New ${eventData.type} ${eventData.id} added, triggering full refresh`);
            Qt.callLater(refresh);
        }
    }

    function handleEntityDelete(eventData) {
        const deleteHandlers = {
            "scene": deleteScene,
            "light": deleteEntity,
            "room": deleteEntity
        };

        if (deleteHandlers[eventData.type]) {
            deleteHandlers[eventData.type](eventData);
        }
    }

    function deleteScene(eventData) {
        const roomId = service.sceneToRoom.get(eventData.id);
        const room = service.rooms.get(roomId);
        const sceneIndex = room?.scenes.findIndex(s => s.id === eventData.id) ?? -1;

        service.sceneToRoom.delete(eventData.id);

        if (!roomId || !room) {
            console.warn(`${pluginId}: Received delete event for unknown scene ${eventData.id}`);
            return;
        }

        if (sceneIndex !== -1) {
            const updatedScenes = [...room.scenes];
            updatedScenes.splice(sceneIndex, 1);
            room.scenes = updatedScenes;
            console.info(`${pluginId}: Deleted scene ${eventData.id} from room ${room.name}`);
        } else {
            console.warn(`${pluginId}: Scene ${eventData.id} not found in room ${room.name} scenes array`);
        }
    }

    function deleteEntity(eventData) {
        const entityMap = eventData.type === "light" ? service.lights : service.rooms;
        const entity = entityMap.get(eventData.id);

        if (!entity) {
            console.warn(`${pluginId}: Received delete event for unknown ${eventData.type} ${eventData.id}`);
            return;
        }

        entity.destroy();
        const updatedMap = new Map(entityMap);
        updatedMap.delete(eventData.id);
        service[eventData.type === "light" ? "lights" : "rooms"] = updatedMap;
        console.info(`${pluginId}: Deleted ${eventData.type} ${eventData.id}`);
    }

    function applyEventDataToEntity(entity, eventData) {
        if (eventData.on?.on !== undefined) {
            entity.on = eventData.on.on;
        }

        applyEntityDimming(entity, eventData);

        if (entity.entityType === "light") {
            applyLightColor(entity, eventData);
            applyLightTemperature(entity, eventData);
        }
    }

    function applyEntityDimming(entity, eventData) {
        const brightness = eventData.dimming?.brightness;
        if (brightness !== undefined) {
            entity.dimming = brightness;
            if (entity.entityType === "room" && entity.on && brightness > 0) {
                entity.lastOnDimming = brightness;
            }
        }
    }

    function applyLightColor(entity, eventData) {
        if (eventData.color?.xy !== undefined) {
            entity.colorData = {
                xy: eventData.color.xy,
                gamut: entity.colorData?.gamut || eventData.color.gamut_type || 'C'
            };
        }
    }

    function applyLightTemperature(entity, eventData) {
        const mirek = eventData.color_temperature?.mirek;
        if (mirek !== undefined) {
            entity.temperature = {
                value: mirek,
                schema: entity.temperature?.schema || {
                    maximum: eventData.color_temperature.mirek_schema?.mirek_maximum || 500,
                    minimum: eventData.color_temperature.mirek_schema?.mirek_minimum || 153
                },
                valid: eventData.color_temperature.mirek_valid ?? true
            };
        }
    }
}
