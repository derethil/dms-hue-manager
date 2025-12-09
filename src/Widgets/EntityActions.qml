import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var entity
    required property bool expanded

    visible: root.opacity > 0
    opacity: root.expanded ? 1 : 0
    height: root.expanded ? implicitHeight : 0
    clip: true

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.shorterDuration
            easing.type: Theme.standardEasing
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Theme.shorterDuration
            easing.type: Theme.standardEasing
        }
    }

    StyledText {
        text: "Entity actions will go here."
    }
}
