# Arayüz ve QML Bileşenleri

Uygulamanın görsel katmanı Qt Quick ve QML ile geliştirilmiştir. Ekran boyutlarına duyarlı (responsive), pencereli ve modern kart tabanlı bir deneyim hedeflenmiştir.

---

## 1. Dizin Yapısı ve Rolleri

```
qml/
├── main.qml                 # Ana pencere ve sayfa geçiş konteyneri (StackView)
├── Theme.qml                # Renk, yazı boyutu ve stil tasarım tokenları (Singleton)
├── qmldir                   # Modül ve Theme singleton bildirimi
├── pages/
│   ├── LoginPage.qml        # Kullanıcı girişi, kayıtlı kimlik bilgileri yükleme
│   ├── CollectionsPage.qml  # Koleksiyon kartları ve ızgara görünümü
│   └── MediaPage.qml        # Koleksiyon içi gönderi ızgarası ve filtreleme
├── dialogs/
│   ├── PreviewDialog.qml    # Gönderi detay penceresi, açıklama, OCR aksiyonları
│   └── UnsaveConfirmDialog.qml # Koleksiyondan çıkarma onay penceresi
└── components/
    └── MediaViewer.qml      # Fotoğraf, video, carousel ve alan seçici bileşen
```

---

## 2. Temel Arayüz Bileşenleri

### 2.1. `Theme.qml` (Tasarım Sistemi)
Tüm renkler ve UI sabitleri tek merkezden yönetilir:
* **`primary` / `accent`:** Instagram mavisi ve vurgu tonları.
* **`previewBg`:** Önizleme alanının mat koyu tonu (`#18191E`).
* **`dangerColor`:** Çıkarma/silme aksiyonları için kırmızı uyarı rengi.
* **`cardBg`, `cardRadius`:** Kart yapılarının görünüm parametreleri.

### 2.2. `MediaViewer.qml` (Evrensel Medya Görüntüleyici)
Üç farklı Instagram medya türünü tek bir bileşende sorunsuz sunar:
1. **Fotoğraf (`mediaType == 1`):** `Image` bileşeni ile `PreserveAspectFit` oranında gösterilir.
2. **Video (`mediaType == 2`):** `Video` bileşeni ve `MediaPlayer` ile tıkla-oynat/duraklat mantığıyla çalışır.
3. **Carousel / Çoklu Slayt (`mediaType == 8`):** `SwipeView` üzerinde fotoğraflar ve videolar sıralanır; hover anında beliren ileri/geri okları ve alt `PageIndicator` ile gezilir.

#### Alan Seçim Mekanizması (`selectionMode`):
* Kullanıcı OCR için bir bölge seçmek istediğinde `selectionArea` (`MouseArea`) devreye girer.
* Fare sürüklendikçe `selectionRect` yarı saydam mavi bir kutu çizer.
* Fare bırakıldığında gerçek piksel koordinatları letterbox paylarından arındırılarak normalize edilir (`0.0` - `1.0`) ve `regionSelected(sourceUrl, nx, ny, nw, nh)` sinyali yayılır.

### 2.3. `PreviewDialog.qml` (Önizleme Penceresi)
Gönderiyi modal bir diyalog içerisinde açar:
* **Sol Panel (`MediaViewer`):** Medyanın orijinal oranında büyük önizlemesi.
* **Sağ Panel:**
  - Kopyalanabilir gönderi açıklaması (`TextEdit`).
  - **Otomatik Tara (OCR):** Görselin/videonun tamamını tarar.
  - **Alan Seçerek Tara:** Kullanıcının fareyle belirlediği kutuyu tarar.
  - **İşlem Durumu:** Tarama esnasında `BusyIndicator` ve *"Seçilen alan taranıyor…"* geri bildirimi.
  - **Sonuç Kutusu:** Tanınan metin ve tek tıkla panoya kopyalama butonu.
  - **Instagram'da Aç:** Gönderiyi varsayılan web tarayıcısında açar.

---

## 3. İlgili Dokümanlar
* [[mimari|Sistem Mimarisi]]
* [[ocr-ve-medya|OCR ve Medya İşleme Boru Hattı]]
* [[backend-servisleri|Backend Servisleri ve Köprü Mimarisi]]
* [[rules|Geliştirme ve Commit Kuralları]]
