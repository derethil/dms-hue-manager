pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets
import "../utils/EntityUtils.js" as EntityUtils

StyledRect {
    id: root

    required property var entity
    required property bool expanded

    signal toggleExpanded

    width: parent.width
    height: 48
    radius: Theme.cornerRadius
    border.width: 0

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
                const baseColor = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(baseColor, root.entity);
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
        color: EntityUtils.dimColorByBrightness(textColor, root.entity)
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
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingS
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
                text: {
                    const powerStatus = `Power: ${root.entity.on ? "On" : "Off"}`;
                    if (root.entity.isDimmable) {
                        return `${powerStatus}, Brightness: ${root.entity.dimming}%`;
                    }
                    return powerStatus;
                }
                textColor: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Theme.spacingS
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
