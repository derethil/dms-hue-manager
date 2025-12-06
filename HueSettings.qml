import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
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

            StyledText {
                width: parent.width
                text: "No configurable settings available at this time."
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }
        }
    }
}