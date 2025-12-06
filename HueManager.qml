import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "emoji-launcher"

    property var displayedEmojis: ["😊", "😢", "❤️"]

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            Repeater {
                model: root.displayedEmojis
                StyledText {
                    text: modelData
                    font.pixelSize: Theme.fontSizeLarge
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            Repeater {
                model: root.displayedEmojis
                StyledText {
                    text: modelData
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn

            headerText: "Emoji Picker"
            detailsText: "Click an emoji to copy it"
            showCloseButton: true

            property var allEmojis: [
                "😀", "😃", "😄", "😁", "😆", "🤣",
                "❤️", "🧡", "💛", "💚", "💙", "💜"
            ]

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popoutColumn.headerHeight -
                               popoutColumn.detailsHeight - Theme.spacingXL

                DankGridView {
                    anchors.fill: parent
                    cellWidth: 50
                    cellHeight: 50
                    model: popoutColumn.allEmojis

                    delegate: StyledRect {
                        width: 45
                        height: 45
                        radius: Theme.cornerRadius
                        color: emojiMouse.containsMouse ?
                               Theme.surfaceContainerHighest :
                               Theme.surfaceContainerHigh

                        StyledText {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Theme.fontSizeXLarge
                        }

                        MouseArea {
                            id: emojiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                Quickshell.execDetached(["sh", "-c",
                                    "echo -n '" + modelData + "' | wl-copy"])
                                ToastService.showInfo("Copied " + modelData)
                                popoutColumn.closePopout()
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 500
}
