import QtQuick
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

    component HueIcon: DankIcon {
        name: "lightbulb_2"
        size: Theme.barIconSize(root.barThickness, -4)
        color: {
            if (HueService.isError)
                return Theme.error;
            if (root.isOpen)
                return Theme.primary;
            return Theme.widgetIconColor || Theme.surfaceText;
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
            size: Theme.iconSizeSmall
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

    component LightingItemHeader: StyledRect {
        id: lightingItemHeader
        property var entity: null
        property real leftIndent: Theme.spacingM
        width: parent.width
        height: 48
        radius: Theme.cornerRadius
        border.width: 0

        Rectangle {
            property var isActive: false

            anchors.left: parent.left
            width: Theme.iconSizeSmall * 2
            height: Theme.iconSizeSmall * 2
            color: mouseArea.containsMouse ? Theme.surfaceHover : "transparent"

            DankIcon {
                anchors.centerIn: parent
                name: "light_group"
                size: Theme.iconSize
                color: root.getEntityProperty(entity, "on") ? Theme.primary : Theme.surfaceText
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    toggleEntityPower(entity);
                }
            }
        }

        Column {
            anchors.right: parent.right

            StyledText {
                id: headerText
                text: entity.name
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }
        }
    }

    component RoomsView: Item {
        DankListView {
            id: roomsList
            width: parent.width
            height: root.popoutHeight - 46 - Theme.spacingM * 2
            model: HueService.rooms
            currentIndex: root.currentIndex

            delegate: Column {
                id: roomDelegate
                width: parent.width
                spacing: 0

                LightingItemHeader {
                    entity: modelData
                }
            }
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

                        ViewToggleButton {
                            iconName: "light_group"
                            isActive: root.activeView === "rooms"
                            onClicked: {
                                root.activeView = "rooms";
                            }
                        }

                        ViewToggleButton {
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
                    RoomsView {
                        anchors.fill: parent
                        visible: root.activeView === "rooms"
                    }

                    LightsView {
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
