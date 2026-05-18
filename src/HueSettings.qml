import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "hueManager"

    // Cache the room list so the Repeater only rebuilds when rooms actually change
    property var roomList: Array.from(HueService.rooms.values())

    StyledText {
        width: parent.width
        text: "Hue Manager Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure behavior and preferences for Hue Manager."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: settingsColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: settingsColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StringSetting {
                settingKey: "openHuePath"
                label: "OpenHue Path"
                description: "Path or name of the openhue cli executable."
                defaultValue: HueService.defaults.openHuePath
                placeholder: HueService.defaults.openHuePath
            }

            StringSetting {
                settingKey: "jqPath"
                label: "jq Path"
                description: "Path or name of the jq executable."
                defaultValue: HueService.defaults.jqPath
                placeholder: HueService.defaults.jqPath
            }

            ToggleSetting {
                settingKey: "useDeviceIcons"
                label: "Use Device Icons"
                description: "Use specific icons for different types of Hue devices."
                defaultValue: HueService.defaults.useDeviceIcons
            }
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Theme Sync"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Synchronise your Hue lights with the DMS accent colour. The accent colour is read from the current theme and applied to all colour-capable lights."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: themeSyncColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: themeSyncColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            ToggleSetting {
                settingKey: "autoSyncAccent"
                label: "Auto-Sync Accent Colour"
                description: "Automatically sync lights to the DMS accent colour whenever the theme changes."
                defaultValue: false
                onValueChanged: {
                    if (value) {
                        HueService.syncAllToAccent();
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: 1
                color: Theme.outline
                opacity: 0.2
            }

            StyledText {
                text: "Sync Rooms"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                width: parent.width
                text: "Choose which rooms to sync. All rooms are selected by default."
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.roomList

                delegate: Row {
                    id: roomDelegate
                    required property var modelData

                    spacing: Theme.spacingS
                    anchors.left: parent.left

                    CheckBox {
                        id: roomCheck
                        Component.onCompleted: checked = HueService._syncRoomIds.has(roomDelegate.modelData.entityId)
                        onClicked: {
                            if (checked) {
                                HueService._syncRoomIds.add(roomDelegate.modelData.entityId);
                            } else {
                                HueService._syncRoomIds.delete(roomDelegate.modelData.entityId);
                            }
                            HueService.saveSyncRoomIds();
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: roomDelegate.modelData.name
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: 1
                color: Theme.outline
                opacity: 0.2
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: "Accent Colour Preview"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                Row {
                    spacing: Theme.spacingM
                    anchors.left: parent.left

                    Rectangle {
                        id: accentPreview
                        width: 32
                        height: 32
                        radius: Theme.cornerRadius
                        color: Theme.currentThemeData?.primary ?? "#42a5f5"
                        border.width: 1
                        border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.2)
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        StyledText {
                            text: Theme.currentThemeData?.primary ?? "#42a5f5"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.family: "monospace"
                        }

                        StyledText {
                            text: "Current accent colour from theme"
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: Theme.surfaceVariantText
                        }
                    }
                }
            }

            DankButton {
                id: syncNowButton
                width: parent.width
                text: "Sync Now"
                iconName: "sync"
                enabled: HueService.isReady && HueService.lights.size > 0
                onClicked: {
                    HueService.syncAllToAccent();
                }
            }

            StyledText {
                width: parent.width
                text: {
                    if (!HueService.isReady)
                        return "Hue service is not ready yet.";
                    if (HueService.lights.size === 0)
                        return "No lights found. Make sure your Hue bridge is configured.";
                    return "This will apply the current accent colour to colour-capable lights that are turned on in the selected rooms.";
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }
}
