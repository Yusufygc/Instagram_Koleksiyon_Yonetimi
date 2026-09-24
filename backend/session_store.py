import os
import shutil
import stat
import sys


def get_user_data_dir(app_name="InstagramKoleksiyonYoneticisi"):
    """İşletim sistemine uygun kullanıcı veri dizinini döndürür ve klasörü oluşturur."""
    if sys.platform == "win32":
        base = os.environ.get("LOCALAPPDATA") or os.path.expanduser("~")
    elif sys.platform == "darwin":
        base = os.path.expanduser("~/Library/Application Support")
    else:
        base = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    app_dir = os.path.join(base, app_name)
    os.makedirs(app_dir, exist_ok=True)
    return app_dir


class SessionStore:
    """instagrapi oturum dosyasının (session.json) konumunu, okunmasını,
    yazılmasını ve dosya izinlerinin kısıtlanmasını yönetir. Dosyayı Program
    Files yerine kullanıcının yerel veri dizininde (LOCALAPPDATA) barındırarak
    izin hatalarını önler."""

    def __init__(self, filename="session.json"):
        storage_dir = get_user_data_dir()
        self.path = os.path.join(storage_dir, filename)

        # Eski çalışma dizininde var olan bir session.json varsa ve yeni yerde
        # henüz yoksa, kullanıcı oturumunu yeni konuma kopyala.
        if not os.path.exists(self.path):
            base_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
            old_path = os.path.join(base_dir, filename)
            if os.path.exists(old_path) and os.path.isfile(old_path):
                try:
                    shutil.copy2(old_path, self.path)
                except OSError:
                    pass

    def exists(self):
        return os.path.exists(self.path)

    def apply_to(self, client, override_app_version=True):
        """Kaydedilmiş oturumu verilen instagrapi Client'a yükler.
        override_app_version=True: eski/tutarsız bir app_version -
        bloks_versioning_id eşleşmesi varsa (örn. kütüphane güncellendi)
        instagrapi'nin güncel, kendi içinde tutarlı profiline geçer."""
        if not self.exists():
            return
        try:
            client.load_settings(self.path, override_app_version=override_app_version)
        except Exception:
            pass  # Oturum geçersizse normal girişe devam et

    def save_from(self, client):
        client.dump_settings(self.path)
        self._restrict_permissions()

    def _restrict_permissions(self):
        """Oturum dosyasını yalnızca sahibi okuyabilsin diye izinleri kısıtla"""
        try:
            os.chmod(self.path, stat.S_IRUSR | stat.S_IWUSR)
        except Exception:
            pass  # Windows gibi platformlarda no-op olabilir
