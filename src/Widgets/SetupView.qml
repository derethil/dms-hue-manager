import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    Item {
        anchors.centerIn: parent
        width: 200
        height: 200

        Rectangle {
            id: pulsingRing
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: Theme.primary
            border.width: 4

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: true

                NumberAnimation {
                    from: 1.0
                    to: 0.3
                    duration: Theme.extraLongDuration
                    easing.type: Theme.standardEasing
                }

                NumberAnimation {
                    from: 0.3
                    to: 1.0
                    duration: Theme.extraLongDuration
                    easing.type: Theme.standardEasing
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: "Push the button on\nyour Hue Bridge"
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
