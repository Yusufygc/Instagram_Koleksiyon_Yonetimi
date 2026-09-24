# Sistem Mimarisi

Instagram Koleksiyon Yöneticisi, modern bir masaüstü kullanıcı deneyimi sunmak amacıyla **Python (PySide6)** çekirdeği ile **Qt Quick / QML** bildirimsel arayüz teknolojisini bir araya getiren katmanlı bir mimariye sahiptir.

---

## 1. Katmanlı Yapı (Architecture Layers)

Sistem birbirinden kesin sınırlarla ayrılmış üç temel katmandan meydana gelir:

```
┌────────────────────────────────────────────────────────┐
│               Arayüz Katmanı (QML / Qt Quick)          │
│   - main.qml, Theme.qml                                │
│   - Pages (LoginPage, CollectionsPage, MediaPage)      │
│   - Components (MediaViewer), Dialogs (PreviewDialog)  │
└───────────────────────────▲────────────────────────────┘
                            │ Qt Signals & Slots
┌───────────────────────────▼────────────────────────────┐
│               Köprü Katmanı (QmlBridge / Backend)      │
│   - QThreadPool & Asenkron Worker Yönetimi             │
│   - UI Olaylarının Backend Servislerine Dağıtımı       │
└───────────────────────────▲────────────────────────────┘
                            │ Bağımsız Python Çağrıları
┌───────────────────────────▼────────────────────────────┐
│               Servis Katmanı (Domain & Business)       │
│   - InstagramService (instagrapi istemcisi)            │
│   - OcrService (Tesseract OCR & FFmpeg motoru)         │
│   - CredentialsStore (İşletim sistemi Keyring)         │
│   - SessionStore (session.json oturum yönetimi)        │
└────────────────────────────────────────────────────────┘
```

---

## 2. Temel Tasarım İlkeleri

### 2.1. UI ve İş Mantığının Yalıtımı (Decoupling)
* `InstagramService` ve `OcrService` sınıfları hiçbir Qt kütüphanesine (`QObject`, `Signal`, `Slot` vb.) bağımlı değildir.
* Bu yalıtım sayesinde backend servisleri arayüz olmadan bağımsız birim testlerine tabi tutulabilir, CLI ortamında çalıştırılabilir veya farklı bir arayüz çerçevesine taşınabilir.

### 2.2. Arayüzün Asla Kilitlenmemesi (Non-blocking UI)
* Instagram API istekleri (giriş, koleksiyon listeleme, medya çekme), video karesi yakalama (FFmpeg alt süreci) ve optik karakter tanıma (Tesseract) yoğun işlemci ve ağ kaynağı tüketir.
* Tüm bu ağır işler `QThreadPool.globalInstance()` üzerinde çalışan [[backend-servisleri|Worker (QRunnable)]] iş parçacıklarıyla asenkronize edilir.
* İşlem tamamlandığında veya hata oluştuğunda Qt sinyal-slot mekanizmasıyla ana arayüz (GUI) iş parçacığı güvenle uyarılır.

### 2.3. Merkezi Tasarım ve Tema Sistemi
* Arayüz renkleri, kart yuvarlama oranları, tipografi ve arka plan tonları [[arayuz-katmani|Theme.qml]] içerisinde merkezi bir singleton olarak tanımlanmıştır.
* `main.py` başlangıcında `QQuickStyle.setStyle("Material")` uygulanarak tüm platformlarda tutarlı modern Windows 11 / Material tasarım dili sağlanır.

---

## 3. İlgili Dokümanlar
* [[backend-servisleri|Backend Servisleri ve Köprü Mimarisi]]
* [[arayuz-katmani|Arayüz ve QML Bileşenleri]]
* [[ocr-ve-medya|OCR ve Medya İşleme Boru Hattı]]
* [[build-ve-dagitim|Derleme, Paketleme ve Kurulum]]
* [[rules|Geliştirme ve Commit Kuralları]]
