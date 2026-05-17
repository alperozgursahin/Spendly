# SPENDLY - PROJE HAFIZASI (PROJECT MEMORY)

## 1. Proje �zeti
Spendly; bireysel gelir-gider takibi ve grup harcamalar�n� y�neten, App Store/Play Store odakl�, profesyonel bir SaaS uygulamas�d�r. Vizyon; "Sosyal Finans Platformu" olmak, yani sadece harcama girmek de�il, WhatsApp/Revolut hibritinde, arkada�l�klar (Social Split) �zerinden finans y�r�tmektir.

## 2. Teknik Stack
- **Frontend:** Flutter
- **State Management:** Riverpod (Feature-first architecture)
- **Backend:** Supabase (Auth, DB, RLS, Storage, Realtime)
- **Monetization:** RevenueCat
- **Hata Takibi:** Sentry

## 3. Veri Modeli & Mimari
- **Klas�r Yap�s�:** lib/features/ alt�nda uth, dashboard, 	ransactions, groups, profile ve social (yeni) klas�rleri.
- **DB Tablolar�:** profiles, 	ransactions, groups, group_members, group_transactions, riendships, direct_messages.
  - **Yeni (Sosyal & DM):** profiles i�in benzersiz username, riendships (arkada�l�k ili�kisi), ve direct_messages (DM) altyap�s�.
  - **Yeni Tablo (group_transactions):** id, group_id, payer_id, mount, description, split_type (equal, percentage, exact), split_data (JSONB), created_at.
- **Grup Vizyonu (Revolut/WhatsApp Hibrit):** Grup detay sayfas� statik bir liste de�il, WhatsApp tarz� ger�ek zamanl� bir 'Activity Feed' (Olay Ak���) olacak. Ayr�ca bir "Grup Bilgisi" ekran� bulunacak.
- **Balance Engine:** Gruptaki net bor�/alacak durumunu hesaplayan merkezi bir servis planlanacak.
- **G�venlik (RLS):** Her tabloda RLS aktif. T�m mesajlar sadece ilgili taraflara.

## 4. Kritik Kurallar & Standartlar
- **�retim Standart�:** T�m hassas veriler lutter_secure_storage ile saklanacak.
- **Performans:** Listeler sayfalama (pagination) ile �ekilecek. DM ve aktivite ak��lar�nda Realtime kullan�lacak.
- **Hukuki:** Profil ekran�nda "Hesab� ve Verileri Sil" fonksiyonu zorunlu.
- **MVP S�n�r�:** Banka API entegrasyonu ve OCR (fi� okuma) �u an kapsam d���.

## 5. Mevcut Durum
- Auth (Email/Şifre), Transactions (Gelir/Gider), ve Temel Groups UI tamamlandı. Paywall kısmen var.
- **Yeni Eklenen (Sosyal Devrim):** Benzersiz username yapısı ile onboarding, "Social" tab'ı ile mesajlaşma/arkadaşlık ve doğrudan arkadaş listesinden gruba davet mekaniği (WhatsApp stili) kuruldu.
- **Bug Fix (Arkadaşlık):** Aynı kişiye birden fazla arkadaşlık isteği gönderilmesi engellendi (Hem pending hem accepted durumları Supabase'den kontrol ediliyor).
- **Global Currency (Riverpod):** Uygulamadaki sabit '$' ve '₺' işaretleri merkezi `currencyProvider` ile yönetilebilir hale getirildi ve profil menüsüne seçenek eklendi.
- **Dashboard UI/UX Yenilemesi (Premium FinTech):**
  - Tüm Dashboard, Material 3 standartlarında, yüksek border-radius, gölgelendirmeler ve Inter yazı tipine hazır güncellendi.
  - Quick Add (Hızlı Ekle) widget'ı Stateful widget'a çıkarılarak içine Income/Expense (Gelir/Gider) için "SegmentedButton" konuldu. Kategoriler "Dropdown" ile (Maaş, Ulaşım vd.) + "Diğer" seçildiğinde elle girilebilir yapıldı.
  - Pie Chart veri hazırlığında case sensitivity (büyük/küçük harf eşitsizlikleri) sorunu fixlendi (`.trim().toLowerCase()` kullanıldı).
  - Aktivite akışı ve statik tarihler ile son işlemler listesi modernize edilerek tutarlar `currencyProvider`'dan çekildi.
- **Grup Harcamaları:** `AddExpenseSheet` içerisine Slider entegre edilerek, tutarın yüzdelik (`%`) veya tam tutar (`₺`) olarak Slider ile dinamik hesaplanması sağlandı. `CurrencyProvider` buraya da entegre edildi.

## 6. Son Güncelleme (Modules 1-5 yeniden uygulandı)

- **Module 1 (Core & UI Overhaul):** Material 3 teması güçlendirildi, `scaffoldBackgroundColor` temiz Off-White `#F8F9FA` olarak sabitlendi ve `surfaceTintColor` transparent yapıldı. `CardTheme` yumuşak kenar ve hafif gölge ile güncellendi. Global `currencyProvider` (Riverpod) mevcut ve uygulatıldı.

- **Module 2 (Dashboard):** Tarihler sol tarafta sabitlendi; pasta grafik `fl_chart` ile eklendi ve kategori stringleri `sanitizeCategory` ile normalize edilerek büyük/küçük harf farklılıkları giderildi. Sosyal aktivite akışı Supabase'den çekiliyor.

- **Module 3 (Activation Heatmap):** Özelleştirilmiş ısı haritası kartı eklendi (pinned Y-axis Türkçe etiketleri: Pzt..Paz), üstünde aralık `SegmentedButton` (1A/3A/6A/1Y). `heatmapRangeProvider` ve `heatmapDataProvider` eklendi; 1A modu için dinamik blok boyutlaması uygulanıyor.

- **Module 4 (Quick Add):** Hızlı ekle widget'ı yeniden inşa edildi; `SegmentedButton` ile Gelir/Gider seçimi, kategori `Dropdown` ve `Diğer` seçildiğinde özel giriş alanı gösteriliyor. Miktar prefix'i `currencyProvider`'ı izliyor.

- **Module 5 (Group Expenses & Bug Fixes):** Grup split UI'sinde Slider mevcut; `sendFriendRequest` fonksiyonu Supabase'de mevcut ilişkileri (pending/accepted) kontrol ederek tekrar istekleri engelliyor.

Not: Kod değişiklikleri `lib/main.dart`, `lib/features/dashboard/dashboard_screen.dart`, `lib/features/dashboard/heatmap_provider.dart` ve birkaç yardımcı sağlayıcı üzerinde yapıldı. Derleme sırasında paket bağımlılıkları (`fl_chart`, `flutter_heatmap_calendar`) zaten `pubspec.yaml` içinde yer alıyor.
