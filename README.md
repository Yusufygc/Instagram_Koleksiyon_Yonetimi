# Instagram Koleksiyon Yöneticisi

Instagram'da kaydettiğiniz gönderileri ve özel koleksiyonlarınızı masaüstünden modern, hızlı ve konforlu bir şekilde yönetmenizi sağlayan **PySide6 (Qt Quick / QML)** tabanlı masaüstü uygulaması.

---

## 📸 Genel Bakış

Instagram web arayüzü ve mobil uygulaması, binlerce kaydedilmiş gönderi arasında arama yapmayı, içerikteki metinleri okumayı ve koleksiyonları toplu yönetmeyi zorlaştırır. **Instagram Koleksiyon Yöneticisi**, gönderilerinizi orijinal en-boy oranlarıyla büyük önizlemede incelemenizi, görsel ve videolardaki gömülü yazıları **OCR** ile anında metne dönüştürmenizi ve koleksiyonlarınızı zahmetsizce düzenlemenizi sağlar.

---

## ✨ Öne Çıkan Özellikler

* **🔐 Güvenli Kimlik ve Oturum Yönetimi:**
  * Parolalar düz metin olarak saklanmaz; Windows Credential Locker (**Keyring**) sistemiyle şifrelenir.
  * Oturum bilgileri (`session.json`) yerel olarak izinleri kısıtlanmış şekilde saklanır; her açılışta tekrar şifre sormadan oturumu devam ettirir.
* **🖼️ Evrensel Medya Görüntüleyici (`MediaViewer`):**
  * **Fotoğraflar:** Orijinal çözünürlük ve oranda kristal netliğinde gösterim.
  * **Videolar:** Dahili oynat/duraklat kontrolleri ile akıcı video önizlemesi.
  * **Carousel (Çoklu Slayt):** Fotoğraf ve videolar arasında hover okları ve sayfa göstergesiyle kolay geçiş.
* **🔍 Gelişmiş OCR (Optik Karakter Tanıma):**
  * **Otomatik Tarama:** Görselin veya videonun geçerli karesindeki tüm metinleri tek tıkla tanır.
  * **Alan Seçerek Tarama:** Görsel/video üzerinde fare ile serbest alan seçimi; letterbox (siyah boşluk) paylarını matematiksel olarak ayıklayan akıllı kesişim geometrisi.
  * **Çözünürlük İyileştirme:** Düşük çözünürlüklü kırpımları Lanczos enterpolasyonu ile büyüterek Tesseract tanıma doğruluğunu artırır.
  * **Çoklu Dil Desteği:** Türkçe ve İngilizce (`tur+eng`) karakter desteği.
* **⚡ Modern ve Minimal Arayüz:**
  * Windows 11 / Material Design ilkelerine uygun merkezi tasarım tokenları (`Theme.qml`).
  * Gönderi çıkarma ve koleksiyon silme işlemleri için kompakt, şık onay pencereleri.
  * Tüm ağ ve görüntü işlemlerini ana arayüzü kilitlemeden yürüten `QThreadPool` arka plan mimarisi.
* **📦 Bağımsız Kurulum Sihirbazı:**
  * Inno Setup ile hazırlanan Türkçe kurulum sihirbazı.
  * İsteğe bağlı olarak Tesseract OCR ve FFmpeg bileşenlerini `winget` üzerinden otomatik kurabilme yeteneği.

---

## 🛠️ Teknoloji Yığını

| Katman | Teknoloji | Amaç |
| :--- | :--- | :--- |
| **Arayüz (UI)** | PySide6 (Qt Quick 2 / QML) | Bildirimsel, akıcı ve yüksek DPI destekli masaüstü arayüzü |
| **API İstemcisi** | `instagrapi` | Instagram koleksiyon ve medya sorguları |
| **OCR Motoru** | Google Tesseract OCR (`pytesseract`) | Görsellerden optik karakter tanıma |
| **Video İşleme** | FFmpeg | Canlı videolardan hassas zaman damgalı kare yakalama |
| **Görüntü İşleme** | Pillow (PIL) | Görsel kırpma, renk dönüşümü ve Lanczos büyütme |
| **Güvenlik** | `keyring` | İşletim sistemi seviyesinde güvenli parola saklama |
| **Paketleme** | PyInstaller & Inno Setup 6 | Taşınabilir `.exe` ve Windows kurulum sihirbazı üretimi |

