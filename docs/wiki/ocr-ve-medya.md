# OCR ve Medya İşleme Boru Hattı

Instagram gönderilerinde yer alan görsel ve videolardaki gömülü metinlerin tanınması, uygulamanın en kritik yeteneklerinden biridir. Bu doküman, OCR sürecini, video kare yakalama mekanizmasını ve koordinat matematiğini detaylandırır.

---

## 1. Kullanılan Teknolojiler

* **Optik Karakter Tanıma:** Google Tesseract OCR (`pytesseract` sarmalayıcısı).
* **Video İşleme ve Kare Yakalama:** FFmpeg CLI alt süreci.
* **Görsel İşleme ve Kırpma:** Python Imaging Library (Pillow / PIL).

---

## 2. OCR İş Akışı

### 2.1. Fotoğraf Taraması
1. **İndirme / Yükleme:** Görsel URL'si HTTP(S) ise `requests` üzerinden `_USER_AGENT` başlığıyla indirilir; yerel dosya ise Pillow ile doğrudan açılır.
2. **Kırpma (`_crop`):** Kullanıcının seçtiği normalize koordinatlar (`nx, ny, nw, nh`) görselin gerçek genişlik/yükseklik piksellerine (`iw, ih`) dönüştürülür ve kırpılır.
3. **Yeniden Ölçekleme (`_upscale_if_small`):** Tesseract düşük çözünürlüklü kırpımlarda başarısız olduğundan, genişliği `700px` altındaki kırpımlar Lanczos enterpolasyonu ile büyütülür.
4. **Metin Tanıma:** `pytesseract.image_to_string(cropped, lang="tur+eng")` çağrısıyla Türkçe ve İngilizce dillerinde metin çıkarılır.

### 2.2. Video Taraması ve Alan Seçimi
Canlı video üzerinde doğrudan piksel seçimi yapılamaz. Bu sebeple iki aşamalı bir süreç işletilir:

```
[Kullanıcı: "Alan Seçerek Tara"]
           │
           ▼
[1. Aşama: FFmpeg Kare Yakalama]
 - Video URL'si ve geçerli zaman damgası (position_seconds) alınır.
 - FFmpeg subprocess çalıştırılarak kare yakalanır:
   ffmpeg -ss <sec> -i <video_url> -frames:v 1 -f image2 -vcodec png pipe:1
 - Yakalanan kare geçici bir dosyaya yazılır:
   %TEMP%/ig_ocr_frame_<id>.png
 - Backend bu yolu QUrl.fromLocalFile formatında yayar:
   file:///C:/Users/.../ig_ocr_frame_<id>.png
           │
           ▼
[2. Aşama: QML Üzerinde Dondurulmuş Kare]
 - MediaViewer.qml bu kareyi canlı videonun üzerine serer (asynchronous: false).
 - Kullanıcı fare ile metin alanını seçer.
 - Kesişim koordinatları normalize edilerek extract_text metoduna gönderilir.
```

---

## 3. Letterbox ve Kesişim Matematiği

`MediaViewer` içindeki `Image` bileşeni `fillMode: Image.PreserveAspectFit` kullandığından, pencere en-boy oranı ile görsel en-boy oranı uyuşmadığında kenarlarda siyah boşluklar (letterbox) oluşur. 

Kullanıcının fareyle seçtiği alanın görselin gerçek içeriğine doğru haritalanabilmesi için aşağıdaki kesişim algoritması uygulanır:

```javascript
// Letterbox ofsetleri
var xOff = (img.width - img.paintedWidth) / 2
var yOff = (img.height - img.paintedHeight) / 2

// Seçim kutusu sınırları
var selLeft = selectionRect.x, selRight = selectionRect.x + selectionRect.width
var selTop = selectionRect.y, selBottom = selectionRect.y + selectionRect.height

// Gerçek görsel sınırları
var imgLeft = xOff, imgRight = xOff + img.paintedWidth
var imgTop = yOff, imgBottom = yOff + img.paintedHeight

// İki kutunun kesişimi
var interLeft = Math.max(selLeft, imgLeft)
var interRight = Math.min(selRight, imgRight)
var interTop = Math.max(selTop, imgTop)
var interBottom = Math.min(selBottom, imgBottom)

var interW = interRight - interLeft
var interH = interBottom - interTop

// Yalnızca geçerli kesişim varsa sinyal yayılır
if (interW >= 6 && interH >= 6) {
    var rx = interLeft - imgLeft
    var ry = interTop - imgTop
    root.regionSelected(sourceUrl, rx / img.paintedWidth, ry / img.paintedHeight,
                        interW / img.paintedWidth, interH / img.paintedHeight)
} else {
    root.invalidRegionSelected()
}
```

Bu matematik sayesinde:
* Kullanıcı siyah boşlukta başlasa bile yalnızca görsel üzerindeki pikseller seçilir.
* Görselin tamamen dışındaki tıklamalar ve sürüklemeler boşa düşmez; kullanıcıya net hata uyarısı verilir.

---

## 4. İlgili Dokümanlar
* [[backend-servisleri|Backend Servisleri ve Köprü Mimarisi]]
* [[arayuz-katmani|Arayüz ve QML Bileşenleri]]
* [[mimari|Sistem Mimarisi]]
* [[rules|Geliştirme ve Commit Kuralları]]
