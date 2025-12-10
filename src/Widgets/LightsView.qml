import Quickshell
import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root
    property int popoutHeight: 500
    property var lights: []

    readonly property var lightsByRoom: {
        return root.lights.reduce((acc, light) => {
            const roomId = light.room?.id || "unknown";
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

        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            id: headerText
            text: roomView.roomName
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
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
