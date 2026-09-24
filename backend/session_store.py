import os
import stat
import sys


class SessionStore:
    """instagrapi oturum dosyasının (session.json) konumunu, okunmasını,
    yazılmasını ve dosya izinlerinin kısıtlanmasını yönetir."""

    def __init__(self, filename="session.json"):
        # Uygulama nereden çalıştırılırsa çalıştırılsın aynı dosyayı kullan
        base_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
        self.path = os.path.join(base_dir, filename)

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
