# Derleme, Paketleme ve Kurulum

Uygulamanın Windows işletim sisteminde bağımsız (standalone) bir masaüstü yazılımı olarak dağıtılması iki aşamada gerçekleştirilir: **PyInstaller** ile `.exe` üretimi ve **Inno Setup** ile kurulum sihirbazı oluşturulması.

---

## 1. PyInstaller ile Derleme (`build_exe.bat`)

Uygulama kodları ve bağlı varlıklar `build_exe.bat` betiği ile paketlenir:

```bat
venv\Scripts\pyinstaller.exe main.py ^
  --name "InstagramKoleksiyonYoneticisi" ^
  --windowed ^
  --icon assets\app_icon.ico ^
  --add-data "qml;qml" ^
  --add-data "assets;assets" ^
  --hidden-import PySide6.QtQml ^
  --hidden-import PySide6.QtQuick ^
  --hidden-import PySide6.QtQuickControls2 ^
  --hidden-import PySide6.QtMultimedia ^
  --hidden-import PySide6.QtNetwork ^
  --hidden-import keyring.backends.Windows ^
  --noconfirm
```

* **Çıktı Dizini:** `dist\InstagramKoleksiyonYoneticisi\`
* **Kritik Gizli İçe Aktarmalar (`hidden-import`):**
  - QML modülleri dinamik yüklendiğinden `PySide6.QtQuickControls2`, `QtMultimedia` ve `QtNetwork` açıkça eklenmelidir.
  - Windows anahtarlık desteği için `keyring.backends.Windows` mutlaka dahil edilmelidir.

---

## 2. Inno Setup Kurulum Sihirbazı (`installer.iss`)

`installer.iss` betiği Inno Setup derleyicisi ile derlendiğinde `installer_output\` altında son kullanıcı kurulum dosyasını (`InstagramKoleksiyonYoneticisi_Setup.exe`) üretir.

### 2.1. Özellikler
* **Türkçe Dil Desteği:** Kurulum adımları tamamen Türkçedir.
* **Masaüstü Kısayolu:** İsteğe bağlı masaüstü ve başlat menüsü simgeleri oluşturur.
* **Otomatik Bağımlılık Kurulumu (winget Entegrasyonu):**
  Kurulum sihirbazında özel bir `[Code]` sayfası (`DepsPage`) yer alır:
  1. Sistemin `winget` desteğini denetler (`IsWinGetAvailable`).
  2. OCR ve video işleme için isteğe bağlı iki bileşeni kullanıcı onayına sunar:
     - **Tesseract OCR:** `winget install --id UB-Mannheim.TesseractOCR`
     - **FFmpeg:** `winget install --id Gyan.FFmpeg`
  3. Kullanıcı kutucukları işaretlerse kurulum tamamlandıktan sonra bu araçları arka planda otomatik kurar.

---

## 3. Versiyon Kontrolü ve Yoksayılanlar

Derleme ve kurulum süreçlerinde üretilen tüm geçici ve nihai ikili dosyalar `.gitignore` dosyasında tanımlanmıştır:
* `build/`
* `dist/`
* `installer_output/`
* `Output/`
* `*.spec`

---

## 4. İlgili Dokümanlar
* [[mimari|Sistem Mimarisi]]
* [[ocr-ve-medya|OCR ve Medya İşleme Boru Hattı]]
* [[rules|Geliştirme ve Commit Kuralları]]
