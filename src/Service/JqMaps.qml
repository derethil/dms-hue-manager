import QtQuick

QtObject {
    readonly property string rooms: `
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
    `

    readonly property string lights: `
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
    `
}
