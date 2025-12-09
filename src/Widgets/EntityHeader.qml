pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: root

    required property var entity
    required property bool expanded

    signal toggleExpanded

    width: parent.width
    height: 48
    radius: Theme.cornerRadius
    border.width: 0

    function dimColorByBrightness(color, brightness) {
        const minBrightness = 0.4;
        const factor = minBrightness + (brightness / 100) * (1 - minBrightness);
        return Qt.rgba(color.r * factor, color.g * factor, color.b * factor, color.a);
    }

    component ToggleButton: Rectangle {
        width: Theme.iconSizeSmall * 2
        height: Theme.iconSizeSmall * 2
        color: toggleEntityMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
        radius: Theme.cornerRadius

        DankIcon {
            anchors.centerIn: parent
            name: "light_group"
            size: Theme.iconSize
            color: {
                const color = root.entity.on ? Theme.primary : Theme.surfaceText;
                return root.dimColorByBrightness(color, root.entity.dimming);
            }

            Behavior on color {
                ColorAnimation {
                    duration: Theme.shorterDuration
                    easing.type: Theme.standardEasing
                }
            }
        }

        MouseArea {
            id: toggleEntityMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.entity.togglePower();
            }
        }
    }

    component HeaderText: StyledText {
        required property color textColor
        color: root.dimColorByBrightness(textColor, root.entity.dimming)
        Behavior on color {
            ColorAnimation {
                duration: Theme.shorterDuration
                easing.type: Theme.standardEasing
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.toggleExpanded();
        }
    }

    Row {
        spacing: Theme.spacingS

        ToggleButton {
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            HeaderText {
                text: root.entity.name
                textColor: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
            }

            HeaderText {
                text: `Power: ${root.entity.on ? "On" : "Off"}, Brightness: ${root.entity.dimming}%`
                textColor: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
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
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: Theme.shorterDuration
                    easing.type: Theme.standardEasing
                }
            }
        }

        MouseArea {
            id: chevronMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.toggleExpanded();
            }
        }
    }
}
