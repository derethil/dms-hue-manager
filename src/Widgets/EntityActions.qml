import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets
import "../utils/Entities.js" as EntityUtils

Item {
    id: root

    required property var entity
    required property bool expanded

    signal powerToggled(bool isOn)
    signal viewLightsClicked(string roomId)

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
                const baseColor = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(baseColor, root.entity);
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
            visible: root.entity.isDimmable
            Layout.preferredHeight: 48
            iconColor: {
                const baseColor = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(baseColor, root.entity);
            }
            icon: "brightness_6"
            label: "Brightness"

            DankSlider {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingL
                width: 150

                value: root.entity.dimming ?? 0
                minimum: root.entity.minDimming ?? 0
                maximum: 100
                enabled: root.entity.on

                onSliderValueChanged: newValue => {
                    root.entity.setBrightness(newValue);
                }
            }
        }

        EntityAction {
            visible: root.entity.entityType === "light" && root.entity.isColorCapable
            iconColor: {
                if (root.entity.temperature?.valid) {
                    return EntityUtils.dimColorByBrightness(Theme.surfaceText, root.entity);
                }

                const baseColor = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(baseColor, root.entity);
            }
            icon: "palette"
            label: "Color"

            Item {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingL
                width: colorRow.width
                height: colorRow.height

                Row {
                    id: colorRow
                    spacing: Theme.spacingS
                    height: Theme.iconSize

                    Item {
                        width: hexText.width
                        height: parent.height

                        StyledText {
                            id: hexText
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.entity.color?.toString() || "#000000"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                    }

                    Rectangle {
                        width: Theme.iconSize
                        height: Theme.iconSize
                        radius: Theme.iconSize / 2
                        color: root.entity.color || "#000000"
                        border.color: Theme.outlineStrong
                        border.width: 2
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (PopoutService && PopoutService.colorPickerModal) {
                            const entity = root.entity;

                            HueService.preserveWidgetStateOnNextOpen = true;

                            PopoutService.colorPickerModal.selectedColor = entity.color || "#FFFFFF";
                            PopoutService.colorPickerModal.pickerTitle = "Color";
                            PopoutService.colorPickerModal.onColorSelectedCallback = function (selectedColor) {
                                entity.setColor(selectedColor);
                                Qt.callLater(() => {
                                    BarWidgetService?.triggerWidgetPopout("hueManager");
                                });
                            };
                            PopoutService.colorPickerModal.show();
                        }
                    }
                }
            }
        }

        EntityAction {
            visible: root.entity.entityType === "light" && root.entity.temperature !== null
            Layout.preferredHeight: 48
            iconColor: {
                if (!root.entity.temperature?.valid) {
                    return EntityUtils.dimColorByBrightness(Theme.surfaceText, root.entity);
                }

                const baseColor = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(baseColor, root.entity);
            }
            icon: "thermostat"
            label: "Temperature"

            DankSlider {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingL
                width: 150

                unit: "K"

                value: {
                    const milrek = root.entity.temperature?.value ?? root.entity.temperature?.schema.minimum ?? 153;
                    return EntityUtils.milrekToKelvin(milrek);
                }
                // Milrek is inverted compared to Kelvin
                minimum: {
                    const milrek = root.entity.temperature?.schema.maximum ?? 500;
                    return EntityUtils.milrekToKelvin(milrek);
                }
                maximum: {
                    const milrek = root.entity.temperature?.schema.minimum ?? 153;
                    return EntityUtils.milrekToKelvin(milrek);
                }
                enabled: root.entity.on

                onSliderValueChanged: newValue => {
                    const milrekValue = EntityUtils.kelvinToMilrek(newValue);
                    root.entity.setTemperature(milrekValue);
                }
            }
        }

        EntityAction {
            visible: root.entity.entityType === "room"
            iconColor: {
                const baseColor = root.entity.on ? Theme.primary : Theme.surfaceText;
                return EntityUtils.dimColorByBrightness(baseColor, root.entity);
            }
            icon: "view_agenda"
            label: {
                const count = root.entity.lights?.length || 0;
                return count === 1 ? "1 Light" : `${count} Lights`;
            }

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingL
                name: "chevron_right"
                size: Theme.iconSizeSmall
                color: Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.viewLightsClicked(root.entity.entityId);
                }
            }
        }
    }
}
