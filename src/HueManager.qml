pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Modules.Plugins
import "./Widgets"

PluginComponent {
    id: root
    layerNamespacePlugin: "hue-manager"

    property bool isOpen: false
    property string activeView: "rooms"

    property int currentIndex: 0

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

                Header {
                    headerHeight: popoutColumn.headerHeight
                    activeView: root.activeView
                    onViewChangeRequested: newView => {
                        root.activeView = newView;
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
                Error {
                    errorMessage: HueService.errorMessage
                }
            }

            Component {
                id: viewComponent

                Item {
                    RoomsView {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        width: parent.width
                        visible: root.activeView === "rooms"
                        popoutHeight: root.popoutHeight
                        currentIndex: root.currentIndex
                        rooms: HueService.rooms
                    }

                    LightsView {
                        anchors.margins: Theme.spacingM
                        anchors.fill: parent
                        visible: root.activeView === "lights"
                    }
                }
            }
        }
    }
}
