pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import "./Widgets"

PluginComponent {
    id: root
    layerNamespacePlugin: "hue-manager"

    property bool isOpen: false
    property string activeView: "rooms"
    property string lightFilterRoomId: ""
    property var expandedEntityIds: new Set()
    property int slideDuration: Theme.shortDuration

    function setEntityExpanded(entityId, isExpanded) {
        const newSet = new Set(root.expandedEntityIds);
        if (isExpanded) {
            newSet.add(entityId);
        } else {
            newSet.delete(entityId);
        }
        root.expandedEntityIds = newSet;  // Reassign to trigger QML reactivity
    }

    popoutWidth: 350
    popoutHeight: 500

    Component.onCompleted: {
        // Note: the import of HueService here is necessary because Singletons are lazy-loaded in QML.
        console.log("HueService loaded with bridge:", HueService.pluginId);
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
                root.isOpen = true;
                forceActiveFocus();
            }

            Component.onDestruction: {
                root.isOpen = false;

                Qt.callLater(() => {
                    if (!HueService.preserveWidgetStateOnNextOpen) {
                        root.lightFilterRoomId = "";
                        root.activeView = "rooms";
                        root.expandedEntityIds = new Set();
                    }
                    HueService.preserveWidgetStateOnNextOpen = false;
                });
            }

            Column {
                id: popoutColumn
                spacing: 0
                width: parent.width

                property int headerHeight: 46

                Header {
                    headerHeight: popoutColumn.headerHeight
                    activeView: root.activeView
                    onViewChangeRequested: newView => {
                        root.activeView = newView;
                        if (newView === "lights") {
                            root.lightFilterRoomId = "";
                        }
                    }
                }

                Loader {
                    width: parent.width
                    height: root.popoutHeight - popoutColumn.headerHeight

                    sourceComponent: {
                        if (HueService.isError) {
                            return errorComponent;
                        } else if (HueService.isReady) {
                            return viewComponent;
                        } else {
                            return setupComponent;
                        }
                    }
                }
            }

            Component {
                id: setupComponent
                SetupView {}
            }

            Component {
                id: errorComponent
                Error {
                    errorMessage: HueService.errorMessage
                }
            }

            Component {
                id: viewComponent

                SwipeView {
                    id: swipeView
                    currentIndex: root.activeView === "rooms" ? 0 : 1

                    Component.onCompleted: {
                        contentItem.highlightMoveDuration = root.slideDuration;
                    }

                    onCurrentIndexChanged: {
                        root.activeView = currentIndex === 0 ? "rooms" : "lights";
                    }

                    Timer {
                        id: clearFilterTimer
                        interval: root.slideDuration
                        onTriggered: {
                            root.lightFilterRoomId = "";
                        }
                    }

                    Item {
                        RoomsView {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            popoutHeight: root.popoutHeight
                            rooms: Array.from(HueService.rooms.values())
                            expandedEntityIds: root.expandedEntityIds
                            setEntityExpanded: root.setEntityExpanded
                            onRoomSelected: roomId => {
                                root.lightFilterRoomId = roomId;
                                root.activeView = "lights";
                            }
                        }
                    }

                    Item {
                        LightsView {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            popoutHeight: root.popoutHeight
                            lights: Array.from(HueService.lights.values())
                            filterToRoomId: root.lightFilterRoomId
                            expandedEntityIds: root.expandedEntityIds
                            setEntityExpanded: root.setEntityExpanded
                            onBackRequested: {
                                root.activeView = "rooms";
                                clearFilterTimer.start();
                            }
                        }
                    }
                }
            }
        }
    }
}
