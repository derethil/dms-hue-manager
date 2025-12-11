function dimColorByBrightness(color, entity) {
    const brightness = entity.isDimmable ? entity.dimming : (entity.on ? 100 : 0);
    const minBrightness = 0.4;
    const factor = minBrightness + (brightness / 100) * (1 - minBrightness);
    return Qt.rgba(color.r * factor, color.g * factor, color.b * factor, color.a);
}

function milrekToKelvin(milek) {
    return Math.round(1_000_000 / milek);
}

function kelvinToMilrek(kelvin) {
    return Math.round(1_000_000 / kelvin);
}

function getEntityIcon(entity, useDeviceIcons) {
    // roughly map hue's archetypes to mdi icons

    if (entity.entityType === "room") {
        if (!useDeviceIcons) {
            return "light_group";
        }

        switch (entity.archetype) {
            case "living_room":
                return "chair";
            case "kitchen":
                return "kitchen"
            case "dining":
                return "table_bar"
            case "bedroom":
            case "kids_bedroom":
                return "bed";
            case "bathroom":
                return "bathtub"
            case "nursery":
                return "crib"
            case "guest_room":
            case "office":
                return "chair"

            case "staircase":
                return "stairs_2"
            case "hallway":
                return "hallway"
            case "laundry_room":
                return "laundry"
            case "storage":
                return "home_storage"
            case "closet":
                return "dresser"
            case "garage":
                return "construction";
            case "other":
                return "door_open"

            case "gym":
              return "exercise"
            case "lounge":
                return "weekend"
            case "tv":
                return "TV"
            case "computer":
                return "computer"
            case "recreation":
                return "sports_tennis"
            case "man_cave":
                return "sports_esports"
            case "music":
                return "headphones"
            case "reading":
                return "book_5"
            case "studio":
                return "palette"

            case "garden":
                return "grass"
            case "terrace":
                return "deck"
            case "balcony":
                return "balcony"
            case "driveway":
                return "directions_car"
            case "carport":
                return "garage_home"
            case "front_door":
                return "door_front"
            case "barbecue":
                return "outdoor_grill"
            case "pool":
                return "pool"

            case "home":
                return "home"

            default:
                console.warn(`hueManager: ${entity.archetype} does not have a corresponding MDI icon or is not supported`)
                return "light_group"
        }
    }

    if (entity.entityType === "light") {
        if (!useDeviceIcons) {
            return "lightbulb_2";
        }

        switch (entity.archetype) {
            case "table_shade":
            case "flexible_lamp":
            case "table_wash":
                return "table_lamp";

            case "christmas_tree":
                return "park"

            case "floor_shade":
            case "floor_lantern":
            case "bollard":
            case "ground_spot":
            case "recessed_floor":
            case "wall_washer":
                return "floor_lamp";

            case "pendant_round":
            case "pendant_long":
            case "ceiling_round":
            case "ceiling_square":
            case "single_spot":
            case "double_spot":
            case "recessed_ceiling":
            case "pendant_spot":
            case "ceiling_horizontal":
            case "ceiling_tube":
                return "light";

            case "wall_lantern":
            case "wall_shade":
            case "wall_spot":
            case "up_and_down":
            case "up_and_down_down":
            case "up_and_down_up":
                return "wall_lamp";

            default:
                console.warn(`hueManager: ${entity.archetype} does not have a corresponding MDI icon or is not supported`)
                return "lightbulb";
        }
    }
}
