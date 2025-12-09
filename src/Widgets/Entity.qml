import QtQuick

Column {
    id: root
    required property var modelData

    property bool isExpanded: false

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

    EntityActions {
        entity: root.modelData
        expanded: root.isExpanded
    }
}
