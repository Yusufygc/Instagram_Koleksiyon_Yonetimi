import QtQuick
import QtQuick.Controls
import QtMultimedia
import ".."

// Fotoğraf / video / carousel (çoklu slayt) gösterimini tek yerde toplar.
// Kırpma yapmaz (PreserveAspectFit): içerik her zaman tam ve orijinal
// oranıyla görünür. active=false olduğunda video kaynakları boşaltılır.
Rectangle {
    id: root
    color: Theme.previewBg
    clip: true

    property int mediaType: 1  // 1=fotoğraf, 2=video, 8=carousel
    property string photoUrl: ""
    property string videoUrl: ""
    property var resources: []
    property bool active: true
    property bool selectionMode: false  // true iken kullanıcı OCR için bir bölge sürükleyerek seçer
    // Video için: alan seçilebilsin diye dondurulmuş bir kare gösterilir
    // (canlı video üzerinde piksel-doğru seçim yapılamaz). Boşken etkisizdir.
    property string capturedFrameUrl: ""

    // nx/ny/nw/nh: seçilen alan, GÖRÜNTÜNÜN GERÇEK piksellerine göre 0-1 oran
    // (harf kutusu/letterbox hariç), böylece backend doğrudan orantılı kırpar.
    // imageUrl: seçimin yapıldığı aktif görsel kaynağı (file:/// veya https://)
    signal regionSelected(string imageUrl, real nx, real ny, real nw, real nh)
    signal invalidRegionSelected()

    readonly property alias currentIndex: carouselSwipe.currentIndex
    readonly property alias pageCount: carouselSwipe.count

    // OCR gibi "şu an ekranda görünen görsel" gerektiren işlemler için:
    // fotoğrafta doğrudan kendisi, carousel'de aktif slayt (video ise boş).
    readonly property string currentImageUrl: {
        if (mediaType === 1) return photoUrl
        if (mediaType === 8 && resources.length > 0) {
            // currentIndex geçici olarak resources ile senkron olmayabilir
            // (örn. showFor() sırasındaki ara adımlar); sınır dışına taşmayı
            // ve undefined erişimini önle.
            var idx = Math.max(0, Math.min(currentIndex, resources.length - 1))
            var item = resources[idx]
            return (item && item.type !== "video") ? item.thumbnail : ""
        }
        return ""
    }

    function _activeVideo() {
        if (mediaType === 2) return mainVideo
        if (mediaType === 8 && resources.length > 0) {
            var idx = Math.max(0, Math.min(currentIndex, resources.length - 1))
            var item = resources[idx]
            if (item && item.type === "video" && carouselSwipe.currentItem)
                return carouselSwipe.currentItem.video
        }
        return null
    }

    // Video OCR için: hangi video oynatılıyor ve hangi karede duruyor.
    readonly property string currentVideoUrl: {
        if (mediaType === 2) return videoUrl
        if (mediaType === 8 && resources.length > 0) {
            var idx = Math.max(0, Math.min(currentIndex, resources.length - 1))
            var item = resources[idx]
            return (item && item.type === "video") ? item.video : ""
        }
        return ""
    }
    readonly property real currentVideoPositionMs: {
        var v = _activeVideo()
        return v ? v.position : 0
    }

    function pauseActiveVideo() {
        var v = _activeVideo()
        if (v) v.pause()
    }

    // Fare üzerine gelmeden okları gizli tutar (var olan MouseArea'ların
    // tıklamalarını tüketmeden yalnızca hover durumunu izler), böylece
    // gönderi içeriğini kapatmazlar.
    HoverHandler {
        id: hoverHandler
    }

    onActiveChanged: {
        // Kaynağı boşaltmadan önce nazikçe durdur (ani kesme yerine)
        if (!active) {
            mainVideo.stop()
        }
    }

    Image {
        id: photoImage
        anchors.fill: parent
        visible: root.mediaType === 1
        source: (root.mediaType === 1 && root.active) ? root.photoUrl : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true

        BusyIndicator {
            anchors.centerIn: parent
            running: parent.status === Image.Loading
            visible: running
        }

        Label {
            anchors.centerIn: parent
            text: "Görsel yüklenemedi"
            color: "#B0B0B8"
            visible: parent.status === Image.Error || root.photoUrl.length === 0
        }
    }

    Video {
        id: mainVideo
        anchors.fill: parent
        visible: root.mediaType === 2
        source: (root.mediaType === 2 && root.active) ? root.videoUrl : ""
        fillMode: VideoOutput.PreserveAspectFit

        MouseArea {
            anchors.fill: parent
            onClicked: mainVideo.playbackState === MediaPlayer.PlayingState
                       ? mainVideo.pause() : mainVideo.play()
        }

        Label {
            anchors.centerIn: parent
            text: "▶"
            font.pixelSize: 48
            color: "white"
            visible: mainVideo.playbackState !== MediaPlayer.PlayingState
        }
    }

    SwipeView {
        id: carouselSwipe
        anchors.fill: parent
        visible: root.mediaType === 8
        clip: true

        Repeater {
            model: root.mediaType === 8 ? root.resources : []

            delegate: Item {
                required property var modelData
                property alias image: slideImage
                property alias video: slideVideo

                Image {
                    id: slideImage
                    anchors.fill: parent
                    visible: modelData.type !== "video"
                    source: (modelData.type !== "video" && root.active) ? modelData.thumbnail : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: parent.status === Image.Loading
                        visible: running
                    }
                }

                Video {
                    id: slideVideo
                    anchors.fill: parent
                    visible: modelData.type === "video"
                    source: (modelData.type === "video" && root.active) ? modelData.video : ""
                    fillMode: VideoOutput.PreserveAspectFit

                    MouseArea {
                        anchors.fill: parent
                        onClicked: slideVideo.playbackState === MediaPlayer.PlayingState
                                   ? slideVideo.pause() : slideVideo.play()
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "▶"
                        font.pixelSize: 40
                        color: "white"
                        visible: slideVideo.playbackState !== MediaPlayer.PlayingState
                    }
                }
            }
        }
    }

    PageIndicator {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        visible: root.mediaType === 8 && carouselSwipe.count > 1
        count: carouselSwipe.count
        currentIndex: carouselSwipe.currentIndex
    }

    // --- Carousel geçiş (slider) okları: sadece hover'da görünür,
    // gönderi içeriğinin üzerini kapatmaz ---
    RoundButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        opacity: 0.75
        text: "‹"
        font.pixelSize: 20
        visible: root.mediaType === 8 && carouselSwipe.count > 1 && carouselSwipe.currentIndex > 0 && hoverHandler.hovered
        onClicked: carouselSwipe.decrementCurrentIndex()
    }

    RoundButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 8
        opacity: 0.75
        text: "›"
        font.pixelSize: 20
        visible: root.mediaType === 8 && carouselSwipe.count > 1 && carouselSwipe.currentIndex < carouselSwipe.count - 1 && hoverHandler.hovered
        onClicked: carouselSwipe.incrementCurrentIndex()
    }

    // Videodan yakalanmış dondurulmuş kare: capturedFrameUrl doluyken bunu
    // canlı video/foto'nun ÜZERİNDE gösterir; seçim burada yapılır.
    Image {
        id: capturedFrameImage
        anchors.fill: parent
        visible: root.capturedFrameUrl.length > 0
        source: root.capturedFrameUrl
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        z: 15

        BusyIndicator {
            anchors.centerIn: parent
            running: parent.status === Image.Loading
            visible: running
        }
    }

    // --- OCR için bölge seçimi ---
    function _activeImage() {
        if (root.capturedFrameUrl.length > 0) return capturedFrameImage
        if (root.mediaType === 1) return photoImage
        if (root.mediaType === 8 && carouselSwipe.currentItem) return carouselSwipe.currentItem.image
        return null
    }

    // currentImageUrl/currentVideoUrl veri katmanından hesaplanır; bazı
    // gönderilerde bu alanlar boş gelebilir. O yüzden asıl ekranda o an
    // GERÇEKTEN yüklenmiş olan kaynağı (Image/Video.source) da yedek olarak
    // dener — buton hep tıklanabilir kalır, mümkün olan her durumda çalışır.
    function bestImageUrl() {
        var img = _activeImage()
        if (img && img.source && img.source.toString().length > 0) return img.source.toString()
        return currentImageUrl
    }

    onSelectionModeChanged: {
        // Seçim bitince/iptal olunca dondurulmuş kareyi bırak, canlı videoya dön
        if (!selectionMode) capturedFrameUrl = ""
    }

    function bestVideoUrl() {
        var v = _activeVideo()
        if (v && v.source && v.source.toString().length > 0) return v.source.toString()
        return currentVideoUrl
    }

    Label {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 12
        visible: root.selectionMode && !selectionArea.dragging
        text: "Metni içeren alanı fare ile sürükleyerek seçin"
        color: "white"
        font.pixelSize: 13
        padding: 8
        background: Rectangle { color: "#00000099"; radius: 6 }
        z: 20
    }

    MouseArea {
        id: selectionArea
        anchors.fill: parent
        visible: root.selectionMode
        enabled: root.selectionMode
        cursorShape: Qt.CrossCursor
        z: 20
        property bool dragging: false
        property point startPt

        onPressed: function(mouse) {
            dragging = true
            startPt = Qt.point(mouse.x, mouse.y)
            selectionRect.x = mouse.x
            selectionRect.y = mouse.y
            selectionRect.width = 0
            selectionRect.height = 0
        }

        onPositionChanged: function(mouse) {
            if (!dragging) return
            var x1 = Math.min(startPt.x, mouse.x)
            var x2 = Math.max(startPt.x, mouse.x)
            var y1 = Math.min(startPt.y, mouse.y)
            var y2 = Math.max(startPt.y, mouse.y)
            selectionRect.x = x1
            selectionRect.y = y1
            selectionRect.width = x2 - x1
            selectionRect.height = y2 - y1
        }

        onReleased: function() {
            dragging = false

            // ÖNEMLİ: bölgeyi hesapla ve sinyali gönder, selectionMode'u
            // FALSE yapmadan önce — aksi halde capturedFrameUrl (dondurulmuş
            // video karesi) selectionMode kapanır kapanmaz temizlenir ve
            // _activeImage() artık doğru kareyi döndüremez.
            var img = root._activeImage()
            var valid = false
            var rx = 0, ry = 0, rw = 0, rh = 0
            var sourceUrl = ""

            if (img && img.paintedWidth > 0 && img.paintedHeight > 0 &&
                selectionRect.width >= 6 && selectionRect.height >= 6) {
                // PreserveAspectFit görüntüyü ortalar; asıl piksel alanı
                // paintedWidth/Height ile letterbox boşlukları hesaba katılır.
                var xOff = (img.width - img.paintedWidth) / 2
                var yOff = (img.height - img.paintedHeight) / 2

                var selLeft = selectionRect.x
                var selRight = selectionRect.x + selectionRect.width
                var selTop = selectionRect.y
                var selBottom = selectionRect.y + selectionRect.height

                var imgLeft = xOff
                var imgRight = xOff + img.paintedWidth
                var imgTop = yOff
                var imgBottom = yOff + img.paintedHeight

                // Seçilen alan ile gerçek görselin kesişimi
                var interLeft = Math.max(selLeft, imgLeft)
                var interRight = Math.min(selRight, imgRight)
                var interTop = Math.max(selTop, imgTop)
                var interBottom = Math.min(selBottom, imgBottom)

                var interW = interRight - interLeft
                var interH = interBottom - interTop

                if (interW >= 6 && interH >= 6) {
                    rx = interLeft - imgLeft
                    ry = interTop - imgTop
                    rw = interW
                    rh = interH
                    valid = true
                    sourceUrl = (img.source && img.source.toString().length > 0)
                                ? img.source.toString() : root.bestImageUrl()
                }
            }

            selectionRect.width = 0
            selectionRect.height = 0

            if (valid && sourceUrl.length > 0) {
                root.regionSelected(sourceUrl,
                                     rx / img.paintedWidth, ry / img.paintedHeight,
                                     rw / img.paintedWidth, rh / img.paintedHeight)
            } else {
                root.invalidRegionSelected()
            }

            root.selectionMode = false  // capturedFrameUrl'i de temizler
        }
    }

    Rectangle {
        id: selectionRect
        visible: selectionArea.dragging
        color: "#332196F3"
        border.color: "#2196F3"
        border.width: 2
        z: 21
    }
}
