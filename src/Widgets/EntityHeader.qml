import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: root

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
            color: root.entity.on ? Theme.primary : Theme.surfaceText
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.entity.togglePower();
            }
        }
    }

    Column {
        anchors.right: parent.right

        StyledText {
            id: headerText
            text: root.entity.name
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
        }
    }
}
