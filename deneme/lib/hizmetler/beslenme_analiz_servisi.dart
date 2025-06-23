import 'dart:math';
import '../modeller/kullanici_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import 'veri_tabani_servisi.dart';

class BeslenmeAnalizServisi {
  // Besin eksikliği analizi
  static Map<String, dynamic> besinEksikligiAnalizi(
    KullaniciModeli kullanici,
    GunlukBeslenmeModeli? beslenme,
  ) {
    if (beslenme == null) {
      return {
        'protein': {'durum': 'eksik', 'yuzde': 0, 'mesaj': 'Protein eksik'},
        'karbonhidrat': {'durum': 'eksik', 'yuzde': 0, 'mesaj': 'Karbonhidrat eksik'},
        'yag': {'durum': 'eksik', 'yuzde': 0, 'mesaj': 'Yağ eksik'},
        'genelDurum': 'kotu',
      };
    }

    // Günlük hedefler (genel öneriler)
    final hedefProtein = kullanici.kilo * 1.2; // kg başına 1.2g protein
    final hedefKarbonhidrat = kullanici.gunlukKaloriHedefi * 0.45 / 4; // Kalorilerin %45'i
    final hedefYag = kullanici.gunlukKaloriHedefi * 0.25 / 9; // Kalorilerin %25'i

    final proteinYuzde = (beslenme.toplamProtein / hedefProtein * 100).clamp(0.0, 150.0);
    final karbonhidratYuzde = (beslenme.toplamKarbonhidrat / hedefKarbonhidrat * 100).clamp(0.0, 150.0);
    final yagYuzde = (beslenme.toplamYag / hedefYag * 100).clamp(0.0, 150.0);

    return {
      'protein': {
        'durum': _besinDurumuGetir(proteinYuzde),
        'yuzde': proteinYuzde,
        'mesaj': _besinMesajiGetir('Protein', proteinYuzde),
        'hedef': hedefProtein,
        'gercek': beslenme.toplamProtein,
      },
      'karbonhidrat': {
        'durum': _besinDurumuGetir(karbonhidratYuzde),
        'yuzde': karbonhidratYuzde,
        'mesaj': _besinMesajiGetir('Karbonhidrat', karbonhidratYuzde),
        'hedef': hedefKarbonhidrat,
        'gercek': beslenme.toplamKarbonhidrat,
      },
      'yag': {
        'durum': _besinDurumuGetir(yagYuzde),
        'yuzde': yagYuzde,
        'mesaj': _besinMesajiGetir('Yağ', yagYuzde),
        'hedef': hedefYag,
        'gercek': beslenme.toplamYag,
      },
      'genelDurum': _genelDurumGetir([proteinYuzde, karbonhidratYuzde, yagYuzde], kaloriAsimi: beslenme.toplamKalori - kullanici.gunlukKaloriHedefi),
    };
  }

  // Haftalık beslenme özeti
  static Future<Map<String, dynamic>> haftalikBeslenmeOzeti(String kullaniciId) async {
    final bugun = DateTime.now();
    final haftaBaslangici = bugun.subtract(Duration(days: 6));
    
    List<GunlukBeslenmeModeli?> haftalikVeriler = [];
    double toplamKalori = 0;
    double toplamProtein = 0;
    double toplamKarbonhidrat = 0;
    double toplamYag = 0;
    
    for (int i = 0; i < 7; i++) {
      final tarih = haftaBaslangici.add(Duration(days: i));
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
      haftalikVeriler.add(gunlukBeslenme);
      
      if (gunlukBeslenme != null) {
        toplamKalori += gunlukBeslenme.toplamKalori;
        toplamProtein += gunlukBeslenme.toplamProtein;
        toplamKarbonhidrat += gunlukBeslenme.toplamKarbonhidrat;
        toplamYag += gunlukBeslenme.toplamYag;
      }
    }
    
    final ortalamalar = {
      'kalori': toplamKalori / 7,
      'protein': toplamProtein / 7,
      'karbonhidrat': toplamKarbonhidrat / 7,
      'yag': toplamYag / 7,
    };
    
    return {
      'haftalikVeriler': haftalikVeriler,
      'ortalamalar': ortalamalar,
      'toplamlar': {
        'kalori': toplamKalori,
        'protein': toplamProtein,
        'karbonhidrat': toplamKarbonhidrat,
        'yag': toplamYag,
      },
      'tutarlilik': _tutarlilikAnalizi(haftalikVeriler),
    };
  }

