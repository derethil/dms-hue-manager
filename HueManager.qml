import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import qs.Modules.ControlCenter.Widgets

PluginComponent {
    id: root
    layerNamespacePlugin: "hue-manager"

    property bool isOpen: false

    Component.onCompleted: {
        // Note: the import of HueService here is necessary because Singletons are lazy-loaded in QML.
        console.log("HueService loaded with bridge:", HueService.pluginId);
    }

    component HueIcon: DankIcon {
        name: "lightbulb_2"
        size: Theme.barIconSize(root.barThickness, -4)
        color: {
          if (HueService.isError) return Theme.error
          if (root.isOpen) return Theme.primary
          return Theme.widgetIconColor || Theme.surfaceText
        }
    }

    horizontalBarPill: Component {
      HueIcon {
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }

    verticalBarPill: Component {
      HueIcon {
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn

            Component.onCompleted: {
                root.isOpen = true
            }

            Component.onDestruction: {
                root.isOpen = false
            }

            headerText: "Phillips Hue Lights"
            showCloseButton: true

            detailsText: {
              if (HueService.isError) {
                return ""
              } else {
                return `Bridge IP: ${HueService.bridgeIP}, Rooms: ${HueService.rooms.length}`
              }

            }

            Loader {
                width: parent.width
                height: root.popoutHeight - popoutColumn.headerHeight - popoutColumn.detailsHeight - Theme.spacingXL
                sourceComponent: HueService.isError ? errorComponent : lightsComponent
            }

            Component {
                id: errorComponent

                Item {
                    StyledText {
                        anchors.centerIn: parent
                        text: HueService.errorMessage
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
