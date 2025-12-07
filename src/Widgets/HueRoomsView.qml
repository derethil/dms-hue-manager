import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root
    property int popoutHeight: 500
    property int currentIndex: 0
    property var rooms: []
    property var getEntityProperty: null
    property var toggleEntityPower: null

    DankListView {
        id: roomsList
        width: parent.width
        height: popoutHeight - 46 - Theme.spacingM * 2
        model: rooms
        currentIndex: parent.currentIndex

        delegate: Column {
            id: roomDelegate
            width: parent.width
            spacing: 0

            HueLightingItemHeader {
                entity: modelData
                getEntityProperty: root.getEntityProperty
                toggleEntityPower: root.toggleEntityPower
            }
        }
    }
}
