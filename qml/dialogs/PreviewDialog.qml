import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ".."
import "../components"

// Gönderi önizlemesi: medya solda tam boyutta (kırpılmadan, orijinal
// çözünürlükte), açıklama ve aksiyonlar sağda ayrı bir panelde gösterilir.
// Not: Popup açılmadan önce Window attached property güvenilir çözülmez,
// bu yüzden boyut için (Overlay'e yeniden ebeveynlenmeden önceki) parent
// referans alınır.
Dialog {
    id: root
    title: "Gönderi Önizleme"
    modal: true

    // Manuel x/y ile sağ üst köşeye konumlamak Popup'ın kendi padding/başlık
    // alanına göre kaymaya yol açıyordu; bunun yerine X butonu Dialog'un
    // kendi header'ının bir parçası yapılır, böylece her zaman gerçek sağ
    // üst köşede kalır.
    header: Item {
        implicitHeight: headerRow.implicitHeight + 24

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Label {
                text: root.title
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            RoundButton {
                text: "✕"
                font.pixelSize: 14
                flat: true
                onClicked: root.close()
            }
        }
    }

    // Reels/video neredeyse hep dikey (9:16); fotoğraf ve carousel gönderileri
    // ise Instagram'ın azami oranı olan 4:5'e (veya daha geniş/kareye) daha
    // yakındır. Videoyu dar tutup yatay siyah boşluğu önlerken, foto/carousel
    // içeriğini fazla daraltıp küçültmemek (okunaksız hale getirmemek) için
    // medya tipine göre farklı oran kullanılır.
    readonly property real aspectRatio: mediaType === 2 ? (9 / 16) : (4 / 5)
    readonly property real availablePanelHeight: Math.min(680, (parent ? parent.height : 720) - 100)
    readonly property real sidePanelWidth: 300
    readonly property real mediaWidth: Math.min(
        availablePanelHeight * aspectRatio,
        (parent ? parent.width : 1000) - 40 - sidePanelWidth - 48
    )

    width: Math.min(mediaWidth + sidePanelWidth + 48, (parent ? parent.width : 1000) - 40)
    height: availablePanelHeight + 100

    property string previewUrl: ""
    property string videoUrl: ""
    property int mediaType: 1
    property var resources: []
    property string permalink: ""
    property string caption: ""
    property string mediaId: ""
    property string collectionId: ""
    property string ocrResult: ""
    property bool ocrBusy: false
    property bool isAreaOcr: false
    property bool frameCapturing: false  // video karesi yakalanıp gösterilirken

    onClosed: {
        // Diyalog kapanınca kaynakları boşalt (arka planda ses/video akmasın)
        previewUrl = ""
        videoUrl = ""
        resources = []
        ocrResult = ""
        ocrBusy = false
        isAreaOcr = false
        frameCapturing = false
        viewer.selectionMode = false
    }

    function showFor(item) {
        previewUrl = item.preview
        videoUrl = item.videoUrl
        mediaType = item.mediaType
        resources = item.resources
        permalink = item.permalink
        caption = item.caption
        mediaId = item.id
        ocrResult = ""
        ocrBusy = false
        isAreaOcr = false
        frameCapturing = false
        viewer.selectionMode = false
        open()
    }

    // Görsel varsa tamamını, yoksa (video) o an duraklatılmış kareyi tarar.
    // Hangi kaynağın kullanılacağına TIKLAMA ANINDA karar verilir; veri
    // katmanındaki olası eksiklere karşı viewer'ın gerçekten yüklediği
    // kaynağı da yedek olarak dener (bestImageUrl/bestVideoUrl).
    function runAutoOcr() {
        viewer.selectionMode = false
        var img = viewer.bestImageUrl()
        if (img.length > 0) {
            isAreaOcr = false
            ocrBusy = true
            ocrResult = ""
            backend.recognizeTextInRegion(img, 0.0, 0.0, 1.0, 1.0)
            return
        }
        var vid = viewer.bestVideoUrl()
        if (vid.length > 0) {
            viewer.pauseActiveVideo()
            isAreaOcr = false
            ocrBusy = true
            ocrResult = ""
            backend.recognizeTextInVideoFrame(vid, viewer.currentVideoPositionMs / 1000.0)
            return
        }
        ocrResult = "Taranacak bir görsel/video bulunamadı."
    }

    UnsaveConfirmDialog {
        id: unsaveConfirmDialog
        pendingMediaId: root.mediaId
        collectionId: root.collectionId
    }

    Connections {
        // UnsaveConfirmDialog kendi onAccepted'ında zaten backend.unsaveMedia
        // çağırıyor; burada onu EZMEDEN (onAccepted: doğrudan ata mak
        // üzerine yazardı) ayrıca önizlemeyi kapatmak için Connections
        // kullanılır.
        target: unsaveConfirmDialog
        function onAccepted() { root.close() }
    }

    Connections {
        target: backend
        function onTextRecognized(text) {
            if (!root.ocrBusy) return  // bu diyalogla ilgisiz bir OCR sonucu olabilir
            root.ocrBusy = false
            root.ocrResult = text
        }
        function onVideoFrameCaptured(path) {
            if (!root.frameCapturing) return  // bu diyalogla ilgisiz bir yakalama olabilir
            root.frameCapturing = false
            viewer.capturedFrameUrl = path
            viewer.selectionMode = true
        }
        function onError(msg) {
            if (root.frameCapturing) {
                root.frameCapturing = false
                root.ocrResult = "Kare yakalanamadı: " + msg
                return
            }
            if (!root.ocrBusy) return  // başka bir işlemden gelen hata olabilir
            root.ocrBusy = false
            root.ocrResult = "Metin tanınamadı: " + msg
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        MediaViewer {
            id: viewer
            Layout.fillHeight: true
            Layout.preferredWidth: root.mediaWidth
            radius: 8
            active: root.visible
            mediaType: root.mediaType
            photoUrl: root.previewUrl
            videoUrl: root.videoUrl
            resources: root.resources

            onRegionSelected: function(sourceUrl, nx, ny, nw, nh) {
                root.isAreaOcr = true
                root.ocrBusy = true
                root.ocrResult = ""
                backend.recognizeTextInRegion(sourceUrl, nx, ny, nw, nh)
            }

            onInvalidRegionSelected: function() {
                root.ocrResult = "Geçersiz seçim: Lütfen doğrudan görsel/video üzerindeki metin alanını fare ile sürükleyerek seçin."
            }
        }

        ColumnLayout {
            Layout.preferredWidth: root.sidePanelWidth
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Açıklama"
                    font.bold: true
                    font.pixelSize: 14
                    color: Theme.textMuted
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "⧉"
                    font.pixelSize: 14
                    enabled: root.caption.length > 0
                    ToolTip.visible: hovered
                    ToolTip.text: "Açıklamayı kopyala"
                    onClicked: {
                        captionEdit.selectAll()
                        captionEdit.copy()
                        captionEdit.deselect()
                    }
                }
            }

            ScrollView {
                id: captionScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextEdit {
                    id: captionEdit
                    // Genişlik doğrudan ScrollView'a bağlanır (parent.width
                    // burada dairesel/tanımsız kalıp yatay taşmaya yol açardı)
                    width: captionScroll.availableWidth
                    text: root.caption.length > 0 ? root.caption : "(Açıklama yok)"
                    wrapMode: Text.Wrap
                    color: root.caption.length > 0 ? "black" : Theme.textMuted
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                }
            }

            // OCR: her zaman tıklanabilir (gönderide görünen içeriğin veri
            // katmanı bazen eksik/gecikmeli olabilir; buton bu yüzden asla
            // kilitlenmez). Metin bulunamazsa backend zaten "bulunamadı" der.
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: (root.ocrBusy && !root.isAreaOcr) ? "Taranıyor…" : "Otomatik Tara (OCR)"
                    flat: true
                    Layout.fillWidth: true
                    enabled: !root.ocrBusy && !root.frameCapturing
                    onClicked: root.runAutoOcr()
                }

                Button {
                    text: {
                        if (root.frameCapturing) return "Kare yakalanıyor…"
                        if (root.ocrBusy && root.isAreaOcr) return "Alan taranıyor…"
                        if (viewer.selectionMode) return "İptal"
                        return "Alan Seçerek Tara"
                    }
                    flat: true
                    Layout.fillWidth: true
                    enabled: !root.ocrBusy && !root.frameCapturing
                    onClicked: {
                        if (viewer.selectionMode) {
                            viewer.selectionMode = false
                            return
                        }
                        var img = viewer.bestImageUrl()
                        if (img.length > 0) {
                            // Fotoğraf/carousel-foto: doğrudan üzerinde seçim yapılır.
                            viewer.selectionMode = true
                            return
                        }
                        var vid = viewer.bestVideoUrl()
                        if (vid.length === 0) {
                            root.ocrResult = "Taranacak bir görsel/video bulunamadı."
                            return
                        }
                        // Video: canlı görüntü üzerinde piksel-doğru seçim yapılamaz;
                        // önce mevcut kareyi yakalayıp durağan görsel olarak göster.
                        viewer.pauseActiveVideo()
                        root.frameCapturing = true
                        root.ocrResult = ""
                        backend.captureVideoFrame(vid, viewer.currentVideoPositionMs / 1000.0)
                    }
                }
            }

            RowLayout {
                visible: root.ocrBusy
                Layout.fillWidth: true
                spacing: 8

                BusyIndicator {
                    running: root.ocrBusy
                    implicitWidth: 24
                    implicitHeight: 24
                }

                Label {
                    text: root.isAreaOcr ? "Seçilen alan taranıyor…" : "Görsel taranıyor…"
                    color: Theme.primary
                    font.pixelSize: 13
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                visible: root.ocrResult.length > 0 && !root.ocrBusy
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Tanınan Metin"
                    font.bold: true
                    font.pixelSize: 13
                    color: Theme.textMuted
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "⧉"
                    font.pixelSize: 13
                    ToolTip.visible: hovered
                    ToolTip.text: "Tanınan metni kopyala"
                    onClicked: {
                        ocrResultEdit.selectAll()
                        ocrResultEdit.copy()
                        ocrResultEdit.deselect()
                    }
                }
            }

            ScrollView {
                id: ocrScroll
                visible: root.ocrResult.length > 0 && !root.ocrBusy
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextEdit {
                    id: ocrResultEdit
                    width: ocrScroll.availableWidth
                    text: root.ocrResult
                    wrapMode: Text.Wrap
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                }
            }

            Button {
                text: "Instagram'da Aç (Tarayıcı)"
                highlighted: true
                Layout.fillWidth: true
                onClicked: Qt.openUrlExternally(root.permalink)
            }

            Button {
                text: "Çıkar"
                flat: true
                Material.foreground: Theme.dangerColor
                Layout.fillWidth: true
                onClicked: unsaveConfirmDialog.open()
            }
        }
    }
}
