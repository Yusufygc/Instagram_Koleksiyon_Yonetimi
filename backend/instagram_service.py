from instagrapi import Client

from .session_store import SessionStore


class InstagramService:
    """instagrapi Client'ı sarar; Instagram'a özgü tüm iş mantığını (giriş,
    koleksiyonlar, gönderiler, kaydı çıkarma) tek yerde toplar. Qt/QML'den
    tamamen bağımsızdır, bu yüzden ayrı test edilebilir/taklit edilebilir."""

    def __init__(self, session_store: SessionStore = None):
        self._session_store = session_store or SessionStore()
        self._client = None

    def login(self, username, password):
        client = Client()
        self._session_store.apply_to(client)

        # instagrapi mevcut oturumu önce doğrular, geçerliyse tekrar ağ
        # üzerinden giriş yapmaz.
        client.login(username, password)

        self._session_store.save_from(client)
        self._client = client

    def collections(self):
        collections = self._client.collections()
        return [{"id": c.id, "name": c.name, "count": c.media_count} for c in collections]

    def medias(self, collection_pk):
        medias = self._client.collection_medias(collection_pk, amount=0)
        return [self._media_dict(m) for m in medias]

    def unsave_media(self, media_pk, collection_pk):
        self._client.media_unsave(media_pk, collection_pk)

    def delete_collection(self, collection_pk):
        """Koleksiyonu, içindeki tüm gönderileri Kaydedilenler'den (Tüm
        Gönderiler dahil) çıkararak siler. instagrapi'de hazır bir metod
        olmadığından Instagram'ın özel API'sine doğrudan istek atılır."""
        medias = self._client.collection_medias(collection_pk, amount=0)
        for m in medias:
            try:
                self._client.media_unsave(m.pk)
            except Exception:
                pass  # Tekil bir gönderi başarısız olsa bile silme işlemine devam et

        self._client.private_request(
            f"collections/{collection_pk}/delete/",
            self._client.with_default_data({})
        )

    def _media_dict(self, m):
        cover = self._cover_url(m)
        return {
            "id": m.pk,
            "caption": m.caption_text or "",
            "thumbnail": cover,
            "preview": cover,
            "permalink": f"https://www.instagram.com/p/{m.code}/",
            "mediaType": m.media_type,  # 1=fotoğraf, 2=video, 8=carousel
            "videoUrl": str(m.video_url) if m.video_url else "",
            "resources": [self._resource_dict(r) for r in m.resources] if m.media_type == 8 else []
        }

    @staticmethod
    def _cover_url(m):
        """Kapak/önizleme görseli için mümkün olan en büyük çözünürlüklü
        adayı seç. Carousel gönderilerinde üst medyanın kendi görseli
        olmayabilir; bu durumda ilk slaytın görseline düşülür."""
        candidates = m.image_versions2.candidates if m.image_versions2 else []
        if candidates:
            best = max(candidates, key=lambda c: c.width * c.height)
            return str(best.url)
        if m.thumbnail_url:
            return str(m.thumbnail_url)
        if m.media_type == 8 and m.resources and m.resources[0].thumbnail_url:
            return str(m.resources[0].thumbnail_url)
        return ""

    @staticmethod
    def _resource_dict(r):
        return {
            "type": "video" if r.media_type == 2 else "photo",
            "thumbnail": str(r.thumbnail_url) if r.thumbnail_url else "",
            "video": str(r.video_url) if r.video_url else "",
        }
