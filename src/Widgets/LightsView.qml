import Quickshell
import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root
    property int popoutHeight: 500
    property var lights: []
    property string filterToRoomId: ""

    signal clearFilterRequested

    readonly property var lightsByRoom: {
        return root.lights.reduce((acc, light) => {
            const roomId = light.room?.id || "unknown";

            if (filterToRoomId !== "" && roomId !== filterToRoomId) {
                return acc;
            }

            if (!acc.has(roomId)) {
                acc.set(roomId, {
                    roomId: roomId,
                    roomName: light.room?.name || "Unknown Room",
                    lights: []
                });
            }

            acc.get(roomId).lights.push(light);

            return acc;
        }, new Map());
    }

    component RoomLightsView: Column {
        id: roomView
        required property var modelData

        readonly property string roomId: modelData.roomId
        readonly property string roomName: modelData.roomName
        readonly property var lights: modelData.lights

        width: parent ? parent.width : 0
        spacing: Theme.spacingS

        Item {
            width: parent.width
            height: Math.max(headerText.implicitHeight, clearButton.height)

            StyledText {
                id: headerText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: roomView.roomName
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
            }

            Rectangle {
                id: clearButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSize
                height: Theme.iconSize
                radius: Theme.cornerRadius
                color: clearMouseArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                visible: root.filterToRoomId !== ""

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.shorterDuration
                        easing.type: Theme.standardEasing
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: Theme.iconSizeSmall
                    color: Theme.surfaceText
                }

                MouseArea {
                    id: clearMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.clearFilterRequested();
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: Theme.spacingM

            Repeater {
                model: roomView.lights
                delegate: Entity {}
            }
        }
    }

    DankListView {
        id: lightsList
        width: parent.width
        height: root.popoutHeight - 46 - Theme.spacingM * 2
        spacing: Theme.spacingL

        header: Item {
            height: Theme.spacingXS
        }

        model: ScriptModel {
            values: Array.from(root.lightsByRoom.values())
            objectProp: "roomId"
        }

        delegate: RoomLightsView {}
    }
}
