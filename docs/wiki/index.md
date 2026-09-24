# Bilgi Tabanı ve İçerik Haritası (Index)

Instagram Koleksiyon Yöneticisi projesinin mimarisini, iş mantığını, görsel bileşenlerini ve geliştirme standartlarını içeren merkezi bilgi tabanı haritasıdır.

---

## 1. Geliştirme Standartları ve Kurallar

* [[rules]]: Projede kod yazarken, dosya düzenlerken ve Git kullanırken uyulması zorunlu geliştirme standartları ile Türkçe, her dosyaya ayrı ve sıfır AI referansı içeren katı commit kuralları.
* [[log]]: Projede alınan mimari kararların, yapılan geliştirmelerin ve hata çözümlerinin kronolojik kayıt defteri.

---

## 2. Mimari ve Tasarım

* [[mimari]]: Python (PySide6) ve Qt Quick (QML) temelli katmanlı mimari yapısı, yalıtım ilkeleri ve iş parçacığı havuzu modeli.
* [[backend-servisleri]]: `InstagramService`, `OcrService`, `CredentialsStore`, `SessionStore` servisleri ve Python-QML köprüsünün (`QmlBridge`) sorumlulukları ve işleyişi.
* [[arayuz-katmani]]: `Theme.qml` tasarım sistemi, sayfa akışları, modal pencereler ve evrensel `MediaViewer` bileşeninin yapısı.

---

## 3. Özellikler ve Entegrasyonlar

* [[ocr-ve-medya]]: Tesseract OCR metin tanıma, FFmpeg video karesi yakalama, görsel kırpma, Lanczos büyütme ve letterbox kesişim geometrisi.
* [[build-ve-dagitim]]: `build_exe.bat` ile PyInstaller masaüstü derlemesi, Inno Setup `installer.iss` kurulum sihirbazı ve winget bağımlılık otomasyonu.

---

## 4. Hızlı Gezinme Grafiği

```
                        [[index]]
                            │
       ┌─────────────┬──────┴──────┬─────────────┐
       ▼             ▼             ▼             ▼
   [[rules]]     [[mimari]]   [[ocr-ve-medya]] [[build-ve-dagitim]]
       ▲             │             ▲             ▲
       │       ┌─────┴─────┐       │             │
       │       ▼           ▼       │             │
   [[log]] [[backend-  [[arayuz- ──┘             │
           servisleri]] katmani]]────────────────┘
```
