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
        model: root.rooms
        currentIndex: parent.currentIndex

        delegate: Column {
            id: roomDelegate
            required property var modelData

            width: parent.width
            spacing: 0

            EntityHeader {
                entity: roomDelegate.modelData
            }
        }
    }
}
