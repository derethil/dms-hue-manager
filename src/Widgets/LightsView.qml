pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root
    property int popoutHeight: 500
    property var lights: []

    DankListView {
        id: lightsList
        width: parent.width
        height: root.popoutHeight - 46 - Theme.spacingM * 2
        spacing: Theme.spacingM

        model: ScriptModel {
            values: root.lights
            objectProp: "entityId"
        }

        Component.onCompleted: {
            console.info(`${HueService.pluginId}: ListView completed with ${root.lights.length} lights.`);
        }

        delegate: Entity {}
    }
}
