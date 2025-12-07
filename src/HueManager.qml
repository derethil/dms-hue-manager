import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import qs.Modules.ControlCenter.Widgets
import "./Widgets"

PluginComponent {
    id: root
    layerNamespacePlugin: "hue-manager"

    property bool isOpen: false
    property string activeView: "rooms"

    property int currentIndex: 0
    property var pendingChanges: ({})

    Component.onCompleted: {
        // Note: the import of HueService here is necessary because Singletons are lazy-loaded in QML.
        console.log("HueService loaded with bridge:", HueService.pluginId);
    }

    Connections {
        target: HueService
        function onRoomsChanged() {
            root.pendingChanges = ({});
        }
    }

    function setPendingChange(entity, propertyName, value) {
        if (!pendingChanges[entity.id]) {
            pendingChanges[entity.id] = {};
        }
        pendingChanges[entity.id][propertyName] = value;
        pendingChangesChanged();
    }

    function getEntityProperty(entity, propertyName) {
        if (pendingChanges[entity.id] && pendingChanges[entity.id][propertyName] !== undefined) {
            return pendingChanges[entity.id][propertyName];
        }
        return entity[propertyName];
    }

    function toggleEntityPower(entity) {
        setPendingChange(entity, "on", !entity.on);
        HueService.setEntityPower(entity, !entity.on);
    }

    function setEntityBrightness(entity, brightness) {
        setPendingChange(entity, "dimming", brightness);
        HueService.setEntityBrightness(entity, brightness);
    }

    horizontalBarPill: Component {
        HueIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            isOpen: root.isOpen
            barThickness: root.barThickness
            isError: HueService.isError
        }
    }

    verticalBarPill: Component {
        HueIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            isOpen: root.isOpen
            barThickness: root.barThickness
            isError: HueService.isError
        }
    }

    popoutContent: Component {
        FocusScope {
            implicitWidth: popoutColumn.implicitWidth
            implicitHeight: popoutColumn.implicitHeight
            focus: true

            Component.onCompleted: {
                Qt.callLater(() => {
                    root.isOpen = true;
                    forceActiveFocus();
                });
            }

            Component.onDestruction: {
                root.isOpen = false;
            }

            Column {
                id: popoutColumn
                spacing: 0
                width: parent.width

                property int headerHeight: 46

                Rectangle {
                    width: parent.width
                    height: popoutColumn.headerHeight
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
                        id: viewToggleRow
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS
                        visible: !HueService.isError

                        HueViewToggleButton {
                            iconName: "light_group"
                            isActive: root.activeView === "rooms"
                            onClicked: {
                                root.activeView = "rooms";
                            }
                        }

                        HueViewToggleButton {
                            iconName: "floor_lamp"
                            isActive: root.activeView === "lights"
                            onClicked: {
                                root.activeView = "lights";
                            }
                        }
                    }
                }

                Loader {
                    width: parent.width
                    height: root.popoutHeight - popoutColumn.headerHeight
                    sourceComponent: HueService.isError ? errorComponent : viewComponent
                }
            }

            Component {
                id: errorComponent

                Item {
                    StyledText {
                        anchors.centerIn: parent
                        text: HueService.errorMessage
                        color: Theme.error
                        font.pixelSize: Theme.fontSizeLarge
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width - Theme.spacingXL * 2
                    }
                }
            }

            Component {
                id: viewComponent

                Item {
                    HueRoomsView {
                        anchors.fill: parent
                        visible: root.activeView === "rooms"
                        popoutHeight: root.popoutHeight
                        currentIndex: root.currentIndex
                        rooms: HueService.rooms
                        getEntityProperty: root.getEntityProperty
                        toggleEntityPower: root.toggleEntityPower
                    }

                    HueLightsView {
                        anchors.fill: parent
                        visible: root.activeView === "lights"
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 500
}