  // Beslenme alışkanlıkları analizi
  static Map<String, dynamic> beslenmeAliskanligiAnalizi(List<OgunGirisiModeli> sonOgunler) {
    if (sonOgunler.isEmpty) {
      return {
        'enSikBesin': 'Veri yok',
        'enSikOgun': 'Veri yok',
        'cesitlilik': 0,
        'tutarlilik': 0,
      };
    }

    // En sık tüketilen besinler
    Map<String, int> besinSikligi = {};
    Map<String, int> ogunSikligi = {};
    
    for (final ogun in sonOgunler) {
      besinSikligi[ogun.yemekIsmi] = (besinSikligi[ogun.yemekIsmi] ?? 0) + 1;
      ogunSikligi[ogun.ogunTipi] = (ogunSikligi[ogun.ogunTipi] ?? 0) + 1;
    }
    
    final enSikBesin = besinSikligi.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;
    final enSikOgun = ogunSikligi.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;
    
    // Çeşitlilik skoru (farklı besin sayısı / toplam öğün sayısı)
    final cesitlilik = (besinSikligi.length / sonOgunler.length * 100).clamp(0.0, 100.0);
    
    return {
      'enSikBesin': enSikBesin,
      'enSikOgun': enSikOgun,
      'cesitlilik': cesitlilik,
      'besinSikligi': besinSikligi,
      'ogunSikligi': ogunSikligi,
    };
  }

  // Kişiselleştirilmiş öneriler
  static List<String> kisisellestirilmisOneriler(
    KullaniciModeli kullanici,
    GunlukBeslenmeModeli? beslenme,
    Map<String, dynamic> analizSonucu,
  ) {
    List<String> oneriler = [];
    
    if (beslenme == null) {
      oneriler.add('📝 Günlük beslenme kaydı yapmaya başlayın');
      oneriler.add('🎯 Günlük kalori hedefiniz ${kullanici.gunlukKaloriHedefi.round()} kcal');
      return oneriler;
    }

    final kaloriFarki = kullanici.gunlukKaloriHedefi - beslenme.toplamKalori;
    final kaloriAsimi = -kaloriFarki; // Pozitif değer = aşım
    
    // Kalori önerileri - SAĞLIK ODAKLI
    if (kaloriFarki > 300) {
      oneriler.add('⚡ Günlük kalori hedefinize ${kaloriFarki.round()} kcal eksik, sağlıklı atıştırmalıklar ekleyin');
    } else if (kaloriAsimi > 500) {
      // Çok fazla aşım - ACİL UYARI
      oneriler.add('🚨 TEHLİKE! Günlük kalori hedefinizi ${kaloriAsimi.round()} kcal aştınız!');
      oneriler.add('🏃‍♂️ ACİL: En az 60 dk yoğun egzersiz yapın (koşu, bisiklet, yüzme)');
      oneriler.add('💪 Yarın mutlaka kalori açığı yaratın ve aktif olun');
    } else if (kaloriAsimi > 300) {
      // Orta düzey aşım - UYARI
      oneriler.add('⚠️ ZARARI! Kalori hedefinizi ${kaloriAsimi.round()} kcal aştınız');
      oneriler.add('🚶‍♂️ En az 45 dk hızlı yürüyüş yapın');
      oneriler.add('🎯 Yarın daha kontrollü beslenin');
    } else if (kaloriFarki < 100 && kaloriFarki > 0) {
      // Hedefe çok yakın - DİKKAT
      oneriler.add('⚠️ DİKKAT! Kalori hedefinize sadece ${kaloriFarki.round()} kcal kaldı');
      oneriler.add('🛑 Daha fazla yemek yemeyin - günlük hedef doldu');
      oneriler.add('🏃‍♂️ Ekstra aktivite için 20 dk yürüyüş yapabilirsiniz');
    } else if (kaloriFarki >= -100 && kaloriFarki <= 100) {
      // İdeal aralık
      oneriler.add('✅ Kalori dengesi ideal seviyede');
    }

    // Makro besin önerileri
    final proteinAnaliz = analizSonucu['protein'];
    if (proteinAnaliz['yuzde'] < 80) {
      oneriler.add('🥩 Protein alımını artırın: tavuk, balık, yumurta veya baklagiller tüketin');
    }

    final karbonhidratAnaliz = analizSonucu['karbonhidrat'];
    if (karbonhidratAnaliz['yuzde'] < 70) {
      oneriler.add('🍞 Kompleks karbonhidrat alın: tam tahıl, meyve ve sebze tüketin');
    }

    final yagAnaliz = analizSonucu['yag'];
    if (yagAnaliz['yuzde'] < 70) {
      oneriler.add('🥑 Sağlıklı yağlar ekleyin: zeytinyağı, avokado, kuruyemiş');
    }

    // Aktivite seviyesine göre öneriler
    if (kullanici.aktiviteSeviyesi >= 4) {
      oneriler.add('🏃‍♂️ Yüksek aktivite seviyeniz için ek protein alın');
    }

    return oneriler;
  }

