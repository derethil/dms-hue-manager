import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.DCommon.Widgets as DCommon
import "../utils/ScenePalette.js" as ScenePalette
import "../utils/ScenePages.js" as ScenePages

Column {
    id: root

    required property var entity
    property int pageIndex: 0
    readonly property var scenes: entity.scenes || []
    readonly property int pageCount: ScenePages.pageCount(scenes)
    spacing: Theme.spacingS

    onEntityChanged: pageIndex = 0
    onPageCountChanged: pageIndex = Math.max(0, Math.min(pageIndex, pageCount - 1))

    RowLayout {
        width: parent.width
        DCommon.StyledText {
            text: I18n.trFor("hueManager", "Scenes")
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
            Layout.fillWidth: true
        }
        Row {
            visible: root.pageCount > 1
            spacing: Theme.spacingXS
            DCommon.DActionButton {
                iconName: "chevron_left"
                tooltipText: I18n.trFor("hueManager", "Previous scenes")
                enabled: root.pageIndex > 0
                onClicked: root.pageIndex--
            }
            DCommon.StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: (root.pageIndex + 1) + " / " + root.pageCount
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
            }
            DCommon.DActionButton {
                iconName: "chevron_right"
                tooltipText: I18n.trFor("hueManager", "Next scenes")
                enabled: root.pageIndex + 1 < root.pageCount
                onClicked: root.pageIndex++
            }
        }
    }

    GridLayout {
        id: grid
        width: parent.width
        columns: 4
        columnSpacing: Theme.spacingS
        rowSpacing: Theme.spacingS

        Repeater {
            model: ScenePages.slots(root.scenes, root.pageIndex)

            DCommon.StyledButton {
                id: tile
                required property var modelData
                objectName: modelData ? "hueScene_" + modelData.id : "hueSceneEmpty"
                enabled: modelData !== null
                opacity: modelData ? 1 : 0
                Accessible.ignored: modelData === null
                readonly property bool selected: !!modelData && root.entity.activeScene?.id === modelData.id
                readonly property var previewColors: modelData ? ScenePalette.colors(modelData) : []
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                Layout.preferredHeight: Theme.iconSize * 2 + Theme.fontSizeSmall * 2 + Theme.spacingM * 2
                padding: Theme.spacingS
                radius: Theme.cornerRadius
                color: selected ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                border.color: selected ? Theme.primary : Theme.outlineVariant
                border.width: selected ? 2 : 1
                checkable: true
                checked: selected
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData?.name || ""
                Accessible.description: I18n.trFor("hueManager", "Activate scene")
                onClicked: {
                    if (modelData)
                        root.entity.activateScene(modelData.id);
                }

                contentItem: Column {
                    spacing: Theme.spacingXS

                    Item {
                        width: parent.width
                        height: Theme.iconSize * 2

                        DCommon.DColorSwatch {
                            id: swatch
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.height
                            height: width
                            swatchColor: tile.previewColors[0] || Theme.primary
                            secondaryColor: tile.previewColors[1] || swatchColor
                            tertiaryColor: tile.previewColors[2] || secondaryColor
                            ringColor: tile.selected ? Theme.primary : Theme.outlineVariant
                        }

                        Rectangle {
                            visible: tile.selected
                            anchors.top: swatch.top
                            anchors.right: swatch.right
                            width: Theme.iconSizeSmall + Theme.spacingXS
                            height: width
                            radius: width / 2
                            color: Theme.primary

                            DCommon.DIcon {
                                anchors.centerIn: parent
                                name: "check"
                                size: Theme.iconSizeSmall
                                color: Theme.primaryText
                            }
                        }
                    }

                    DCommon.StyledText {
                        width: parent.width
                        text: tile.modelData?.name || ""
                        textFormat: Text.PlainText
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                DCommon.StateLayer {
                    control: tile
                    stateColor: Theme.surfaceText
                    tooltipText: tile.modelData?.name || ""
                }

                DCommon.FocusRing {
                    visible: tile.visualFocus
                }
            }
        }
    }
}
