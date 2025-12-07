import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    pluginId: "hueManager"

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
        }
    }
}