---

## 🚀 Kurulum ve Çalıştırma (Geliştirici)

### 1. Gereksinimler
* Python 3.10 veya üzeri
* Windows 10 / 11
* *(İsteğe bağlı)* Tesseract OCR ve FFmpeg (OCR ve video karesi yakalama özelliği için)

### 2. Adımlar

```powershell
# 1. Depoyu klonlayın
git clone https://github.com/Yusufygc/Instagram_Koleksiyon_Yonetimi.git
cd Instagram_Koleksiyon_Yonetimi

# 2. Sanal ortam oluşturun ve etkinleştirin
python -m venv venv
.\venv\Scripts\activate

# 3. Bağımlılıkları yükleyin
pip install -r requirements.txt

# 4. (İsteğe bağlı) Test giriş bilgileri için .env oluşturun
copy .env.example .env

# 5. Uygulamayı başlatın
python main.py
```

---

## 📦 Dağıtım ve Kurulum Dosyası Oluşturma

Uygulamayı bağımsız bir masaüstü yazılımı olarak derlemek için iki adım yeterlidir:

1. **PyInstaller ile Derleme:**
   ```powershell
   .\build_exe.bat
   ```
   *Çıktı:* `dist\InstagramKoleksiyonYoneticisi\InstagramKoleksiyonYoneticisi.exe`

2. **Inno Setup Kurulum Sihirbazı Oluşturma:**
   ```powershell
   & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
   ```
   *Çıktı:* `installer_output\InstagramKoleksiyonYoneticisi_Setup.exe`

---

## 📚 Bilgi Tabanı ve Dokümantasyon

Projenin tüm mimari kararları, servis detayları, OCR boru hattı ve geliştirme kuralları `docs/wiki/` altında dokümante edilmiştir:

* 🗺️ **[İçerik Haritası (Index)](docs/wiki/index.md):** Tüm wiki sayfalarının listesi ve özetleri.
* 🏛️ **[Sistem Mimarisi](docs/wiki/mimari.md):** 3 katmanlı mimari ve iş parçacığı havuzu modeli.
* ⚙️ **[Backend Servisleri](docs/wiki/backend-servisleri.md):** Instagram, OCR, Keyring ve Session servisleri.
* 🎨 **[Arayüz Katmanı](docs/wiki/arayuz-katmani.md):** QML bileşenleri ve Theme sistemi.
* 🔍 **[OCR ve Medya Boru Hattı](docs/wiki/ocr-ve-medya.md):** Kesişim matematiği ve kare yakalama akışı.
* 📦 **[Derleme ve Dağıtım](docs/wiki/build-ve-dagitim.md):** PyInstaller ve Inno Setup yönergeleri.
* 📋 **[Geliştirme ve Commit Kuralları](docs/wiki/rules.md):** Kodlama ve Git commit standartları.
* 📜 **[Değişiklik Kayıt Defteri (Log)](docs/wiki/log.md):** Kronolojik işlem kaydı.

---

## 🛡️ Güvenlik ve Gizlilik

* Uygulama tamamen istemci taraflı (client-side) çalışır.
* Kullanıcı adı, şifre ve oturum bilgileri **kesinlikle** geliştiriciye veya herhangi bir üçüncü taraf sunucuya iletilmez; yalnızca doğrudan Instagram resmi sunucularıyla güvenli HTTPS protokolü üzerinden haberleşir.
* Parolalar diske açık metin olarak kaydedilmez; Windows Credential Locker üzerinde şifreli olarak barındırılır.

---

## 📄 Lisans

Bu proje kişisel ve eğitim amaçlı kullanım için geliştirilmiştir.