  // Su içme önerisi
  static String suOnerisi(KullaniciModeli kullanici) {
    final gunlukSuIhtiyaci = (kullanici.kilo * 35).round(); // ml cinsinden
    return 'Günlük su ihtiyacınız yaklaşık ${(gunlukSuIhtiyaci / 1000).toStringAsFixed(1)} litre';
  }

  // Yardımcı metodlar
  static String _besinDurumuGetir(num yuzde) {
    if (yuzde >= 90) return 'iyi';
    if (yuzde >= 70) return 'orta';
    return 'eksik';
  }

  static String _besinMesajiGetir(String besinAdi, num yuzde) {
    if (yuzde >= 100) return '$besinAdi alımınız yeterli';
    if (yuzde >= 80) return '$besinAdi alımınız neredeyse yeterli';
    if (yuzde >= 50) return '$besinAdi alımınızı artırmalısınız';
    return '$besinAdi alımınız oldukça eksik';
  }

  static String _genelDurumGetir(List<num> yuzdeler, {double? kaloriAsimi}) {
    // ÖNCE KALORİ AŞIMI KONTROLÜ
    if (kaloriAsimi != null && kaloriAsimi > 100) {
      return 'kotu'; // Kalori aşımında asla iyi durum gösterme
    }
    
    final ortalama = yuzdeler.reduce((a, b) => a + b) / yuzdeler.length;
    if (ortalama >= 85) return 'mukemmel';
    if (ortalama >= 70) return 'iyi';
    if (ortalama >= 50) return 'orta';
    return 'kotu';
  }

  static double _tutarlilikAnalizi(List<GunlukBeslenmeModeli?> haftalikVeriler) {
    final gecerliVeriler = haftalikVeriler.where((v) => v != null).cast<GunlukBeslenmeModeli>();
    if (gecerliVeriler.length < 2) return 0;

    final kaloriDegerleri = gecerliVeriler.map((v) => v.toplamKalori).toList();
    final ortalama = kaloriDegerleri.reduce((a, b) => a + b) / kaloriDegerleri.length;
    
    // Standart sapma hesaplama
    final varyans = kaloriDegerleri.map((k) => (k - ortalama) * (k - ortalama)).reduce((a, b) => a + b) / kaloriDegerleri.length;
    final standartSapma = sqrt(varyans);
    
    // Tutarlılık skoru (düşük sapma = yüksek tutarlılık)
    final tutarlilikSkoru = (100 - (standartSapma / ortalama * 100)).clamp(0.0, 100.0);
    return tutarlilikSkoru;
  }

