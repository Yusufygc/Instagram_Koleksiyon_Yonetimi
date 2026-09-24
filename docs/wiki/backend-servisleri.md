# Backend Servisleri ve Köprü Mimarisi

Bu doküman, `backend/` dizininde yer alan modüllerin, servis sınıflarının ve Python-QML köprüsünün (`QmlBridge`) sorumluluklarını ve işleyişini açıklar.

---

## 1. Modül Listesi ve Sorumluluklar

| Modül / Sınıf | Dosya | Sorumluluk |
| :--- | :--- | :--- |
| **`Backend` (QmlBridge)** | `backend/qml_bridge.py` | QML'e maruz bırakılan tek nesnedir. Qt sinyalleri/slotları ve iş parçacığı havuzunu yönetir. |
| **`InstagramService`** | `backend/instagram_service.py` | `instagrapi` istemcisini sarar. Giriş, koleksiyon listeleme, medya çekme ve silme operasyonlarını yürütür. |
| **`OcrService`** | `backend/ocr_service.py` | Tesseract OCR ve FFmpeg motorlarını yönetir. Görsel ve video karelerinden metin tanır. |
| **`CredentialsStore`** | `backend/credentials_store.py` | İşletim sistemi anahtarlığı (`keyring` - Windows Credential Locker) ile kullanıcı adı/şifreyi güvenle saklar. |
| **`SessionStore`** | `backend/session_store.py` | Instagram oturumunun (`session.json`) disk kalıcılığını ve dosya izinlerini yönetir. |
| **`Worker` / `WorkerSignals`** | `backend/workers.py` | `QThreadPool` üzerinde arka planda çağrı çalıştıran genel amaçlı `QRunnable` sarmalayıcısı. |

---

## 2. Detaylı Servis İncelemeleri

### 2.1. `Backend` (`backend/qml_bridge.py`)
`main.py` içinde `engine.rootContext().setContextProperty("backend", backend)` olarak bağlanır.

* **Sinyaller:**
  - `collectionsLoaded(list)`: Koleksiyon listesi çekildiğinde yayılır.
  - `mediasLoaded(list)`: Seçili koleksiyondaki gönderiler çekildiğinde yayılır.
  - `loggedIn(bool)`: Giriş işlemi başarılı olduğunda yayılır.
  - `error(str)`: Arka plan işlemlerinde oluşan hata mesajını arayüze iletir.
  - `textRecognized(str)`: OCR işlemi tamamlandığında tanınan metni iletir.
  - `videoFrameCaptured(str)`: Videodan yakalanan durağan karenin `file:///` formatındaki yerel URL'sini iletir.
* **İş Parçacığı Yönetimi (`_run`):**
  Ağ veya disk işlemlerini ana arayüzü kilitlemeden yürütmek için `QThreadPool.globalInstance()` kullanır:
  ```python
  def _run(self, fn, on_finished, on_error=None):
      worker = Worker(fn)
      worker.signals.finished.connect(on_finished)
      worker.signals.error.connect(on_error or self.error.emit)
      self._pool.start(worker)
  ```

### 2.2. `InstagramService` (`backend/instagram_service.py`)
Instagram özel API ve GraphQL uç noktalarıyla etkileşime girer:
* **Akıllı Oturum Yeniden Kullanımı:** Giriş esnasında önce `SessionStore`'dan mevcut ayarlar yüklenir; oturum hala geçerliyse ağ üzerinden tekrar kullanıcı adı ve şifreyle kimlik doğrulama yapılmaz.
* **Toplu Koleksiyon Silme (`delete_collection`):** Instagram API'sinde doğrudan koleksiyonu ve içindekileri silen tek bir uç nokta bulunmadığından; koleksiyondaki tüm medyalar önce teker teker `media_unsave` ile Kaydedilenler'den çıkarılır, ardından `collections/{id}/delete/` özel API isteği gönderilir.

### 2.3. `CredentialsStore` (`backend/credentials_store.py`)
* Kullanıcı adı ve şifreyi açık metin (plain text) olarak saklamak yerine Python `keyring` kütüphanesini kullanarak Windows Credential Locker üzerinde güvenle saklar.
* Güvenli anahtarlık erişilemezse güvenli bir geri çekilme (fallback) sağlar.

### 2.4. `SessionStore` (`backend/session_store.py`)
* `instagrapi` istemcisinin oturum durumunu, çerezlerini ve cihaz profillerini `session.json` dosyasına döker ve buradan yükler.
* Oturum dosyasının yalnızca yerel kullanıcı tarafından okunabilmesi için izinleri (`stat.S_IRUSR | stat.S_IWUSR`) kısıtlar.

---

## 3. İlgili Dokümanlar
* [[mimari|Sistem Mimarisi]]
* [[ocr-ve-medya|OCR ve Medya İşleme Boru Hattı]]
* [[arayuz-katmani|Arayüz ve QML Bileşenleri]]
* [[rules|Geliştirme ve Commit Kuralları]]
