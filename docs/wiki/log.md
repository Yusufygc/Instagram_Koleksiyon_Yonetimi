# Değişiklik ve İşlem Kayıt Defteri (Log)

Bu dosya, projede gerçekleştirilen mimari kararların, özellik eklemelerinin, hata çözümlerinin ve dokümantasyon güncellemelerinin kronolojik kayıt defteridir. En yeni kayıt en üstte yer alır.

---

## [2026-09-25] FIX | Oturum dosyasının kullanıcı yerel veri dizinine (LOCALAPPDATA) taşınması
- SessionStore sınıfı güncellenerek session.json dosya konumu Program Files yerine %LOCALAPPDATA%\InstagramKoleksiyonYoneticisi\ altına alındı.
- Kurulum sihirbazı sonrasında oluşan [Errno 13] Permission denied yazma izin hatası tamamen giderildi.

## [2026-09-25] DOCS | Kapsamlı proje tanıtım ve kurulum kılavuzu (README.md) eklendi
- Proje genel bakışı, öne çıkan özellikler, teknoloji yığını ve mimari özetlendi.
- Geliştirici kurulumu, PyInstaller ve Inno Setup derleme adımları ile güvenlik ilkeleri belgelendi.

## [2026-09-24] FIX | QColor tanımsızlık hatası ve FFmpeg tanı logları giderildi
- PreviewDialog.qml içinde Theme.primaryColor yerine Theme.primary kullanılarak QColor hatası çözüldü.
- main.py içinde QT_LOGGING_RULES ve QLoggingCategory filtre kuralları genişletilerek video akışı kapatılırken basılan aac ve tls uyarıları susturuldu.

## [2026-09-24] STYLE | Gönderi ve koleksiyon silme onay pencereleri minimal kart tasarımına dönüştürüldü
- UnsaveConfirmDialog ve DeleteCollectionDialog bileşenleri kompakt (360px), yuvarlatılmış kart görünümüne geçirildi.
- Standart İngilizce (Yes/No) butonlar yerine Türkçe (Vazgeç/Çıkar/Sil) eylem butonları eklendi.
- Uzun teknik paragraflar sadeleştirildi ve popup anchor uyarıları giderildi.

## [2026-09-24] INIT | Wiki sistemi, içerik haritası ve geliştirme kuralları kuruldu
- `docs/wiki/` altında LLM Wiki anayasasına uygun bilgi tabanı oluşturuldu.
- [[rules|rules.md]] dosyasına Türkçe, her dosyaya ayrı ve sıfır AI referansı içeren katı commit kuralları eklendi.
- Mimari, backend servisleri, arayüz, OCR boru hattı ve derleme süreçleri dokümante edildi.

## [2026-09-24] FIX | Alan seçerek OCR tarama hatası, QUrl yol dönüşümü ve kesişim hesabı düzeltildi
- Videodan yakalanan kare yolunun Windows yerel biçiminden (`C:\...`) QML uyumlu `QUrl.fromLocalFile` (`file:///C:/...`) biçimine dönüştürülmesi sağlandı (`qml_bridge.py`).
- QML tarafındaki `capturedFrameImage` bileşeninin `asynchronous: false` yapılarak senkron yüklenmesi sağlandı (`MediaViewer.qml`).
- Letterbox paylarını doğru ayıklayan matematiksel kutu kesişim algoritması uygulandı; görsel dışı ve geçersiz seçimlerde kullanıcıya anında uyarı verildi (`PreviewDialog.qml`).
- Alan tarama esnasında `BusyIndicator` ve *"Seçilen alan taranıyor…"* görsel durum bildirimleri eklendi.

## [2026-09-24] CHORE | .gitignore dosyasına PyInstaller ve Inno Setup çıktı klasörleri eklendi
- `.gitignore` dosyasındaki karmaşa giderildi; `build/`, `dist/`, `installer_output/`, `Output/` ve `*.spec` kuralları `# --- Dağıtım / Paketleme (PyInstaller & Inno Setup) ---` bloğunda toplandı.

## [2026-09-24] FEAT | Inno Setup kurulum betiği ve PyInstaller derleme otomasyonu oluşturuldu
- `build_exe.bat` ile PyInstaller onedir derleme konfigürasyonu tamamlandı.
- `installer.iss` ile Türkçe dil destekli, masaüstü kısayollu ve isteğe bağlı Tesseract OCR / FFmpeg winget kurulumu yapan Inno Setup kurulum sihirbazı oluşturuldu.

## [2026-09-24] FEAT | Tesseract OCR ve FFmpeg ile video karesi yakalama ve metin tanıma desteği eklendi
- `OcrService` sınıfı oluşturularak Türkçe + İngilizce dil desteği, düşük çözünürlüklü görselleri Lanczos ile büyütme ve FFmpeg alt süreciyle video karesi yakalama entegrasyonu sağlandı.

## [2026-09-24] REFACTOR | Tek parça backend.py modüler servis katmanına dönüştürüldü
- Orijinal `backend.py` dosyası kaldırılarak `backend/` dizini altında tek sorumluluk ilkesine uygun modüllere (`instagram_service.py`, `credentials_store.py`, `session_store.py`, `ocr_service.py`, `workers.py`, `qml_bridge.py`) ayrıldı.
