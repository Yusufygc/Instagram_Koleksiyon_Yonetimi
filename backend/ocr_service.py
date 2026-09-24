import os
import shutil
import subprocess
import tempfile
import urllib.parse
from io import BytesIO

import pytesseract
import requests
from PIL import Image

_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

# Windows'ta winget/UB-Mannheim installer PATH'e eklese bile mevcut kabuk
# oturumu bunu görmeyebilir; yaygın kurulum yolunu yedek olarak dene.
_FALLBACK_TESSERACT_PATHS = [
    r"C:\Program Files\Tesseract-OCR\tesseract.exe",
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
]

_FALLBACK_FFMPEG_PATHS = [
    r"C:\ffmpeg\bin\ffmpeg.exe",
]

# Tesseract küçük/düşük çözünürlüklü kırpımlarda zorlanır; belirli bir
# genişliğin altındaki seçimleri büyütmek doğruluğu belirgin artırır.
_MIN_OCR_WIDTH = 700


class OcrService:
    """Görsel URL'sinden veya bir video karesinden (tamamı veya seçilen bir
    bölgesi) metin çıkarır (Tesseract OCR). Video kareleri ffmpeg ile
    yakalanır. Instagram gönderilerine gömülü yazıları okumak için
    kullanılır."""

    def __init__(self, languages="tur+eng"):
        self._languages = languages
        self._ffmpeg_cmd = self._resolve_ffmpeg_path()
        self._configure_tesseract_path()
        self._last_captured_frame_path = None

    @staticmethod
    def _configure_tesseract_path():
        if shutil.which("tesseract"):
            return
        for path in _FALLBACK_TESSERACT_PATHS:
            try:
                with open(path, "rb"):
                    pytesseract.pytesseract.tesseract_cmd = path
                    return
            except OSError:
                continue

    @staticmethod
    def _resolve_ffmpeg_path():
        if shutil.which("ffmpeg"):
            return "ffmpeg"
        for path in _FALLBACK_FFMPEG_PATHS:
            try:
                with open(path, "rb"):
                    return path
            except OSError:
                continue
        return None

    def is_available(self):
        try:
            pytesseract.get_tesseract_version()
            return True
        except Exception:
            return False

    def is_video_capture_available(self):
        return self._ffmpeg_cmd is not None

    def extract_text(self, image_source, x=0.0, y=0.0, w=1.0, h=1.0):
        """image_source: bir http(s) URL'si veya yerel bir dosya yolu (ör.
        capture_video_frame_to_file'ın döndürdüğü yol) olabilir.
        x/y/w/h: görselin genişlik/yüksekliğine göre 0-1 aralığında oran.
        Varsayılanlar (0,0,1,1) görselin tamamını kapsar."""
        image = self._load_source_image(image_source)
        return self._recognize(image, x, y, w, h)

    def extract_text_from_video(self, video_url, position_seconds, x=0.0, y=0.0, w=1.0, h=1.0):
        """video_url'deki belirtilen saniyedeki kareyi yakalayıp metnini çıkarır."""
        frame = self._capture_video_frame(video_url, position_seconds)
        return self._recognize(frame, x, y, w, h)

    def capture_video_frame_to_file(self, video_url, position_seconds):
        """Videodan bir kare yakalayıp geçici bir PNG dosyasına kaydeder;
        kullanıcının QML tarafında görüp üzerinde alan seçebilmesi için.
        Önceki yakalanan kareyi (varsa) temizler."""
        frame = self._capture_video_frame(video_url, position_seconds)
        if self._last_captured_frame_path:
            try:
                os.remove(self._last_captured_frame_path)
            except OSError:
                pass
        fd, path = tempfile.mkstemp(suffix=".png", prefix="ig_ocr_frame_")
        os.close(fd)
        frame.save(path)
        self._last_captured_frame_path = path
        return path

    def _recognize(self, image, x, y, w, h):
        cropped = self._crop(image, x, y, w, h)
        cropped = self._upscale_if_small(cropped)
        text = pytesseract.image_to_string(cropped, lang=self._languages)
        return text.strip()

    def _load_source_image(self, source):
        if source.startswith("http://") or source.startswith("https://"):
            return self._download_image(source)
        path = source
        if path.startswith("file:///"):
            path = urllib.parse.unquote(path[8:])
        elif path.startswith("file://"):
            path = urllib.parse.unquote(path[7:])
        else:
            path = urllib.parse.unquote(path)
        return Image.open(path).convert("RGB")

    def _download_image(self, image_url):
        # Bazı CDN'ler (Instagram dahil) varsayılan requests User-Agent'ını reddedebilir
        response = requests.get(image_url, headers={"User-Agent": _USER_AGENT}, timeout=15)
        response.raise_for_status()
        return Image.open(BytesIO(response.content)).convert("RGB")

    def _capture_video_frame(self, video_url, position_seconds):
        if not self._ffmpeg_cmd:
            raise RuntimeError(
                "ffmpeg bulunamadı. Video karesi yakalamak için ffmpeg kurulu olmalı."
            )
        position_seconds = max(0.0, float(position_seconds))
        cmd = [
            self._ffmpeg_cmd, "-y",
            "-user_agent", _USER_AGENT,
            "-ss", str(position_seconds),
            "-i", video_url,
            "-frames:v", "1",
            "-update", "1",
            "-f", "image2",
            "-vcodec", "png",
            "pipe:1",
        ]
        proc = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30
        )
        if proc.returncode != 0 or not proc.stdout:
            stderr_tail = proc.stderr[-400:].decode(errors="replace")
            raise RuntimeError(f"Video karesi yakalanamadı: {stderr_tail}")
        return Image.open(BytesIO(proc.stdout)).convert("RGB")

    @staticmethod
    def _crop(image, x, y, w, h):
        iw, ih = image.size
        left = max(0, min(iw, int(x * iw)))
        top = max(0, min(ih, int(y * ih)))
        right = max(left + 1, min(iw, int((x + w) * iw)))
        bottom = max(top + 1, min(ih, int((y + h) * ih)))
        return image.crop((left, top, right, bottom))

    @staticmethod
    def _upscale_if_small(image):
        if image.width >= _MIN_OCR_WIDTH:
            return image
        scale = _MIN_OCR_WIDTH / max(image.width, 1)
        new_size = (int(image.width * scale), int(image.height * scale))
        return image.resize(new_size, Image.LANCZOS)
