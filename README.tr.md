<div align="center">

# Pandermos

**Sunucunuzda sürekli çalışan Claude Code denetçisi.**
Sitelerinizi, uygulamalarınızı ve içeriğinizi belirlediğiniz takvimle kontrol eder. Güvenle düzeltebileceğini düzeltir. İnsan gerektiren bir şey olduğunda size kısa bir mesaj atar.

[English](README.md) · [Mimari](docs/ARCHITECTURE.md) · [Görev yazma](docs/WRITING-TASKS.md) · [Güvenlik](docs/SAFETY.md) · [Maliyet](docs/COST.md)

</div>

---

İzleme araçları bir şeyin bozulduğunu söyler. Pandermos ise gidip bakar:
- Günlükleri okur, sayfayı açar.
- Görseli indirip gerçekten inceler, haberi kaynağıyla karşılaştırır.
- Çöken servisi yeniden başlatır.
- Bir şeye dokunmadan önce yedek alır ve ne yaptığını yazar.

İçi bilerek sade tutuldu: tek bir Bash betiği, bir systemd birimi, Markdown görev dosyalarından oluşan bir klasör ve `claude -p`. Ayrı bir çatı, veritabanı ya da web arayüzü yok. Bütün kodu on dakikada okuyabilirsiniz.

## Nereden çıktı

Pandermos, Bandırma'nın antik adı. Proje de [pandermos.com](https://www.pandermos.com) yerel haber sitesinin gece editörü olarak başladı. Sitede botlar günde onlarca haber yayınlıyor ve hepsini tek tek okuyacak kimse yok. Sunucuya Claude Code'u kurup tek bir talimat verdik: her yeni habere bir editör gibi bak. Fotoğraftaki kişi gerçekten başlıktaki kişi mi? Kaynak, haberde yazanı söylüyor mu? Eski bir olay yeniymiş gibi mi yazılmış?

İşe yarayınca aynı döngüyü sunucudaki bütün sitelere, uygulamalara ve veritabanlarına açtık. Şimdi sunucuda çalışan SaaS ürününü de günde iki kez geliştiriyor.

Bu depo o sistemin, bize özel her şeyden arındırılmış hali.

## Ne yapar

| | |
|---|---|
| Takvimli görevler | Her görev bir Markdown dosyası. Düz metin bir takvim, hangi görevin hangi modelle, en fazla ne kadar sürede ve ne zaman çalışacağını söyler: `every N`, `at 04:00,14:00` ya da `manual`. |
| Düzeltme ya da denetim | Hangisinin olacağına `CLAUDE.md` dosyası ve verdiğiniz sudo yetkisi karar verir. |
| Önce yedek | Dosyalar, veritabanı satırları ve yazılar tarihli bir yedek klasörüne alınır, yolu rapora yazılır. Silmez, kenara taşır. |
| Hafıza | `notes.md` dosyası, görev başına durum dosyaları ve bir önceki rapor. |
| Sessiz bildirim | Temiz geçen çalıştırma mesaj atmaz, aynı mesaj iki kez gitmez, her gün bir özet gelir. Telegram ya da herhangi bir JSON webhook (Slack, Discord, ntfy, n8n). |
| İki deneme kuralı | Aynı sorunu iki kez düzeltemediyse üçüncüde yeniden denemez, size bildirir. |
| Abonelikle çalışır | Pro/Max planında `claude setup-token` jetonu ya da API anahtarı. Kullanım sınırına takılınca bir saat bekler. `pandermos usage` her görevin dakikasını, jetonunu ve API karşılığı maliyetini gösterir. |

## Hazır örnek görevler

| Görev | Baktığı şeyler |
|---|---|
| `server-health` | disk, bellek, çöken servisler, pm2/docker yeniden başlama döngüleri, yedeklerin tazeliği |
| `website-health` | sanal sunucuları kendisi bulur; HTTP kodu, yanıt süresi, TLS bitiş tarihi, 5xx ve ölümcül hatalar |
| `wordpress-news` | her yeni haberin görseline bakar, kaynağını açıp karşılaştırır, metni kontrol eder; düzeltir ya da yayından alır |
| `security` | girişler, kaba kuvvet denemeleri, yeni kullanıcı/anahtar/port, web kökünden sızan `.env` ve `.git`, uploads içindeki PHP |
| `app-logs` | hataları imzasına göre gruplar; yeni, süren, çözülen |
| `database` | PostgreSQL, MySQL ve Redis sağlığı, salt okunur |
| `improve` | bir sorun seçer, önce test yazar, kopyada düzeltir, pull request açar; birleştirmez, yayına almaz |

## Kurulum

```bash
git clone https://github.com/Oto-Pilot-seo/pandermos.git
cd pandermos
sudo ./install.sh
claude setup-token                              # tarayıcısı olan herhangi bir makinede
sudo nano /etc/pandermos/secrets.env            # jeton, Telegram
sudo nano /var/lib/pandermos/CLAUDE.md          # sunucunuzu tanıtın, düzeltme ya da denetim modunu seçin
sudo nano /etc/pandermos/schedule
sudo -u pandermos pandermos doctor
sudo -u pandermos pandermos run server-health
sudo systemctl enable --now pandermos
```

Düzeltme yetkisi vermek için:

```bash
sudo ./install.sh --sudo-commands "/usr/bin/systemctl restart nginx,/usr/sbin/nginx -t"
sudo ./install.sh --full-sudo      # tam yetki. Önce docs/SAFETY.md dosyasını okuyun.
```

## Komutlar

```text
pandermos loop                      zamanlayıcı (systemd bunu çalıştırır)
pandermos run <görev> [--model opus] [--timeout 40m] [--note "..."]
pandermos status                    her görevin son durumu
pandermos usage [gün]               görev başına çalıştırma, dakika ve maliyet
pandermos report <görev>            son raporu gösterir
pandermos notify "metin"            deneme bildirimi
pandermos doctor                    kurulumu kontrol eder
```

## Görev dosyaları Türkçe olabilir

Rapor sözleşmesi Türkçe satırları da tanır: `DURUM: TEMIZ | DUZELTILDI | UYARI | KRITIK` ve `TELEGRAM: ...`. Görevi Türkçe yazarsanız ajan da raporu Türkçe yazar.

## Sahada öğrendiklerimiz

- Baktırın. Dosya adına ve altyazısına göre seçilen bir fotoğraf, bir sağlık haberine kapak oldu. Fotoğraftaki pankartta "damızlık koç" yazıyordu. Artık kural şu: görseli indir, bak, başlıkla karşılaştır.
- "Düzeltme" işi bozabilir. Tekrar eden fotoğrafları değiştir dediğimizde ajan genel stok fotoğraflara uzandı: belediye haberine Ankara manzarası, telefon haberine devre kartı koydu. Uygun görsel yoksa dokunmamalı, raporlamalı. Alakasız bir düzeltme, düzeltme değildir.
- Arka planda bekletmeyin. İlk çalıştırmalar uzun bir işi arka planda başlatıp "takip ediyorum" diyerek rapor yazmadan bitti. Artık arka plan işi yasak, rapor her durumda zorunlu.
- Eski günlük satırları yanıltır. pm2 günlüklerinde zaman damgası olmadığı için haftalık satırlardan "kota bitti" alarmı çıktı. Tarihini bilmediği satırdan alarm üretmemeli.
- İki denemeden sonra insan. Aynı sorunu tekrar tekrar düzeltmeye çalışmak sonsuz döngüye dönüşüyordu.
- Önce yedek. Raporlardaki her değişikliğin yanında bir yedek yolu var.

## Lisans

MIT
