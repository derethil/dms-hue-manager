import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: root
    required property var modelData
    property var expandedEntityIds: new Set()
    property var setEntityExpanded: null

    property bool isExpanded: expandedEntityIds.has(modelData.entityId)

    signal viewLightsClicked(string roomId)

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
                const newExpandedState = !root.isExpanded;
                if (root.setEntityExpanded) {
                    root.setEntityExpanded(root.modelData.entityId, newExpandedState);
                }
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
            onViewLightsClicked: roomId => {
                root.viewLightsClicked(roomId);
            }
        }
    }
}
