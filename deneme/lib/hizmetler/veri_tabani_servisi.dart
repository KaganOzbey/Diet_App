import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../modeller/kullanici_modeli.dart';
import '../modeller/yemek_ogesi_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../modeller/ozel_besin_modeli.dart';
import '../modeller/kilo_girisi_modeli.dart';

class VeriTabaniServisi {
  static const String _kullaniciKutusu = 'kullaniciKutusu';
  static const String _yemekOgesiKutusu = 'yemekOgesiKutusu';
  static const String _ogunGirisiKutusu = 'ogunGirisiKutusu';
  static const String _gunlukBeslenmeKutusu = 'gunlukBeslenmeKutusu';
  static const String _ozelBesinKutusu = 'ozelBesinKutusu';
  static const String _kiloGirisiKutusu = 'kiloGirisiKutusu';
  static const String _aktifKullaniciAnahtari = 'aktifKullanici';

  static final Uuid _uuidUretici = Uuid();

  // Hive veritabanını başlat
  static Future<void> baslat() async {
    try {
      await Hive.initFlutter();
      
      // Model adaptörlerini kaydet
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(KullaniciModeliAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(YemekOgesiModeliAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(OgunGirisiModeliAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(GunlukBeslenmeModeliAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(OzelBesinModeliAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(KiloGirisiModeliAdapter());
      }

      // Kutuları aç
      await Hive.openBox<KullaniciModeli>(_kullaniciKutusu);
      await Hive.openBox<YemekOgesiModeli>(_yemekOgesiKutusu);
      await Hive.openBox<OgunGirisiModeli>(_ogunGirisiKutusu);
      await Hive.openBox<GunlukBeslenmeModeli>(_gunlukBeslenmeKutusu);
      await Hive.openBox<OzelBesinModeli>(_ozelBesinKutusu);
      await Hive.openBox<KiloGirisiModeli>(_kiloGirisiKutusu);
      
      print('Hive veritabanı başarıyla başlatıldı');
    } catch (e) {
      print('Hive başlatma hatası: $e');
      
      // TypeAdapter hatası durumunda tüm Hive verilerini sil
      if (e.toString().contains('TypeAdapter')) {
        print('TypeAdapter hatası tespit edildi, veriler temizleniyor...');
        await temizleVeYenidenBaslat();
      } else {
        rethrow;
      }
    }
  }

  // Hive verilerini temizle ve yeniden başlat
  static Future<void> temizleVeYenidenBaslat() async {
    try {
      // Tüm Hive verilerini sil
      await Hive.deleteFromDisk();
      print('Tüm Hive verileri silindi');
      
      // Yeniden başlat
      await Hive.initFlutter();
      
      // Adapter'ları tekrar kaydet
      Hive.registerAdapter(KullaniciModeliAdapter());
      Hive.registerAdapter(YemekOgesiModeliAdapter());
      Hive.registerAdapter(OgunGirisiModeliAdapter());
      Hive.registerAdapter(GunlukBeslenmeModeliAdapter());
      Hive.registerAdapter(OzelBesinModeliAdapter());
      Hive.registerAdapter(KiloGirisiModeliAdapter());

      // Kutuları aç
      await Hive.openBox<KullaniciModeli>(_kullaniciKutusu);
      await Hive.openBox<YemekOgesiModeli>(_yemekOgesiKutusu);
      await Hive.openBox<OgunGirisiModeli>(_ogunGirisiKutusu);
      await Hive.openBox<GunlukBeslenmeModeli>(_gunlukBeslenmeKutusu);
      await Hive.openBox<OzelBesinModeli>(_ozelBesinKutusu);
      await Hive.openBox<KiloGirisiModeli>(_kiloGirisiKutusu);
      
      print('Hive veritabanı temizlendikten sonra başarıyla başlatıldı');
    } catch (e) {
      print('Temizleme sonrası başlatma hatası: $e');
      throw Exception('Hive veritabanı başlatılamadı: $e');
    }
  }

  // Kutu referansları
  static Box<KullaniciModeli> get _kullaniciKutusuRef => Hive.box<KullaniciModeli>(_kullaniciKutusu);
  static Box<YemekOgesiModeli> get _yemekOgesiKutusuRef => Hive.box<YemekOgesiModeli>(_yemekOgesiKutusu);
  static Box<OgunGirisiModeli> get _ogunGirisiKutusuRef => Hive.box<OgunGirisiModeli>(_ogunGirisiKutusu);
  static Box<GunlukBeslenmeModeli> get _gunlukBeslenmeKutusuRef => Hive.box<GunlukBeslenmeModeli>(_gunlukBeslenmeKutusu);
  static Box<KiloGirisiModeli> get _kiloGirisiKutusuRef => Hive.box<KiloGirisiModeli>(_kiloGirisiKutusu);

  // ============ KULLANICI İŞLEMLERİ ============

  // Yeni kullanıcı oluştur
  static Future<KullaniciModeli> kullaniciOlustur({
    required String email,
    required String isim,
    required double boy,
    required double kilo,
    required int yas,
    required bool erkekMi,
    int aktiviteSeviyesi = 2,
  }) async {
    final simdi = DateTime.now();
    final kullanici = KullaniciModeli(
      uid: _uuidUretici.v4(),
      email: email,
      isim: isim,
      boy: boy,
      kilo: kilo,
      yas: yas,
      erkekMi: erkekMi,
      aktiviteSeviyesi: aktiviteSeviyesi,
      olusturulmaTarihi: simdi,
      guncellemeTarihi: simdi,
    );

    // BMR ve günlük kalori hedefini hesapla
    kullanici.bmr = kullanici.bmrHesapla();
    kullanici.gunlukKaloriHedefi = kullanici.gunlukKaloriIhtiyaci();

    await _kullaniciKutusuRef.put(kullanici.id, kullanici);
    await aktifKullaniciAyarla(kullanici);
    return kullanici;
  }

  // Aktif kullanıcıyı ayarla
  static Future<void> aktifKullaniciAyarla(KullaniciModeli kullanici) async {
    final ayarlarKutusu = await Hive.openBox('ayarlar');
    await ayarlarKutusu.put(_aktifKullaniciAnahtari, kullanici.id);
  }

  // Aktif kullanıcıyı getir
  static Future<KullaniciModeli?> aktifKullaniciGetir() async {
    try {
      final ayarlarKutusu = await Hive.openBox('ayarlar');
      final kullaniciId = ayarlarKutusu.get(_aktifKullaniciAnahtari) as String?;
      if (kullaniciId != null) {
        return _kullaniciKutusuRef.get(kullaniciId);
      }
    } catch (e) {
      print('Aktif kullanıcı getirme hatası: $e');
    }
    return null;
  }

  // Kullanıcı güncelle
  static Future<void> kullaniciGuncelle(KullaniciModeli kullanici) async {
    kullanici.guncellemeTarihi = DateTime.now();
    await kullanici.save();
  }

  // Tüm kullanıcıları getir
  static List<KullaniciModeli> tumKullanicilariGetir() {
    return _kullaniciKutusuRef.values.toList();
  }

  // Email ile kullanıcı bul
  static Future<KullaniciModeli?> kullaniciIdileBul(String email) async {
    try {
      return _kullaniciKutusuRef.values.firstWhere(
        (kullanici) => kullanici.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      print('Kullanıcı bulunamadı: $email');
      return null;
    }
  }

  // Mevcut kullanıcıyı kaydet (migration için)
  static Future<void> mevcutKullaniciKaydet(KullaniciModeli kullanici) async {
    await _kullaniciKutusuRef.put(kullanici.id, kullanici);
    print('Mevcut kullanıcı veritabanına kaydedildi: ${kullanici.email}');
  }

  // Kullanıcıyı ve ilgili tüm verilerini sil
  static Future<void> kullaniciSil(String kullaniciId) async {
    try {
      print('VeriTabaniServisi: Kullanıcı silme işlemi başlıyor - ID: $kullaniciId');
      
      // 1. Kullanıcının öğün girişlerini sil
      final ogunGirisleri = _ogunGirisiKutusuRef.values
          .where((giris) => giris.kullaniciId == kullaniciId)
          .toList();
      
      print('VeriTabaniServisi: ${ogunGirisleri.length} öğün girişi siliniyor...');
      for (final giris in ogunGirisleri) {
        await _ogunGirisiKutusuRef.delete(giris.id);
      }
      
      // 2. Kullanıcının günlük beslenme verilerini sil
      final gunlukBeslenmeAnahtarlari = _gunlukBeslenmeKutusuRef.keys
          .where((anahtar) => anahtar.toString().startsWith(kullaniciId))
          .toList();
      
      print('VeriTabaniServisi: ${gunlukBeslenmeAnahtarlari.length} günlük beslenme kaydı siliniyor...');
      for (final anahtar in gunlukBeslenmeAnahtarlari) {
        await _gunlukBeslenmeKutusuRef.delete(anahtar);
      }
      
      // 3. Kullanıcıyı sil
      await _kullaniciKutusuRef.delete(kullaniciId);
      
      // 4. Aktif kullanıcı bu kullanıcıysa ayarları temizle
      final ayarlarKutusu = await Hive.openBox('ayarlar');
      final aktifKullaniciId = ayarlarKutusu.get('aktifKullanici');
      if (aktifKullaniciId == kullaniciId) {
        await ayarlarKutusu.delete('aktifKullanici');
      }
      
      print('VeriTabaniServisi: Kullanıcı ve tüm verileri başarıyla silindi');
      
    } catch (e) {
      print('VeriTabaniServisi: Kullanıcı silme hatası: $e');
      throw Exception('Kullanıcı silinemedi: $e');
    }
  }

  // ============ YEMEK ÖGESİ İŞLEMLERİ ============

  // Yemek ögesi kaydet
  static Future<YemekOgesiModeli> yemekOgesiKaydet({
    required String isim,
    required int fdcId,
    required double yuzGramKalori,
    double yuzGramProtein = 0.0,
    double yuzGramKarbonhidrat = 0.0,
    double yuzGramYag = 0.0,
    double yuzGramLif = 0.0,
    double yuzGramSeker = 0.0,
    String kategori = 'Genel',
  }) async {
    final yemekOgesi = YemekOgesiModeli(
      id: _uuidUretici.v4(),
      isim: isim,
      fdcId: fdcId,
      yuzGramKalori: yuzGramKalori,
      yuzGramProtein: yuzGramProtein,
      yuzGramKarbonhidrat: yuzGramKarbonhidrat,
      yuzGramYag: yuzGramYag,
      yuzGramLif: yuzGramLif,
      yuzGramSeker: yuzGramSeker,
      kategori: kategori,
      eklenmeTarihi: DateTime.now(),
    );

    await _yemekOgesiKutusuRef.put(yemekOgesi.id, yemekOgesi);
    return yemekOgesi;
  }

  // ID ile yemek ögesi getir
  static YemekOgesiModeli? yemekOgesiGetir(String id) {
    return _yemekOgesiKutusuRef.get(id);
  }

  // FDC ID ile yemek ögesi bul
  static YemekOgesiModeli? fdcIdIleYemekOgesiBul(int fdcId) {
    try {
      return _yemekOgesiKutusuRef.values.firstWhere(
        (yemek) => yemek.fdcId == fdcId,
      );
    } catch (e) {
      return null;
    }
  }

  // İsim ile yemek ara
  static List<YemekOgesiModeli> isimIleYemekAra(String isim) {
    return _yemekOgesiKutusuRef.values
        .where((yemek) => yemek.isim.toLowerCase().contains(isim.toLowerCase()))
        .toList();
  }

  // Favori yemekleri getir
  static List<YemekOgesiModeli> favoriYemekleriGetir() {
    return _yemekOgesiKutusuRef.values.where((yemek) => yemek.favoriMi).toList();
  }

  // Yemek favori durumunu değiştir
  static Future<void> yemekFavoriDurumunuDegistir(String yemekId) async {
    final yemek = _yemekOgesiKutusuRef.get(yemekId);
    if (yemek != null) {
      yemek.favoriMi = !yemek.favoriMi;
      await yemek.save();
    }
  }

  // ============ ÖĞÜN GİRİŞİ İŞLEMLERİ ============

  // Öğün girişi ekle
  static Future<OgunGirisiModeli> ogunGirisiEkle({
    required String kullaniciId,
    required YemekOgesiModeli yemekOgesi,
    required double gramMiktari,
    required String ogunTipi,
    DateTime? tuketimTarihi,
  }) async {
    print('VeriTabaniServisi: Öğün girişi ekleniyor...');
    print('VeriTabaniServisi: Kullanıcı ID: $kullaniciId');
    print('VeriTabaniServisi: Yemek: ${yemekOgesi.isim}');
    print('VeriTabaniServisi: Gram miktarı: $gramMiktari');
    print('VeriTabaniServisi: Öğün tipi: $ogunTipi');
    
    final ogunGirisi = OgunGirisiModeli.yemektenOlustur(
      kullaniciId: kullaniciId,
      yemekOgesi: yemekOgesi,
      gramMiktari: gramMiktari,
      ogunTipi: ogunTipi,
      tuketimTarihi: tuketimTarihi,
    );

    print('VeriTabaniServisi: Öğün girişi oluşturuldu - ID: ${ogunGirisi.id}');
    print('VeriTabaniServisi: Kalori: ${ogunGirisi.kalori}');
    print('VeriTabaniServisi: Veritabanına kaydediliyor...');

    await _ogunGirisiKutusuRef.put(ogunGirisi.id, ogunGirisi);
    print('VeriTabaniServisi: Öğün girişi veritabanına kaydedildi');
    
    // Günlük beslenme özetini güncelle
    print('VeriTabaniServisi: Günlük beslenme özeti güncelleniyor...');
    await _gunlukBeslenmeGuncelle(kullaniciId, ogunGirisi.tuketimTarihi);
    print('VeriTabaniServisi: Günlük beslenme özeti güncellendi');
    
    return ogunGirisi;
  }

  // Günlük öğün girişlerini getir
  static List<OgunGirisiModeli> gunlukOgunGirisleriniGetir(String kullaniciId, DateTime tarih) {
    print('VeriTabaniServisi: Günlük öğün girişleri getiriliyor...');
    print('VeriTabaniServisi: Kullanıcı ID: $kullaniciId');
    print('VeriTabaniServisi: Tarih: ${tarih.toString()}');
    
    final gunBaslangici = DateTime(tarih.year, tarih.month, tarih.day);
    final gunSonu = gunBaslangici.add(Duration(days: 1));
    
    print('VeriTabaniServisi: Gün başlangıcı: ${gunBaslangici.toString()}');
    print('VeriTabaniServisi: Gün sonu: ${gunSonu.toString()}');

    final tumOgunGirisleri = _ogunGirisiKutusuRef.values.toList();
    print('VeriTabaniServisi: Toplam öğün girişi sayısı veritabanında: ${tumOgunGirisleri.length}');
    
    final kullaniciOgunGirisleri = _ogunGirisiKutusuRef.values
        .where((giris) =>
            giris.kullaniciId == kullaniciId &&
            giris.tuketimTarihi.isAfter(gunBaslangici) &&
            giris.tuketimTarihi.isBefore(gunSonu))
        .toList();
    
    print('VeriTabaniServisi: Bu kullanıcı ve tarihe ait öğün girişi sayısı: ${kullaniciOgunGirisleri.length}');
    
    for (int i = 0; i < kullaniciOgunGirisleri.length; i++) {
      final giris = kullaniciOgunGirisleri[i];
      print('VeriTabaniServisi: Öğün $i - ${giris.yemekIsmi}: ${giris.kalori} kcal, ${giris.tuketimTarihi}');
    }
    
    return kullaniciOgunGirisleri;
  }

  // Kullanıcının öğün geçmişini getir
  static List<OgunGirisiModeli> kullaniciOgunGecmisiniGetir(String kullaniciId, {int gunSayisi = 30}) {
    final kesilmeTarihi = DateTime.now().subtract(Duration(days: gunSayisi));
    return _ogunGirisiKutusuRef.values
        .where((giris) => giris.kullaniciId == kullaniciId && giris.tuketimTarihi.isAfter(kesilmeTarihi))
        .toList()
      ..sort((a, b) => b.tuketimTarihi.compareTo(a.tuketimTarihi));
  }

  // Öğün girişini sil
  static Future<void> ogunGirisiSil(String girisId) async {
    final giris = _ogunGirisiKutusuRef.get(girisId);
          if (giris != null) {
        await _ogunGirisiKutusuRef.delete(girisId);
        // Günlük beslenme özetini güncelle
        await _gunlukBeslenmeGuncelle(giris.kullaniciId, giris.tuketimTarihi);
      }
  }

  // ============ GÜNLÜK BESLENME İŞLEMLERİ ============

  // Günlük beslenme özetini getir
  static GunlukBeslenmeModeli? gunlukBeslenmeGetir(String kullaniciId, DateTime tarih) {
    print('VeriTabaniServisi: Günlük beslenme verisi getiriliyor...');
    print('VeriTabaniServisi: Kullanıcı ID: $kullaniciId, Tarih: ${tarih.toString()}');
    
    final tarihAnahtari = _gunlukBeslenmeAnahtariOlustur(kullaniciId, tarih);
    print('VeriTabaniServisi: Aranacak anahtar: $tarihAnahtari');
    
    final gunlukBeslenme = _gunlukBeslenmeKutusuRef.get(tarihAnahtari);
    
    if (gunlukBeslenme != null) {
      print('VeriTabaniServisi: Günlük beslenme verisi bulundu - Toplam kalori: ${gunlukBeslenme.toplamKalori}');
      print('VeriTabaniServisi: Protein: ${gunlukBeslenme.toplamProtein}, Karbonhidrat: ${gunlukBeslenme.toplamKarbonhidrat}, Yağ: ${gunlukBeslenme.toplamYag}');
    } else {
      print('VeriTabaniServisi: Günlük beslenme verisi bulunamadı!');
      
      // Veritabanındaki tüm anahtarları listeleme
      final tumAnahtarlar = _gunlukBeslenmeKutusuRef.keys.toList();
      print('VeriTabaniServisi: Veritabanındaki tüm günlük beslenme anahtarları: $tumAnahtarlar');
    }
    
    return gunlukBeslenme;
  }

  // Haftalık beslenme verilerini getir
  static List<GunlukBeslenmeModeli> haftalikBeslenmeGetir(String kullaniciId, DateTime baslamaTarihi) {
    List<GunlukBeslenmeModeli> haftalikVeri = [];
    for (int i = 0; i < 7; i++) {
      final tarih = baslamaTarihi.add(Duration(days: i));
      final gunlukBeslenme = gunlukBeslenmeGetir(kullaniciId, tarih);
      if (gunlukBeslenme != null) {
        haftalikVeri.add(gunlukBeslenme);
      }
    }
    return haftalikVeri;
  }

  // Aylık beslenme verilerini getir
  static List<GunlukBeslenmeModeli> aylikBeslenmeGetir(String kullaniciId, DateTime ay) {
    final ayBaslangici = DateTime(ay.year, ay.month, 1);
    final aySonu = DateTime(ay.year, ay.month + 1, 0);
    
    List<GunlukBeslenmeModeli> aylikVeri = [];
    for (int gun = 1; gun <= aySonu.day; gun++) {
      final tarih = DateTime(ay.year, ay.month, gun);
      final gunlukBeslenme = gunlukBeslenmeGetir(kullaniciId, tarih);
      if (gunlukBeslenme != null) {
        aylikVeri.add(gunlukBeslenme);
      }
    }
    return aylikVeri;
  }

  // ============ YARDIMCI METODLAR ============

  // Günlük beslenme özetini güncelle
  static Future<void> _gunlukBeslenmeGuncelle(String kullaniciId, DateTime tarih) async {
    print('VeriTabaniServisi: Günlük beslenme güncelleme başlıyor...');
    final kullanici = _kullaniciKutusuRef.get(kullaniciId);
    if (kullanici == null) {
      print('VeriTabaniServisi: Kullanıcı bulunamadı - ID: $kullaniciId');
      return;
    }
    print('VeriTabaniServisi: Kullanıcı bulundu: ${kullanici.email}');

    final tarihAnahtari = _gunlukBeslenmeAnahtariOlustur(kullaniciId, tarih);
    print('VeriTabaniServisi: Günlük beslenme anahtarı: $tarihAnahtari');
    
    final ogunGirisleri = gunlukOgunGirisleriniGetir(kullaniciId, tarih);
    print('VeriTabaniServisi: Günlük beslenme güncellemesi için ${ogunGirisleri.length} öğün girişi bulundu');
    
    // Toplam kalori hesaplama kontrolü
    double toplamKalori = 0;
    for (var ogun in ogunGirisleri) {
      print('VeriTabaniServisi: Öğün: ${ogun.yemekIsmi} - ${ogun.kalori} kcal');
      toplamKalori += ogun.kalori;
    }
    print('VeriTabaniServisi: Hesaplanan toplam kalori: $toplamKalori');
    
    GunlukBeslenmeModeli gunlukBeslenme = _gunlukBeslenmeKutusuRef.get(tarihAnahtari) ??
        GunlukBeslenmeModeli(
          id: tarihAnahtari,
          kullaniciId: kullaniciId,
          tarih: DateTime(tarih.year, tarih.month, tarih.day),
          kaloriHedefi: kullanici.gunlukKaloriHedefi,
          olusturulmaTarihi: DateTime.now(),
          guncellemeTarihi: DateTime.now(),
        );

    print('VeriTabaniServisi: Günlük beslenme modeli güncelleme öncesi - Toplam kalori: ${gunlukBeslenme.toplamKalori}');
    
    gunlukBeslenme.ogunGirisleridenGuncelle(ogunGirisleri);
    
    print('VeriTabaniServisi: Günlük beslenme modeli güncelleme sonrası - Toplam kalori: ${gunlukBeslenme.toplamKalori}');
    print('VeriTabaniServisi: Günlük beslenme modeli kaydediliyor...');
    
    await _gunlukBeslenmeKutusuRef.put(tarihAnahtari, gunlukBeslenme);
    
    print('VeriTabaniServisi: Günlük beslenme modeli başarıyla kaydedildi');
    
    // Kayıt kontrolü
    final kaydedilenModel = _gunlukBeslenmeKutusuRef.get(tarihAnahtari);
    if (kaydedilenModel != null) {
      print('VeriTabaniServisi: Kontrol - Kaydedilen model toplam kalori: ${kaydedilenModel.toplamKalori}');
    } else {
      print('VeriTabaniServisi: HATA - Model kaydedilemedi!');
    }
  }

  // Günlük beslenme anahtarı oluştur
  static String _gunlukBeslenmeAnahtariOlustur(String kullaniciId, DateTime tarih) {
    return '${kullaniciId}_${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}';
  }

  // ============ YARDIMCI ARAÇLAR ============

  // Tüm verileri temizle (test için)
  static Future<void> tumVerileriTemizle() async {
    await _kullaniciKutusuRef.clear();
    await _yemekOgesiKutusuRef.clear();
    await _ogunGirisiKutusuRef.clear();
    await _gunlukBeslenmeKutusuRef.clear();
    await _ozelBesinKutusuRef.clear();
    
    final ayarlarKutusu = await Hive.openBox('ayarlar');
    await ayarlarKutusu.clear();
  }

  // ============ ÖZEL BESİN İŞLEMLERİ ============

  // Özel besin kutusunu getir
  static Box<OzelBesinModeli> get _ozelBesinKutusuRef => Hive.box<OzelBesinModeli>(_ozelBesinKutusu);

  // Özel besin kaydet
  static Future<OzelBesinModeli> ozelBesinKaydet(OzelBesinModeli ozelBesin) async {
    // Hive için güvenli ID oluştur (0-0xFFFFFFFF aralığında)
    final yeniId = ozelBesin.id ?? _yeniOzelBesinIdOlustur();
    final yeniOzelBesin = ozelBesin.copyWith(id: yeniId);
    
    await _ozelBesinKutusuRef.put(yeniOzelBesin.id, yeniOzelBesin);
    return yeniOzelBesin;
  }

  // Güvenli ID oluştur
  static int _yeniOzelBesinIdOlustur() {
    // Mevcut ID'leri kontrol et
    final mevcutIdler = _ozelBesinKutusuRef.values.map((besin) => besin.id).where((id) => id != null).cast<int>().toSet();
    
    // 1'den başlayarak boş ID bul
    int yeniId = 1;
    while (mevcutIdler.contains(yeniId)) {
      yeniId++;
    }
    
    return yeniId;
  }

  // Kullanıcının özel besinlerini getir
  static List<OzelBesinModeli> kullaniciOzelBesinleriniGetir(String kullaniciId) {
    return _ozelBesinKutusuRef.values
        .where((besin) => besin.kullaniciId == kullaniciId)
        .toList()
      ..sort((a, b) => b.eklenmeTarihi.compareTo(a.eklenmeTarihi));
  }

  // Özel besin ara
  static List<OzelBesinModeli> ozelBesinAra(String kullaniciId, String aramaKelimesi) {
    final kelime = aramaKelimesi.toLowerCase();
    return _ozelBesinKutusuRef.values
        .where((besin) => 
            besin.kullaniciId == kullaniciId &&
            besin.isim.toLowerCase().contains(kelime))
        .toList()
      ..sort((a, b) => a.isim.compareTo(b.isim));
  }

  // Özel besin sil
  static Future<void> ozelBesinSil(int besinId) async {
    await _ozelBesinKutusuRef.delete(besinId);
  }

  // Özel besin güncelle
  static Future<void> ozelBesinGuncelle(OzelBesinModeli ozelBesin) async {
    await _ozelBesinKutusuRef.put(ozelBesin.id, ozelBesin);
  }

  // ============ KİLO TAKİBİ İŞLEMLERİ ============

  // Kilo girişi kaydet
  static Future<KiloGirisiModeli> kiloGirisiKaydet(KiloGirisiModeli kiloGirisi) async {
    print('VeriTabaniServisi: Kilo girişi kaydediliyor: ${kiloGirisi.kilo} kg, Kullanıcı: ${kiloGirisi.kullaniciId}');
    
    final yeniId = kiloGirisi.id.isEmpty ? _uuidUretici.v4() : kiloGirisi.id;
    final yeniKiloGirisi = kiloGirisi.copyWith(id: yeniId);
    
    await _kiloGirisiKutusuRef.put(yeniKiloGirisi.id, yeniKiloGirisi);
    print('VeriTabaniServisi: Kilo girişi Hive\'a kaydedildi');
    
    // Kullanıcının mevcut kilosunu güncelle
    final kullanici = _kullaniciKutusuRef.get(kiloGirisi.kullaniciId);
    print('VeriTabaniServisi: Kullanıcı bulundu: ${kullanici?.isim}, Eski kilo: ${kullanici?.kilo}');
    
    if (kullanici != null) {
      final guncellenenKullanici = kullanici.copyWith(
        kilo: kiloGirisi.kilo,
        guncellemeTarihi: DateTime.now(),
      );
      await _kullaniciKutusuRef.put(guncellenenKullanici.id, guncellenenKullanici);
      print('VeriTabaniServisi: Kullanıcının kilosu güncellendi: ${guncellenenKullanici.kilo} kg');
    } else {
      print('VeriTabaniServisi: HATA - Kullanıcı bulunamadı: ${kiloGirisi.kullaniciId}');
    }
    
    return yeniKiloGirisi;
  }

  // Kullanıcının kilo girişlerini getir
  static List<KiloGirisiModeli> kullaniciKiloGirisleriniGetir(String kullaniciId) {
    return _kiloGirisiKutusuRef.values
        .where((giris) => giris.kullaniciId == kullaniciId)
        .toList()
      ..sort((a, b) => b.olcumTarihi.compareTo(a.olcumTarihi));
  }

  // Belirli tarih aralığındaki kilo girişlerini getir
  static List<KiloGirisiModeli> tarihAraligiKiloGirisleriniGetir(
    String kullaniciId, 
    DateTime baslangic, 
    DateTime bitis
  ) {
    return _kiloGirisiKutusuRef.values
        .where((giris) => 
            giris.kullaniciId == kullaniciId &&
            giris.olcumTarihi.isAfter(baslangic.subtract(Duration(days: 1))) &&
            giris.olcumTarihi.isBefore(bitis.add(Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.olcumTarihi.compareTo(b.olcumTarihi));
  }

  // Son kilo girişini getir
  static KiloGirisiModeli? sonKiloGirisiniGetir(String kullaniciId) {
    final kiloGirisleri = kullaniciKiloGirisleriniGetir(kullaniciId);
    return kiloGirisleri.isNotEmpty ? kiloGirisleri.first : null;
  }

  // Haftalık kilo verilerini getir
  static List<KiloGirisiModeli> haftalikKiloVerileriniGetir(String kullaniciId) {
    final bugun = DateTime.now();
    final haftaOncesi = bugun.subtract(Duration(days: 7));
    return tarihAraligiKiloGirisleriniGetir(kullaniciId, haftaOncesi, bugun);
  }

  // Aylık kilo verilerini getir
  static List<KiloGirisiModeli> aylikKiloVerileriniGetir(String kullaniciId) {
    final bugun = DateTime.now();
    final ayOncesi = DateTime(bugun.year, bugun.month - 1, bugun.day);
    return tarihAraligiKiloGirisleriniGetir(kullaniciId, ayOncesi, bugun);
  }

  // Kilo değişim hesaplamaları
  static Map<String, double> kiloIstatistikleriniGetir(String kullaniciId) {
    final kiloGirisleri = kullaniciKiloGirisleriniGetir(kullaniciId);
    
    if (kiloGirisleri.length < 2) {
      return {
        'mevcutKilo': kiloGirisleri.isNotEmpty ? kiloGirisleri.first.kilo : 0.0,
        'haftalikDegisim': 0.0,
        'aylikDegisim': 0.0,
        'toplamDegisim': 0.0,
      };
    }

    final mevcutKilo = kiloGirisleri.first.kilo;
    final bugun = DateTime.now();
    
    // Haftalık değişim
    final haftaOncesi = bugun.subtract(Duration(days: 7));
    final haftalikKilo = kiloGirisleri
        .where((g) => g.olcumTarihi.isAfter(haftaOncesi))
        .lastOrNull?.kilo ?? mevcutKilo;
    
    // Aylık değişim
    final ayOncesi = DateTime(bugun.year, bugun.month - 1, bugun.day);
    final aylikKilo = kiloGirisleri
        .where((g) => g.olcumTarihi.isAfter(ayOncesi))
        .lastOrNull?.kilo ?? mevcutKilo;
    
    // Toplam değişim (ilk kayıttan itibaren)
    final ilkKilo = kiloGirisleri.last.kilo;

    return {
      'mevcutKilo': mevcutKilo,
      'haftalikDegisim': mevcutKilo - haftalikKilo,
      'aylikDegisim': mevcutKilo - aylikKilo,
      'toplamDegisim': mevcutKilo - ilkKilo,
    };
  }

  // Kilo girişi sil
  static Future<void> kiloGirisiniSil(String girisId) async {
    await _kiloGirisiKutusuRef.delete(girisId);
  }

  // Kilo girişi güncelle
  static Future<void> kiloGirisiniGuncelle(KiloGirisiModeli kiloGirisi) async {
    await _kiloGirisiKutusuRef.put(kiloGirisi.id, kiloGirisi);
  }

  // Veritabanını kapat
  static Future<void> kapat() async {
    await Hive.close();
  }
} 