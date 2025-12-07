import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    required property string errorMessage

    StyledText {
        anchors.centerIn: parent
        text: root.errorMessage
        color: Theme.error
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        width: parent.width - Theme.spacingXL * 2
    }
}
