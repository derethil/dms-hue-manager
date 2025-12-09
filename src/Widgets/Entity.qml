import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: root
    required property var modelData

    property bool isExpanded: false

    width: parent.width
    height: content.height
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh

    Column {
        id: content
        width: parent.width
        spacing: 0

        EntityHeader {
            entity: root.modelData
            expanded: root.isExpanded
            onToggleExpanded: {
                root.isExpanded = !root.isExpanded;
                console.error(root.isExpanded);
            }
        }

        Divider {
            variant: Divider.Variant.Horizontal
            visible: root.isExpanded
            opacity: root.isExpanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.shorterDuration
                    easing.type: Theme.standardEasing
                }
            }
        }

        EntityActions {
            entity: root.modelData
            expanded: root.isExpanded
        }
    }
}
