import keyring
from PySide6.QtCore import QSettings

KEYRING_SERVICE = "InstagramKoleksiyonYoneticisi"


class CredentialsStore:
    """'Beni hatırla' tercihini güvenli şekilde saklar: şifre işletim
    sisteminin kimlik bilgisi deposunda (Windows Credential Manager,
    keyring üzerinden), kullanıcı adı ve tercih ise düz metin şifre
    içermeyen QSettings'te (registry) tutulur."""

    def __init__(self):
        self._settings = QSettings("InstagramKoleksiyonYoneticisi", "Ayarlar")

    def save(self, username, password):
        previous_username = self._settings.value("username", "", type=str)
        if previous_username and previous_username != username:
            self._delete_password(previous_username)

        self._settings.setValue("username", username)
        self._settings.setValue("remember", True)
        try:
            keyring.set_password(KEYRING_SERVICE, username, password)
        except Exception:
            pass  # Depo kullanılamıyorsa sessizce hatırlamadan devam et

    def forget(self, username=None):
        username = username or self._settings.value("username", "", type=str)
        self._settings.remove("username")
        self._settings.remove("remember")
        if username:
            self._delete_password(username)

    def load(self):
        """Kayıtlı kullanıcı adı/şifreyi döndürür: (kullanıcı_adı, şifre, hatırla)"""
        username = self._settings.value("username", "", type=str)
        remember = self._settings.value("remember", False, type=bool)
        password = ""
        if remember and username:
            try:
                password = keyring.get_password(KEYRING_SERVICE, username) or ""
            except Exception:
                password = ""
        return username, password, remember

    def _delete_password(self, username):
        try:
            keyring.delete_password(KEYRING_SERVICE, username)
        except Exception:
            pass
