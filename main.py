import os
import sys

# QtMultimedia'nın FFmpeg backend'i, önizleme kapanırken video akışı aniden
# kesildiğinde "Could not update timestamps..." / "Failed to send close
# message" gibi zararsız tanı uyarılarını konsola basar. Bu kategoriler
# QGuiApplication oluşturulmadan önce susturulmalı.
os.environ["QT_LOGGING_RULES"] = (
    "qt.multimedia*=false;"
    "qt.multimedia.ffmpeg*=false;"
    "qt.multimedia.warning=false;"
    "qt.multimedia.ffmpeg.warning=false"
)

from dotenv import load_dotenv
from PySide6.QtCore import QLoggingCategory
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle
from backend import Backend

QLoggingCategory.setFilterRules(
    "qt.multimedia*=false\n"
    "qt.multimedia.ffmpeg*=false\n"
    "qt.multimedia.warning=false\n"
    "qt.multimedia.ffmpeg.warning=false"
)


def resource_path(*parts):
    """Geliştirmede dosyaya göre, PyInstaller ile paketlenmiş .exe'de
    _MEIPASS (onefile) ya da .exe'nin bulunduğu klasöre (onedir) göre yol
    döndürür; böylece aynı kod her iki durumda da çalışır."""
    if getattr(sys, "frozen", False):
        base = getattr(sys, "_MEIPASS", os.path.dirname(sys.executable))
    else:
        base = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base, *parts)


load_dotenv()  # Test için .env dosyasından INSTAGRAM_USERNAME / INSTAGRAM_PASSWORD okur

# Sayfalar artık ayrı QML dosyalarında; stil motor yüklenmeden önce açıkça
# ayarlanmazsa her dosya varsayılan (Basic) stile düşer.
QQuickStyle.setStyle("Material")

app = QGuiApplication(sys.argv)
app.setWindowIcon(QIcon(resource_path("assets", "app_icon.ico")))

engine = QQmlApplicationEngine()

backend = Backend()
engine.rootContext().setContextProperty("backend", backend)
# Sadece test kolaylığı: .env varsa giriş alanlarını önceden doldur, otomatik giriş yapmaz
engine.rootContext().setContextProperty("envUsername", os.environ.get("INSTAGRAM_USERNAME", ""))
engine.rootContext().setContextProperty("envPassword", os.environ.get("INSTAGRAM_PASSWORD", ""))

engine.load(resource_path("qml", "main.qml"))
if not engine.rootObjects():
    sys.exit(-1)

sys.exit(app.exec())