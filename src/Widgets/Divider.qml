import QtQuick
import qs.Common

Rectangle {
    id: divider

    enum Variant {
        Horizontal,
        Vertical
    }

    property int variant: Divider.Variant.Horizontal
    property color dividerColor: Theme.outlineMedium
    property real widthPercent: 0.9

    width: variant === Divider.Variant.Horizontal ? parent.width * widthPercent : 1
    height: variant === Divider.Variant.Horizontal ? 1 : parent.height * widthPercent

    color: dividerColor

    anchors.horizontalCenter: variant === Divider.Variant.Horizontal ? parent.horizontalCenter : undefined
    anchors.verticalCenter: variant === Divider.Variant.Vertical ? parent.verticalCenter : undefined
}
