pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: root

    required property var entity

    width: parent.width
    height: 48
    radius: Theme.cornerRadius
    border.width: 0

    component ToggleButton: Rectangle {
        width: Theme.iconSizeSmall * 2
        height: Theme.iconSizeSmall * 2
        color: mouseArea.containsMouse ? Theme.surfaceHover : "transparent"

        DankIcon {
            anchors.centerIn: parent
            name: "light_group"
            size: Theme.iconSize
            color: root.entity.on ? Theme.primary : Theme.surfaceText
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.entity.togglePower();
            }
        }
    }

    Row {
        spacing: Theme.spacingS

        ToggleButton {
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.entity.name
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }

            StyledText {
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceTextMedium
                text: `Power: ${root.entity.on ? "On" : "Off"}, Brightness: ${root.entity.dimming}%`
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.iconSizeSmall * 2
        height: Theme.iconSizeSmall * 2
        color: chevronMouseArea.containsMouse ? Theme.surfaceHover : "transparent"
        radius: Theme.cornerRadius

        DankIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Theme.spacingXS / 2
            name: "keyboard_arrow_down"
            size: Theme.iconSize
            color: Theme.surfaceText
        }

        MouseArea {
            id: chevronMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // TODO: Open entity details view
            }
        }
    }
}