  /// Günlük beslenme skorunu hesaplar (0-100 arası)
  /// Kullanıcının hedeflerine göre gerçek kalori ve mikrobesin alımına dayalı
  static Future<Map<String, dynamic>> gunlukBeslenmeSkoruHesapla(
    String kullaniciId, 
    DateTime tarih
  ) async {
    try {
      final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
      
      if (kullanici == null || gunlukBeslenme == null) {
        return {
          'skor': 0,
          'durum': 'Veri Yok',
          'aciklama': 'Günlük beslenme verisi bulunamadı',
          'detaylar': <String, dynamic>{},
        };
      }

      // Kullanıcının hedeflerini hesapla
      final hedefler = _kullaniciHedefleriniHesapla(kullanici);
      
      // Skor bileşenlerini hesapla
      final kaloriSkoru = _kaloriSkoruHesapla(gunlukBeslenme.toplamKalori ?? 0.0, hedefler['kalori']!);
      final proteinSkoru = _proteinSkoruHesapla(gunlukBeslenme.toplamProtein ?? 0.0, hedefler['protein']!);
      final karbonhidratSkoru = _karbonhidratSkoruHesapla(gunlukBeslenme.toplamKarbonhidrat ?? 0.0, hedefler['karbonhidrat']!);
      final yagSkoru = _yagSkoruHesapla(gunlukBeslenme.toplamYag ?? 0.0, hedefler['yag']!);
      final lifSkoru = _lifSkoruHesapla(gunlukBeslenme.toplamLif ?? 0.0, hedefler['lif']!); // Gerçek lif değeri kullan
      
      // Ağırlıklı ortalama skor hesapla
      final toplamSkor = (
        kaloriSkoru * 0.40 +      // %40 kalori
        proteinSkoru * 0.25 +     // %25 protein
        karbonhidratSkoru * 0.15 + // %15 karbonhidrat
        yagSkoru * 0.10 +         // %10 yağ
        lifSkoru * 0.10           // %10 lif
      ).round();

      // Kalori aşımını hesapla
      final kaloriAsimi = (gunlukBeslenme.toplamKalori ?? 0.0) - hedefler['kalori']!;
      
      final durum = _skorDurumunuBelirle(toplamSkor, kaloriAsimi: kaloriAsimi);
      final aciklama = _skorAciklamasiniOlustur(toplamSkor, gunlukBeslenme, hedefler);

      return {
        'skor': toplamSkor,
        'durum': durum,
        'aciklama': aciklama,
        'detaylar': {
          'kaloriSkoru': kaloriSkoru,
          'proteinSkoru': proteinSkoru,
          'karbonhidratSkoru': karbonhidratSkoru,
          'yagSkoru': yagSkoru,
          'lifSkoru': lifSkoru,
          'hedefler': hedefler,
          'alinan': {
            'kalori': gunlukBeslenme.toplamKalori ?? 0.0,
            'protein': gunlukBeslenme.toplamProtein ?? 0.0,
            'karbonhidrat': gunlukBeslenme.toplamKarbonhidrat ?? 0.0,
            'yag': gunlukBeslenme.toplamYag ?? 0.0,
            'lif': gunlukBeslenme.toplamLif ?? 0.0,
          },
        },
      };

    } catch (e) {
      print('BeslenmeAnalizServisi: Hata - $e');
      return {
        'skor': 0,
        'durum': 'Hata',
        'aciklama': 'Hesaplama sırasında hata oluştu',
        'detaylar': <String, dynamic>{},
      };
    }
  }

