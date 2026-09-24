import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ".."

Dialog {
    id: root
    modal: true
    dim: true
    width: Math.min(360, (parent ? parent.width : 400) - 32)
    x: Math.round(((parent ? parent.width : 400) - width) / 2)
    y: Math.round(((parent ? parent.height : 300) - height) / 2)
    padding: 20

    property string pendingMediaId: ""
    property string collectionId: ""

    background: Rectangle {
        color: Theme.cardBg
        radius: 12
        border.color: Theme.borderColor
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: "Gönderiyi Çıkar"
                font.pixelSize: 16
                font.bold: true
                color: "#1A1A1A"
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: 13
                color: Theme.textMuted
                lineHeight: 1.2
                text: "Bu gönderi tüm kaydedilenlerinizden ve koleksiyonlarınızdan çıkarılacak."
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Button {
                text: "Vazgeç"
                flat: true
                onClicked: root.reject()
            }

            Button {
                text: "Çıkar"
                flat: true
                Material.foreground: Theme.dangerColor
                font.bold: true
                onClicked: root.accept()
            }
        }
    }

    onAccepted: backend.unsaveMedia(pendingMediaId, collectionId)
}
