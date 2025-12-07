import QtQuick
import qs.Common
import qs.Widgets

DankIcon {
    property bool isOpen: false
    property int barThickness: 0
    property bool isError: false

    name: "lightbulb_2"
    size: Theme.barIconSize(barThickness, -4)
    color: {
        if (isError)
            return Theme.error;
        if (isOpen)
            return Theme.primary;
        return Theme.widgetIconColor || Theme.surfaceText;
    }
}
