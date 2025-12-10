pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root
    property int popoutHeight: 500
    property var rooms: []

    DankListView {
        id: roomsList
        width: parent.width
        height: root.popoutHeight - 46 - Theme.spacingM * 2
        spacing: Theme.spacingM

        model: ScriptModel {
            values: root.rooms
            objectProp: "entityId"
        }

        Component.onCompleted: {
            console.info(`${HueService.pluginId}: ListView completed with ${root.rooms.length} rooms.`);
        }

        delegate: Entity {}
    }
}
