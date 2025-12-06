import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    layerNamespacePlugin: "hue-manager"

    // Internal State
    property bool isError: false
    property string errorMessage: ""

    // Hue State
    property string bridgeIP: ""

    Component.onCompleted: {
        checkSetup()
    }

    function checkSetup() {
        Proc.runCommand(null, ["openhue", "get"], (output, exitCode) => {
            if (output.trim().includes("please run the 'setup' command")) {
              root.isError = true
              root.errorMessage = "OpenHue is not set up. Please set up your Hue Bridge with 'openhue setup'."
            } else {
              root.isError = false
              root.getHueBridgeIP()
            }
        })
    }

    function getHueBridgeIP() {
      Proc.runCommand(null, ["openhue", "discover"], (output, exitCode) => {
          if (exitCode === 0) {
            root.bridgeIP = output.trim()
          } else {
            root.bridgeIP = "Unknown"
          }
      })
    }

    horizontalBarPill: Component {
        DankIcon {
          name: "light"
          size: Theme.barIconSize(root.barThickness, -4)
          color: Theme.surfaceText
          anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    verticalBarPill: Component {
        DankIcon {
          name: "light"
          size: Theme.barIconSize(root.barThickness, -4)
          color: Theme.surfaceText
          anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn

            headerText: "Phillips Hue Lights"
            detailsText: "Manage your smart lights directly on your desktop"
            showCloseButton: true

            Loader {
                width: parent.width
                height: root.popoutHeight - popoutColumn.headerHeight - popoutColumn.detailsHeight - Theme.spacingXL
                sourceComponent: root.isError ? errorComponent : lightsComponent
            }

            Component {
                id: errorComponent

                Item {
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
            }

            Component {
                id: lightsComponent

                Item {
                    StyledText {
                        anchors.centerIn: parent
                        text: "Light control will go here!"
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 500
}
