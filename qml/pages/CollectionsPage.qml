import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"
import "../dialogs"

Page {
    id: root
    property bool loading: false

    background: Rectangle { color: Theme.pageBg }
    header: AppToolBar { titleText: "Koleksiyonlarım" }

    DeleteCollectionDialog {
        id: deleteDialog
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        ErrorBanner {
            id: errorBanner
            onRetryClicked: root.reload()
        }

        BusyIndicator {
            running: root.loading
            visible: root.loading
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
        }

        Label {
            visible: !root.loading && collectionsModel.count === 0 && errorBanner.text.length === 0
            text: "Henüz kaydedilmiş koleksiyon bulunamadı."
            color: Theme.textMuted
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: !root.loading
            model: ListModel { id: collectionsModel }
            spacing: 10
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                width: 10
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: parent.pressed ? Theme.textMuted : "#C6C6CC"
                }
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: 64
                radius: 10
                color: hovered ? "#FAFAFB" : Theme.cardBg
                border.color: Theme.borderColor
                property bool hovered: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: {
                        backend.loadMedias(model.id)
                        root.StackView.view.push("MediaPage.qml", { collectionId: model.id, collectionName: model.name })
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Label {
                        text: model.name
                        font.pixelSize: 15
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Label {
                        text: model.count + " gönderi"
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }

                    ToolButton {
                        text: "🗑"
                        font.pixelSize: 15
                        onClicked: {
                            deleteDialog.pendingCollectionId = model.id
                            deleteDialog.pendingCollectionName = model.name
                            deleteDialog.open()
                        }
                    }

                    Label {
                        text: "›"
                        font.pixelSize: 20
                        color: Theme.textMuted
                    }
                }
            }
        }
    }

    function reload() {
        loading = true
        errorBanner.text = ""
        backend.loadCollections()
    }

    Component.onCompleted: reload()

    Connections {
        target: backend
        function onCollectionsLoaded(list) {
            loading = false
            collectionsModel.clear()
            for (var i = 0; i < list.length; i++)
                collectionsModel.append(list[i])
        }
        function onError(msg) {
            loading = false
            errorBanner.text = msg
        }
    }
}
