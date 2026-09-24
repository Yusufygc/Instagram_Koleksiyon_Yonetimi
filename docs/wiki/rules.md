# Geliştirme ve Commit Kuralları

Bu doküman, projede kod yazarken, dosya düzenlerken ve Git versiyon kontrol sistemini kullanırken uyulması **zorunlu** olan kuralları ve ilkeleri tanımlar.

---

## 1. Git ve Commit Kuralları

Projeye katkı sağlanırken Git geçmişinin temiz, izlenebilir ve profesyonel kalması için aşağıdaki üç kural istisnasız uygulanır:

### 1.1. Türkçe Commit Mesajları
* Tüm commit başlıkları ve açıklamaları **Türkçe** olmalıdır.
* Yüklemler emir kipi veya geniş zaman/geçmiş zaman uyumuyla net ve kararlı ifade edilmelidir (Örn: *Düzelt*, *Ekle*, *Güncelle*, *Kaldır*).

### 1.2. Her Dosyaya Ayrı (Atomik) Commit
* Değişiklikler tek bir devasa commit içinde toplanmamalıdır (`git commit -a` veya tüm dosyaları birden sahnelemek yasaktır).
* **Her dosya veya birbirine sıkı sıkıya bağlı tekil mantıksal birim için ayrı bir commit oluşturulmalıdır.**
* Örnek: Hem `MediaViewer.qml` hem de `qml_bridge.py` dosyalarında değişiklik yapıldıysa;
  1. `git add backend/qml_bridge.py` -> `git commit -m "..."`
  2. `git add qml/components/MediaViewer.qml` -> `git commit -m "..."`
  şeklinde aşamalı commit atılmalıdır.

### 1.3. Sıfır AI / LLM Referansı
* Commit başlıklarında, açıklamalarında veya kod içi yorumlarda kesinlikle yapay zeka, model adı, asistan, prompt veya LLM referansı (**AI, Claude, GPT, Antigravity, Copilot, LLM, Assistant** vb.) yer alamaz.
* Değişiklikler projenin baş yazılımcısının kendi teknik kararı ve uygulaması gibi doğal bir dille belgelenmelidir.

### 1.4. Standart Commit Mesaj Formatı
Commit mesajlarında aşağıdaki etiket yapısı kullanılır:

```text
<tür>(<kapsam>): <kısa açıklama>

[varsa ayrıntılı açıklama]
```

* **feat**: Yeni bir özellik eklenmesi (Örn: `feat(ocr): Alan seçerek tarama desteği ekle`)
* **fix**: Hata düzeltmesi (Örn: `fix(video): Yakalanan kare için QUrl dosya yolu formatını düzelt`)
* **refactor**: Davranışı değiştirmeyen kod iyileştirmesi (Örn: `refactor(bridge): QThreadPool iş parçacığı mantığını modülerleştir`)
* **style**: Kod formatı, UI teması veya görsel rötuşlar (Örn: `style(dialog): OCR işlem durum göstergesini belirginleştir`)
* **docs**: Dokümantasyon veya wiki güncellemeleri (Örn: `docs(wiki): OCR koordinat hesaplama kılavuzunu ekle`)
* **chore**: Derleme, bağımlılık veya .gitignore düzenlemeleri (Örn: `chore(git): Kurulum ve derleme çıktı klasörlerini yoksay`)

---

## 2. Kodlama Standartları

### 2.1. Python (Backend)
* **PEP 8:** Kod stili PEP 8 yönergelerine tam uyumlu olmalıdır.
* **Tip İpuçları ve Açıklamalar:** Fonksiyon parametreleri ve dönüş tipleri açık olmalı; kritik algoritmalar Türkçe docstring ile belgelenmelidir.
* **Qt/Arayüz Ayrımı:** Backend iş mantığı (`InstagramService`, `OcrService` vb.) Qt bağımlılıklarından (`QObject`, `Signal`) tamamen yalıtılmış olmalıdır. Qt ile bağ yalnızca [[backend-servisleri|QmlBridge]] üzerinden kurulur.
* **Hata Yönetimi:** Beklenmeyen hatalar sessizce yutulmamalı (`except: pass` yerine spesifik hata yakalanmalı veya loglanmalıdır). Arayüz iş parçacığını dondurmamak için tüm ağ ve ağır disk/görüntü işlemleri [[backend-servisleri|Worker]] aracılığıyla arka planda çalıştırılmalıdır.

### 2.2. QML ve Tasarım Sistemi
* **Doğrudan Stil Tanımlamaktan Kaçınma:** Renkler, yazı boyutları ve boşluklar doğrudan hard-coded girilmemeli; [[arayuz-katmani|Theme.qml]] tasarım tokenları kullanılmalıdır.
* **Kesişim ve Koordinat Güvenliği:** Görsel/video üzerinde alan seçimi yapılırken letterbox (en-boy oranı koruma boşlukları) matematiksel olarak çıkarılmalı, görsel sınırları dışındaki alanlar elenmelidir ([[ocr-ve-medya|Detaylar]]).
* **Geri Bildirim İlkesi:** Kullanıcının başlattığı her işlemin (yükleme, tarama, silme) arayüzde açık bir görsel karşılığı (`BusyIndicator`, durum metni, devre dışı buton durumu) olmalıdır.

---

## 3. Dokümantasyon ve Wiki Disiplini

* Yapılan her mimari karar, kütüphane eklemesi veya hata çözümü anında `docs/wiki/` altındaki ilgili sayfaya işlenmelidir.
* Yeni eklenen her sayfa [[index|İçerik Haritası (index.md)]]'na eklenmeli ve [[log|Kayıt Defteri (log.md)]]'ne işlenmelidir.
* Sayfalar arasında Obsidian formatında çift köşeli parantezli linkleme (`[[sayfa_adi]]`) kullanılmalıdır.
