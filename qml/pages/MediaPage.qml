import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"
import "../dialogs"

Page {
    id: root
    property string collectionId
    property string collectionName
    property bool loading: false

    background: Rectangle { color: Theme.pageBg }

    header: AppToolBar {
        titleText: root.collectionName
        showBack: true
        onBackClicked: root.StackView.view.pop()
    }

    PreviewDialog {
        id: previewDialog
        anchors.centerIn: parent
        collectionId: root.collectionId
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
            visible: !root.loading && mediaModel.count === 0 && errorBanner.text.length === 0
            text: "Bu koleksiyonda gönderi bulunamadı."
            color: Theme.textMuted
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
        }

        // Instagram'daki gibi kare kutucuklardan oluşan grid; detay ve
        // aksiyonlar (tarayıcıda aç / çıkar) tıklanınca açılan önizlemede.
        GridView {
            id: mediaGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: !root.loading
            model: ListModel { id: mediaModel }
            boundsBehavior: Flickable.StopAtBounds

            readonly property int columns: Math.max(2, Math.floor(width / 280))
            cellWidth: width / columns
            // Instagram'ın azami gönderi oranı 4:5; çoğu gönderi bu civarda
            // olduğundan 9:16 yerine bu oran kullanılınca kırpma çok azalır.
            cellHeight: cellWidth * 5 / 4

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                width: 10
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: parent.pressed ? Theme.textMuted : "#C6C6CC"
                }
            }

            delegate: Item {
                width: mediaGrid.cellWidth
                height: mediaGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 8
                    color: "#EEEEF0"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: model.thumbnail
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true

                        BusyIndicator {
                            anchors.centerIn: parent
                            running: parent.status === Image.Loading
                            visible: running
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "🖼"
                            font.pixelSize: 28
                            color: Theme.textMuted
                            visible: parent.status === Image.Error || model.thumbnail.length === 0
                        }
                    }

                    Rectangle {
                        visible: model.mediaType === 2 || model.mediaType === 8
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: badgeLabel.implicitWidth + 10
                        height: badgeLabel.implicitHeight + 6
                        radius: height / 2
                        color: "#00000099"

                        Label {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: model.mediaType === 2 ? "▶" : "📑"
                            color: "white"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: previewDialog.showFor({
                            id: model.id,
                            preview: model.preview,
                            videoUrl: model.videoUrl,
                            mediaType: model.mediaType,
                            resources: model.resources,
                            permalink: model.permalink,
                            caption: model.caption
                        })
                    }
                }
            }
        }
    }

    function reload() {
        loading = true
        errorBanner.text = ""
        backend.loadMedias(collectionId)
    }

    Component.onCompleted: loading = true

    Connections {
        target: backend
        function onMediasLoaded(list) {
            loading = false
            mediaModel.clear()
            for (var i = 0; i < list.length; i++)
                mediaModel.append(list[i])
        }
        function onError(msg) {
            loading = false
            errorBanner.text = msg
        }
    }
}
