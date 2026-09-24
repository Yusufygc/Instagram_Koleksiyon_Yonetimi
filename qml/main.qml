import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 900
    height: 650
    title: "Instagram Koleksiyonlarım"

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: loginPage
    }

    // --- Giriş Sayfası ---
    Component {
        id: loginPage
        Page {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                width: 300

                TextField { id: user; placeholderText: "Kullanıcı adı"; Layout.fillWidth: true }
                TextField { id: pass; placeholderText: "Şifre"; echoMode: TextInput.Password; Layout.fillWidth: true }

                Button {
                    text: "Giriş Yap"
                    Layout.fillWidth: true
                    onClicked: backend.login(user.text, pass.text)
                }

                Text { id: errorText; color: "red"; wrapMode: Text.Wrap; Layout.fillWidth: true }
            }

            Connections {
                target: backend
                function onLoggedIn(success) {
                    if (success) stack.push(collectionsPage)
                }
                function onError(msg) { errorText.text = msg }
            }
        }
    }

    // --- Koleksiyonlar Sayfası ---
    Component {
        id: collectionsPage
        Page {
            header: ToolBar { Label { text: "Koleksiyonlar"; font.bold: true } }

            ListView {
                anchors.fill: parent
                model: ListModel { id: collectionsModel }

                delegate: ItemDelegate {
                    width: parent.width
                    text: model.name
                    onClicked: {
                        backend.loadMedias(model.id)
                        stack.push(mediaPage, { collectionId: model.id, collectionName: model.name })
                    }
                }
            }

            Component.onCompleted: backend.loadCollections()

            Connections {
                target: backend
                function onCollectionsLoaded(list) {
                    collectionsModel.clear()
                    for (var i = 0; i < list.length; i++)
                        collectionsModel.append(list[i])
                }
            }
        }
    }

    // --- Medya Sayfası ---
    Component {
        id: mediaPage
        Page {
            property string collectionId
            property string collectionName

            header: ToolBar { Label { text: collectionName; font.bold: true } }

            ListView {
                anchors.fill: parent
                model: ListModel { id: mediaModel }

                delegate: RowLayout {
                    width: parent.width
                    spacing: 10

                    Image {
                        source: model.thumbnail
                        width: 100
                        height: 100
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    Text {
                        text: model.caption
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }

                    Button {
                        text: "Çıkar"
                        onClicked: backend.unsaveMedia(model.id, collectionId)
                    }
                }
            }

            Connections {
                target: backend
                function onMediasLoaded(list) {
                    mediaModel.clear()
                    for (var i = 0; i < list.length; i++)
                        mediaModel.append(list[i])
                }
            }
        }
    }
}