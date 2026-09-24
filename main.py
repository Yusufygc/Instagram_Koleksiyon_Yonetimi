import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from backend import Backend

app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()

backend = Backend()
engine.rootContext().setContextProperty("backend", backend)

engine.load("qml/main.qml")
if not engine.rootObjects():
    sys.exit(-1)

sys.exit(app.exec())