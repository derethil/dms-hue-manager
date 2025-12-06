import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import qs.Modules.ControlCenter.Widgets

PluginComponent {
    id: root
    layerNamespacePlugin: "hue-manager"

    property bool isOpen: false
    property string activeView: "rooms"

    Component.onCompleted: {
        // Note: the import of HueService here is necessary because Singletons are lazy-loaded in QML.
        console.log("HueService loaded with bridge:", HueService.pluginId);
    }

    component HueIcon: DankIcon {
        name: "lightbulb_2"
        size: Theme.barIconSize(root.barThickness, -4)
        color: {
            if (HueService.isError) return Theme.error
            if (root.isOpen) return Theme.primary
            return Theme.widgetIconColor || Theme.surfaceText
        }
    }

    component ViewToggleButton: Rectangle {
        property string iconName: ""
        property bool isActive: false
        signal clicked

        width: 36
        height: 36
        radius: Theme.cornerRadius
        color: isActive ? Theme.primaryHover : mouseArea.containsMouse ? Theme.surfaceHover : "transparent"

        DankIcon {
            anchors.centerIn: parent
            name: iconName
            size: 18
            color: isActive ? Theme.primary : Theme.surfaceText
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component RoomsView: Item {
        StyledText {
            anchors.centerIn: parent
            text: "Rooms View"
            color: Theme.surfaceText
        }
    }

    component LightsView: Item {
        StyledText {
            anchors.centerIn: parent
            text: "Lights View"
            color: Theme.surfaceText
        }
    }

    horizontalBarPill: Component {
        HueIcon {
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    verticalBarPill: Component {
        HueIcon {
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        FocusScope {
            implicitWidth: popoutColumn.implicitWidth
            implicitHeight: popoutColumn.implicitHeight
            focus: true

            Component.onCompleted: {
                Qt.callLater(() => {
                    root.isOpen = true
                    forceActiveFocus();
                })
            }

            Component.onDestruction: {
                root.isOpen = false
            }

            Column {
                id: popoutColumn
                spacing: 0
                width: parent.width

                Rectangle {
                    width: parent.width
                    height: 46
                    color: "transparent"

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            text: "Phillips Hue Lights"
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: HueService.isError ? "" : `Bridge IP: ${HueService.bridgeIP}, Rooms: ${HueService.rooms.length}`
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        ViewToggleButton {
                            iconName: "light_group"
                            isActive: root.activeView === "rooms"
                            onClicked: {
                                root.activeView = "rooms"
                            }
                        }

                        ViewToggleButton {
                            iconName: "floor_lamp"
                            isActive: root.activeView === "lights"
                            onClicked: {
                                root.activeView = "lights"
                            }
                        }
                    }
                }

                RoomsView {
                    width: parent.width
                    height: 400
                    visible: root.activeView === "rooms"
                }

                LightsView {
                    width: parent.width
                    height: 400
                    visible: root.activeView === "lights"
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 500
}
