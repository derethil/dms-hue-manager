import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "../utils/EntityUtils.js" as EntityUtils

Item {
    id: root

    required property var entity
    required property bool expanded

    signal powerToggled(bool isOn)

    width: parent.width
    visible: root.opacity > 0
    opacity: root.expanded ? 1 : 0
    height: root.expanded ? content.implicitHeight : 0
    clip: true

    component EntityAction: Rectangle {
        id: actionItem

        required property string icon
        required property color iconColor
        required property string label

        Layout.fillWidth: true
        Layout.preferredHeight: Theme.iconSize * 2
        color: Theme.surfaceContainerHigh
        radius: Theme.cornerRadius

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingL
            spacing: Theme.spacingS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: actionItem.icon
                size: Theme.iconSizeSmall
                color: actionItem.iconColor

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.shorterDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: actionItem.label
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.shorterDuration
            easing.type: Theme.standardEasing
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Theme.shorterDuration
            easing.type: Theme.standardEasing
        }
    }

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 0

        EntityAction {
            iconColor: {
                const color = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(color, root.entity.dimming);
            }
            icon: "power_settings_new"
            label: "Power"

            DankToggle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingL

                checked: root.entity.on
                onToggled: {
                    root.entity.togglePower();
                }
            }
        }

        EntityAction {
            Layout.preferredHeight: 48
            iconColor: {
                const color = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(color, root.entity.dimming);
            }
            icon: "brightness_6"
            label: "Brightness"

            DankSlider {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingL
                width: 150

                value: root.entity.dimming
                minimum: 0
                maximum: 100
                enabled: root.entity.on

                onSliderValueChanged: newValue => {
                    root.entity.setBrightness(newValue);
                }
            }
        }
    }
}
