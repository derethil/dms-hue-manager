import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property string iconName
    property bool isActive: false
    signal clicked

    width: 36
    height: 36
    radius: Theme.cornerRadius
    color: isActive ? Theme.primaryHover : mouseArea.containsMouse ? Theme.surfaceHover : "transparent"

    DankIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: Theme.iconSizeSmall
        color: root.isActive ? Theme.primary : Theme.surfaceText
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.clicked()
    }
}
