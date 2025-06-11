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
      'genelDurum': _genelDurumGetir([proteinYuzde, karbonhidratYuzde, yagYuzde]),
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
    
    // Kalori önerileri
    if (kaloriFarki > 300) {
      oneriler.add('⚡ Günlük kalori hedefinize ${kaloriFarki.round()} kcal eksik, sağlıklı atıştırmalıklar ekleyin');
    } else if (kaloriFarki < -300) {
      oneriler.add('⚠️ Günlük kalori hedefinizi ${(-kaloriFarki).round()} kcal aştınız, yarın daha dikkatli olun');
    } else {
      oneriler.add('✅ Kalori dengesi çok iyi!');
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

  static String _genelDurumGetir(List<num> yuzdeler) {
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
} 