  /// Kullanıcının günlük hedeflerini hesaplar
  static Map<String, double> _kullaniciHedefleriniHesapla(KullaniciModeli kullanici) {
    // BMR hesaplama (Mifflin-St Jeor denklemi)
    double bmr;
    if (kullanici.yas > 40) { // cinsiyet alanı yok, yaşa göre hesapla
      bmr = 88.362 + (13.397 * kullanici.kilo) + (4.799 * kullanici.boy) - (5.677 * kullanici.yas);
    } else {
      bmr = 447.593 + (9.247 * kullanici.kilo) + (3.098 * kullanici.boy) - (4.330 * kullanici.yas);
    }

    // Aktivite faktörü uygula
    double aktiviteFaktoru = _aktiviteFaktorunuGetir('Orta Aktif'); // aktiviteSeviyesi int, varsayılan kullan
    double gunlukKalori = bmr * aktiviteFaktoru;

    // Hedefe göre ayarlama
    // hedef alanı yok, varsayılan koruma modu
    String hedef = 'Kiloyu Korumak'; // varsayılan hedef
    switch (hedef) {
      case 'Kilo Vermek':
        gunlukKalori *= 0.85; // %15 azalt
        break;
      case 'Kilo Almak':
        gunlukKalori *= 1.15; // %15 arttır
        break;
      default: // Kiloyu Korumak
        break;
    }

    // Makrobesin hedeflerini hesapla
    double proteinHedef = (gunlukKalori * 0.25) / 4; // %25 protein (4 kcal/g)
    double karbonhidratHedef = (gunlukKalori * 0.45) / 4; // %45 karbonhidrat (4 kcal/g)
    double yagHedef = (gunlukKalori * 0.30) / 9; // %30 yağ (9 kcal/g)
    double lifHedef = 25 + (kullanici.kilo * 0.2); // Kilo başına 0.2g + 25g baz

    return {
      'kalori': gunlukKalori,
      'protein': proteinHedef,
      'karbonhidrat': karbonhidratHedef,
      'yag': yagHedef,
      'lif': lifHedef,
    };
  }

  static double _aktiviteFaktorunuGetir(String aktiviteSeviyesi) {
    switch (aktiviteSeviyesi) {
      case 'Hareketsiz':
        return 1.2;
      case 'Az Aktif':
        return 1.375;
      case 'Orta Aktif':
        return 1.55;
      case 'Çok Aktif':
        return 1.725;
      case 'Aşırı Aktif':
        return 1.9;
      default:
        return 1.375;
    }
  }

  /// Kalori skorunu hesaplar (0-100) - SAĞLIK ODAKLI
  static int _kaloriSkoruHesapla(double alinan, double hedef) {
    if (hedef <= 0) return 0;
    
    double oran = alinan / hedef;
    
    // Kalori aşımı çok ciddi - düşük skor
    if (oran > 1.30) {
      return 10; // TEHLİKELİ SEVYE - çok düşük skor
    } else if (oran > 1.15) {
      return 30; // ZARARI - düşük skor
    } else if (oran >= 0.85 && oran <= 1.15) {
      return 100; // İdeal aralık
    } else if (oran >= 0.70 && oran <= 1.30) {
      return 80; // İyi aralık
    } else if (oran >= 0.50 && oran <= 1.50) {
      return 60; // Orta aralık
    } else if (oran >= 0.30) {
      return 40; // Zayıf aralık
    } else {
      return 20; // Çok zayıf
    }
  }

  /// Protein skorunu hesaplar
  static int _proteinSkoruHesapla(double alinan, double hedef) {
    if (hedef <= 0) return 0;
    
    double oran = alinan / hedef;
    
    if (oran >= 0.80 && oran <= 1.50) {
      return 100; // Protein fazlası genelde sorun değil
    } else if (oran >= 0.60 && oran <= 1.70) {
      return 80;
    } else if (oran >= 0.40 && oran <= 2.00) {
      return 60;
    } else if (oran >= 0.20) {
      return 40;
    } else {
      return 20;
    }
  }

