import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import "."

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    minimumWidth: 640
    minimumHeight: 480
    title: "Instagram Koleksiyonlarım"

    Material.theme: Material.Light
    Material.primary: Theme.primary
    Material.accent: Theme.accent

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: "pages/LoginPage.qml"
    }
}
