from PySide6.QtCore import QObject, QRunnable, Signal


class WorkerSignals(QObject):
    """Arka plan görevi sinyal taşıyıcısı"""
    finished = Signal(object)
    error = Signal(str)


class Worker(QRunnable):
    """Arayüz bloklanmasını önlemek için herhangi bir fonksiyonu arka plan
    iş parçacığında çalıştırır ve sonucu/hatayı sinyalle bildirir."""

    def __init__(self, fn, *args, **kwargs):
        super().__init__()
        self.fn = fn
        self.args = args
        self.kwargs = kwargs
        self.signals = WorkerSignals()

    def run(self):
        try:
            result = self.fn(*self.args, **self.kwargs)
            self.signals.finished.emit(result)
        except Exception as e:
            self.signals.error.emit(str(e))