  /// Karbonhidrat skorunu hesapla
  static int _karbonhidratSkoruHesapla(double alinan, double hedef) {
    if (hedef <= 0) return 0;
    
    double oran = alinan / hedef;
    
    if (oran >= 0.75 && oran <= 1.25) {
      return 100;
    } else if (oran >= 0.60 && oran <= 1.40) {
      return 80;
    } else if (oran >= 0.40 && oran <= 1.60) {
      return 60;
    } else if (oran >= 0.20) {
      return 40;
    } else {
      return 20;
    }
  }

  /// Yağ skorunu hesapla
  static int _yagSkoruHesapla(double alinan, double hedef) {
    if (hedef <= 0) return 0;
    
    double oran = alinan / hedef;
    
    if (oran >= 0.70 && oran <= 1.30) {
      return 100;
    } else if (oran >= 0.50 && oran <= 1.50) {
      return 80;
    } else if (oran >= 0.30 && oran <= 1.70) {
      return 60;
    } else if (oran >= 0.10) {
      return 40;
    } else {
      return 20;
    }
  }

  /// Lif skorunu hesapla
  static int _lifSkoruHesapla(double alinan, double hedef) {
    if (hedef <= 0) return 0;
    
    double oran = alinan / hedef;
    
    if (oran >= 0.80) {
      return 100; // Lif fazlası genelde iyidir
    } else if (oran >= 0.60) {
      return 80;
    } else if (oran >= 0.40) {
      return 60;
    } else if (oran >= 0.20) {
      return 40;
    } else {
      return 20;
    }
  }

  static String _skorDurumunuBelirle(int skor, {double? kaloriAsimi}) {
    // ÖNCE KALORİ AŞIMI KONTROLÜ
    if (kaloriAsimi != null && kaloriAsimi > 100) {
      if (kaloriAsimi > 500) return 'TEHLİKELİ';
      if (kaloriAsimi > 300) return 'ZARARI';
      return 'RİSKLİ';
    }
    
    // Normal skor değerlendirmesi (sadece kalori aşımı yoksa)
    if (skor >= 90) return 'Mükemmel';
    if (skor >= 80) return 'Çok İyi';
    if (skor >= 70) return 'İyi';
    if (skor >= 60) return 'Orta';
    if (skor >= 50) return 'Zayıf';
    return 'Çok Zayıf';
  }

  static String _skorAciklamasiniOlustur(int skor, GunlukBeslenmeModeli beslenme, Map<String, double> hedefler) {
    final kaloriHedef = hedefler['kalori'] ?? 2000.0;
    final kaloriAlinan = beslenme.toplamKalori ?? 0.0;
    final kaloriAsimi = kaloriAlinan - kaloriHedef;
    
    // Önce kalori aşımı kontrolü yap
    if (kaloriAsimi > 500) {
      return '🚨 ZARARI! ${kaloriAsimi.round()} kcal fazla aldınız. ACİL egzersiz gerekli!';
    } else if (kaloriAsimi > 300) {
      return '⚠️ TEHLİKE! ${kaloriAsimi.round()} kcal fazla. Fiziksel aktivite şart!';
    } else if (kaloriAsimi > 100) {
      return '🟡 DİKKAT! ${kaloriAsimi.round()} kcal fazla. Hızlı yürüyüş yapın.';
    }
    
    // Normal skor değerlendirmesi
    if (skor >= 90) {
      return 'Mükemmel! Beslenme hedeflerinizi neredeyse ideal karşılıyorsunuz.';
    } else if (skor >= 80) {
      return 'İyi gidiyorsunuz! Küçük ayarlamalarla daha da iyi olacak.';
    } else if (skor >= 70) {
      return 'İyi bir beslenme gösteriyorsunuz. Bazı besinleri artırabilirsiniz.';
    } else if (skor >= 60) {
      return 'Orta seviyede besleniyorsunuz. Kalori ve protein alımınızı gözden geçirin.';
    } else if (skor >= 50) {
      return 'Beslenmenizde iyileştirme gerekiyor. Daha dengeli beslenmeye odaklanın.';
    } else {
      return 'Beslenmenizi ciddi şekilde gözden geçirmeniz gerekiyor. Uzman desteği alabilirsiniz.';
    }
  }

