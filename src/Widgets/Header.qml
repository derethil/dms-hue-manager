import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property int headerHeight
    required property string activeView

    signal viewChangeRequested(newView: string)

    width: parent.width
    height: root.headerHeight
    color: "transparent"

    Column {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter

        StyledText {
            text: "Philips Hue Lights"
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.surfaceText
        }

        StyledText {
            text: {
                if (HueService.isError) {
                    return `Error: ${HueService.errorMessage}`;
                } else {
                    return `Bridge IP: ${HueService.bridgeIP}, Rooms: ${HueService.rooms.length}`;
                }
            }
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }

    Row {
        id: viewToggleRow
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS
        visible: !HueService.isError

        ViewToggleButton {
            iconName: "light_group"
            isActive: root.activeView === "rooms"
            onClicked: {
                root.viewChangeRequested("rooms");
            }
        }

        ViewToggleButton {
            iconName: "floor_lamp"
            isActive: root.activeView === "lights"
            onClicked: {
                root.viewChangeRequested("lights");
            }
        }
    }
}
