import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Page {
    id: root
    background: Rectangle { color: Theme.pageBg }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0
        width: Math.min(360, parent.width - 48)

        Label {
            text: "Instagram Koleksiyonlarım"
            font.pixelSize: 24
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.bottomMargin: 4
        }

        Label {
            text: "Kaydettiğin koleksiyonları yönet"
            color: Theme.textMuted
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.bottomMargin: 28
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: card.implicitHeight + 32
            color: Theme.cardBg
            radius: 12
            border.color: Theme.borderColor

            ColumnLayout {
                id: card
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                TextField {
                    id: user
                    placeholderText: "Kullanıcı adı"
                    text: envUsername
                    Layout.fillWidth: true
                    selectByMouse: true
                }
                TextField {
                    id: pass
                    placeholderText: "Şifre"
                    text: envPassword
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    selectByMouse: true
                    Keys.onReturnPressed: loginButton.clicked()
                }

                CheckBox {
                    id: rememberCheck
                    text: "Beni hatırla"
                    Layout.fillWidth: true
                }

                Button {
                    id: loginButton
                    text: loginBusy ? "Giriş yapılıyor…" : "Giriş Yap"
                    enabled: !loginBusy
                    highlighted: true
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    property bool loginBusy: false
                    onClicked: {
                        errorBanner.text = ""
                        loginBusy = true
                        backend.login(user.text, pass.text, rememberCheck.checked)
                    }

                    BusyIndicator {
                        anchors.centerIn: parent
                        visible: loginButton.loginBusy
                        running: visible
                        width: 20
                        height: 20
                    }
                }

                ErrorBanner {
                    id: errorBanner
                    onRetryClicked: loginButton.clicked()
                }
            }
        }
    }

    Component.onCompleted: {
        // .env test bilgisi yoksa güvenli depodaki kayıtlı girişi dene
        if (envUsername.length === 0) {
            var creds = backend.loadSavedCredentials()
            user.text = creds[0]
            pass.text = creds[1]
            rememberCheck.checked = creds[2]
        }
    }

    Connections {
        target: backend
        function onLoggedIn(success) {
            loginButton.loginBusy = false
            if (success) root.StackView.view.push("CollectionsPage.qml")
        }
        function onError(msg) {
            loginButton.loginBusy = false
            errorBanner.text = msg
        }
    }
}