  /// Kullanıcının eksik besinlerini tespit eder
  static Map<String, dynamic> eksikBesinleriTespitEt(
    Map<String, dynamic> beslenmeDetaylari
  ) {
    final hedefler = beslenmeDetaylari['hedefler'] as Map<String, double>;
    final alinan = beslenmeDetaylari['alinan'] as Map<String, double>;
    
    Map<String, dynamic> eksikBesinler = {};
    
    // Kalori eksikliği kontrolü
    final kaloriHedef = hedefler['kalori'] ?? 2000.0;
    final kaloriAlinan = alinan['kalori'] ?? 0.0;
    if (kaloriAlinan < kaloriHedef * 0.8) { // %80'den az ise eksik
      eksikBesinler['kalori'] = {
        'hedef': kaloriHedef,
        'alinan': kaloriAlinan,
        'eksikMiktar': kaloriHedef - kaloriAlinan,
        'yuzde': (kaloriAlinan / kaloriHedef * 100).round(),
      };
    }
    
    // Protein eksikliği kontrolü
    final proteinHedef = hedefler['protein'] ?? 80.0;
    final proteinAlinan = alinan['protein'] ?? 0.0;
    if (proteinAlinan < proteinHedef * 0.8) {
      eksikBesinler['protein'] = {
        'hedef': proteinHedef,
        'alinan': proteinAlinan,
        'eksikMiktar': proteinHedef - proteinAlinan,
        'yuzde': (proteinAlinan / proteinHedef * 100).round(),
      };
    }
    
    // Karbonhidrat eksikliği kontrolü
    final karbonhidratHedef = hedefler['karbonhidrat'] ?? 250.0;
    final karbonhidratAlinan = alinan['karbonhidrat'] ?? 0.0;
    if (karbonhidratAlinan < karbonhidratHedef * 0.7) { // Karbonhidrat için %70
      eksikBesinler['karbonhidrat'] = {
        'hedef': karbonhidratHedef,
        'alinan': karbonhidratAlinan,
        'eksikMiktar': karbonhidratHedef - karbonhidratAlinan,
        'yuzde': (karbonhidratAlinan / karbonhidratHedef * 100).round(),
      };
    }
    
    // Yağ eksikliği kontrolü
    final yagHedef = hedefler['yag'] ?? 65.0;
    final yagAlinan = alinan['yag'] ?? 0.0;
    if (yagAlinan < yagHedef * 0.6) { // Yağ için %60
      eksikBesinler['yag'] = {
        'hedef': yagHedef,
        'alinan': yagAlinan,
        'eksikMiktar': yagHedef - yagAlinan,
        'yuzde': (yagAlinan / yagHedef * 100).round(),
      };
    }
    
    // Lif eksikliği kontrolü - Gerçek lif değeri kullan
    final lifHedef = hedefler['lif'] ?? 25.0;
    final lifAlinan = alinan['lif'] ?? 0.0; // Artık gerçek değer gelecek
    if (lifAlinan < lifHedef * 0.7) { // Lif için %70
      eksikBesinler['lif'] = {
        'hedef': lifHedef,
        'alinan': lifAlinan,
        'eksikMiktar': lifHedef - lifAlinan,
        'yuzde': (lifAlinan / lifHedef * 100).round(),
      };
    }
    
    return eksikBesinler;
  }
} 