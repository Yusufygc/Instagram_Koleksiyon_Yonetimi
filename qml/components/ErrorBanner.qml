import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: banner
    property alias text: msg.text
    signal retryClicked()

    visible: text.length > 0
    color: "#FDECEA"
    border.color: "#F5C2BE"
    radius: 6
    implicitHeight: visible ? row.implicitHeight + 16 : 0
    Layout.fillWidth: true

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Label {
            id: msg
            color: "#611A15"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Button {
            text: "Tekrar Dene"
            flat: true
            onClicked: banner.retryClicked()
        }
    }
}
