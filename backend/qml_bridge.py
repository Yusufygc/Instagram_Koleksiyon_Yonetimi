from PySide6.QtCore import QObject, QThreadPool, QUrl, Signal, Slot

from .credentials_store import CredentialsStore
from .instagram_service import InstagramService
from .ocr_service import OcrService
from .workers import Worker


class Backend(QObject):
    """QML'e açılan ince arayüz katmanı: iş mantığını InstagramService ve
    CredentialsStore'a devreder, kendisi yalnızca Qt sinyal/slot ve arka
    plan iş parçacığı yönetiminden sorumludur (tek sorumluluk)."""

    collectionsLoaded = Signal(list)
    mediasLoaded = Signal(list)
    loggedIn = Signal(bool)
    error = Signal(str)
    textRecognized = Signal(str)
    videoFrameCaptured = Signal(str)

    def __init__(self, instagram_service: InstagramService = None,
                 credentials_store: CredentialsStore = None,
                 ocr_service: OcrService = None):
        super().__init__()
        self._instagram = instagram_service or InstagramService()
        self._credentials = credentials_store or CredentialsStore()
        self._ocr = ocr_service or OcrService()
        self._pool = QThreadPool.globalInstance()
        self._login_in_progress = False

    def _run(self, fn, on_finished, on_error=None):
        worker = Worker(fn)
        worker.signals.finished.connect(on_finished)
        worker.signals.error.connect(on_error or self.error.emit)
        self._pool.start(worker)

    @Slot(str, str, bool)
    def login(self, username, password, remember=False):
        if self._login_in_progress:
            return  # Zaten devam eden bir giriş isteği var, yenisini başlatma
        if not username or not password:
            self.error.emit("Kullanıcı adı ve şifre boş olamaz.")
            return

        def on_finished(_):
            self._login_in_progress = False
            if remember:
                self._credentials.save(username, password)
            else:
                self._credentials.forget(username)
            self.loggedIn.emit(True)

        def on_error(msg):
            self._login_in_progress = False
            self.error.emit(msg)

        self._login_in_progress = True
        self._run(lambda: self._instagram.login(username, password), on_finished, on_error)

    @Slot(result=list)
    def loadSavedCredentials(self):
        """Kayıtlı kullanıcı adı/şifreyi döndürür: [kullanıcı_adı, şifre, hatırla]"""
        username, password, remember = self._credentials.load()
        return [username, password, remember]

    @Slot()
    def forgetCredentials(self):
        self._credentials.forget()

    @Slot()
    def loadCollections(self):
        self._run(self._instagram.collections, self.collectionsLoaded.emit)

    @Slot(str)
    def loadMedias(self, collection_pk):
        self._run(lambda: self._instagram.medias(collection_pk), self.mediasLoaded.emit)

    @Slot(str, str)
    def unsaveMedia(self, media_pk, collection_pk):
        def do():
            self._instagram.unsave_media(media_pk, collection_pk)
            return True
        # Çıkarma işlemi sonrasında liste otomatik olarak yenilenir
        self._run(do, lambda _: self.loadMedias(collection_pk))

    @Slot(str)
    def deleteCollection(self, collection_pk):
        def do():
            self._instagram.delete_collection(collection_pk)
            return True
        # Silme işlemi sonrasında koleksiyon listesi otomatik olarak yenilenir
        self._run(do, lambda _: self.loadCollections())

    @Slot(str, float, float, float, float)
    def recognizeTextInRegion(self, image_url, x, y, w, h):
        """x/y/w/h: kullanıcının seçtiği alan, görsel boyutuna göre 0-1
        aralığında oran (tüm görsel için 0,0,1,1)."""
        if not image_url:
            self.error.emit("Metin tanınacak bir görsel yok.")
            return
        if not self._ocr.is_available():
            self.error.emit(
                "Tesseract OCR bulunamadı. Kurulu olduğundan ve PATH'te "
                "olduğundan emin olun."
            )
            return

        def do():
            text = self._ocr.extract_text(image_url, x, y, w, h)
            return text or "Seçilen alanda metin bulunamadı."

        self._run(do, self.textRecognized.emit)

    @Slot(str, float)
    def recognizeTextInVideoFrame(self, video_url, position_seconds):
        """video_url'deki o anki (duraklatılmış) karenin tamamından metin okur."""
        if not video_url:
            self.error.emit("Metin tanınacak bir video yok.")
            return
        if not self._ocr.is_available():
            self.error.emit(
                "Tesseract OCR bulunamadı. Kurulu olduğundan ve PATH'te "
                "olduğundan emin olun."
            )
            return
        if not self._ocr.is_video_capture_available():
            self.error.emit(
                "ffmpeg bulunamadı. Videodan kare yakalamak için ffmpeg kurulu olmalı."
            )
            return

        def do():
            text = self._ocr.extract_text_from_video(video_url, position_seconds)
            return text or "Bu karede metin bulunamadı."

        self._run(do, self.textRecognized.emit)

    @Slot(str, float)
    def captureVideoFrame(self, video_url, position_seconds):
        """Videodan bir kare yakalayıp geçici bir dosyaya kaydeder; kullanıcı
        bu dondurulmuş kare üzerinde bir bölge seçebilsin diye (videoFrameCaptured
        sinyaliyle dosya yolu döner). OCR'ın kendisini tetiklemez."""
        if not video_url:
            self.error.emit("Kare yakalanacak bir video yok.")
            return
        if not self._ocr.is_video_capture_available():
            self.error.emit(
                "ffmpeg bulunamadı. Videodan kare yakalamak için ffmpeg kurulu olmalı."
            )
            return

        def do():
            path = self._ocr.capture_video_frame_to_file(video_url, position_seconds)
            return QUrl.fromLocalFile(path).toString()

        self._run(do, self.videoFrameCaptured.emit)
