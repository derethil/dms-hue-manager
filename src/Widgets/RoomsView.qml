pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root
    property int popoutHeight: 500
    property int currentIndex: 0
    property var rooms: []

    DankListView {
        id: roomsList
        width: parent.width
        height: root.popoutHeight - 46 - Theme.spacingM * 2
        currentIndex: parent.currentIndex
        spacing: Theme.spacingS

        model: ScriptModel {
            values: root.rooms
            objectProp: "entityId"
        }

        delegate: Column {
            id: roomDelegate
            required property var modelData

            width: root.width
            spacing: 0

            EntityHeader {
                entity: roomDelegate.modelData
            }
        }
    }
}
