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
        anchors.leftMargin: Theme.spacingS
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
                } else if (HueService.isReady) {
                    return `Bridge IP: ${HueService.bridgeIP}`;
                } else {
                    return "Pairing...";
                }
            }
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }

    Row {
        id: viewToggleRow
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS
        visible: HueService.isReady

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
