import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ".."

ToolBar {
    id: toolBar
    property string titleText: ""
    property bool showBack: false
    signal backClicked()

    Material.foreground: "white"
    background: Rectangle {
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 1.0; color: Theme.accent }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 12
        spacing: 4

        ToolButton {
            text: "←"
            visible: toolBar.showBack
            font.pixelSize: 20
            Layout.preferredWidth: visible ? implicitWidth : 0
            onClicked: toolBar.backClicked()
        }

        Label {
            text: toolBar.titleText
            color: "white"
            font.pixelSize: 18
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
