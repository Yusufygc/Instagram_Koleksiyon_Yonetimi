from PySide6.QtCore import QObject, Signal, Slot, QThreadPool, QRunnable
from instagrapi import Client

import os
from dotenv import load_dotenv

load_dotenv()
username = os.getenv("IG_USERNAME")
password = os.getenv("IG_PASSWORD")

class WorkerSignals(QObject):
    finished = Signal(object)
    error = Signal(str)

class Worker(QRunnable):
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

class Backend(QObject):
    collectionsLoaded = Signal(list)
    mediasLoaded = Signal(list)
    loggedIn = Signal(bool)
    error = Signal(str)

    def __init__(self):
        super().__init__()
        self.cl = None
        self.pool = QThreadPool.globalInstance()

    def _run(self, fn, on_finished, *args):
        worker = Worker(fn, *args)
        worker.signals.finished.connect(on_finished)
        worker.signals.error.connect(self.error.emit)
        self.pool.start(worker)

    @Slot(str, str)
    def login(self, username, password):
        def do_login():
            cl = Client()
            cl.login(username, password)
            return cl
        def on_done(cl):
            self.cl = cl
            self.loggedIn.emit(True)
        self._run(do_login, on_done)

    @Slot()
    def loadCollections(self):
        def do():
            return [{"id": c.id, "name": c.name} for c in self.cl.collections()]
        self._run(do, self.collectionsLoaded.emit)

    @Slot(str)
    def loadMedias(self, collection_pk):
        def do():
            medias = self.cl.collection_medias(collection_pk, amount=0)
            return [{
                "id": m.pk,
                "caption": m.caption_text or "",
                "thumbnail": str(m.thumbnail_url)
            } for m in medias]
        self._run(do, self.mediasLoaded.emit)

    @Slot(str, str)
    def unsaveMedia(self, media_pk, collection_pk):
        def do():
            self.cl.media_unsave(media_pk, collection_pk)
            return True
        self._run(do, lambda _: self.loadMedias(collection_pk))