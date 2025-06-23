import 'dart:math';
import '../modeller/kullanici_modeli.dart';
import '../modeller/kilo_girisi_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import 'veri_tabani_servisi.dart';

class KiloAnalizServisi {
  
  // 1 kg yağ = 7700 kalori (bilimsel standart)
  static const double KALORI_PER_KG = 7700.0;
  
  /// Kalori açığı/fazlası ile kilo değişim tahmini
  static Future<Map<String, dynamic>> kaloriDengesiAnaliziYap(String kullaniciId, DateTime tarih) async {
    final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
    final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
    
    if (gunlukBeslenme == null || kullanici == null) {
      return {
        'kaloriHedefi': 0.0,
        'alinanKalori': 0.0,
        'kaloriDengesi': 0.0,
        'tahminKiloEtkisi': 0.0,
        'durum': 'Veri yok',
        'aciklama': 'Günlük beslenme verisi bulunamadı'
      };
    }
    
    final kaloriHedefi = kullanici.gunlukKaloriHedefi;
    final alinanKalori = gunlukBeslenme.toplamKalori;
    final kaloriDengesi = alinanKalori - kaloriHedefi;
    final tahminKiloEtkisi = kaloriDengesi / KALORI_PER_KG;
    
    String durum;
    String aciklama;
    
    if (kaloriDengesi > 200) {
      durum = 'Fazla';
      aciklama = 'Hedefin üzerinde kalori aldın. ${tahminKiloEtkisi.toStringAsFixed(3)} kg artış bekleniyor.';
    } else if (kaloriDengesi < -200) {
      durum = 'Açık';
      aciklama = 'Hedefin altında kalori aldın. ${(-tahminKiloEtkisi).toStringAsFixed(3)} kg azalış bekleniyor.';
    } else {
      durum = 'Dengede';
      aciklama = 'Kalori hedefine yakınsın. Kilo değişimi minimal olacak.';
    }
    
    return {
      'kaloriHedefi': kaloriHedefi,
      'alinanKalori': alinanKalori,
      'kaloriDengesi': kaloriDengesi,
      'tahminKiloEtkisi': tahminKiloEtkisi,
      'durum': durum,
      'aciklama': aciklama
    };
  }
  
  /// Haftalık kalori dengesi ile kilo tahmin analizi
  static Future<Map<String, dynamic>> haftalikKaloriAnaliziYap(String kullaniciId) async {
    final bugun = DateTime.now();
    final haftaOncesi = bugun.subtract(Duration(days: 7));
    
    double toplamKaloriDengesi = 0.0;
    int gunSayisi = 0;
    
    for (int i = 0; i < 7; i++) {
      final tarih = haftaOncesi.add(Duration(days: i));
      final analiz = await kaloriDengesiAnaliziYap(kullaniciId, tarih);
      if (analiz['kaloriDengesi'] != 0.0) {
        toplamKaloriDengesi += analiz['kaloriDengesi'] as double;
        gunSayisi++;
      }
    }
    
    final ortalamaDengesi = gunSayisi > 0 ? toplamKaloriDengesi / gunSayisi : 0.0;
    final haftalikTahminKiloEtkisi = toplamKaloriDengesi / KALORI_PER_KG;
    
    return {
      'toplamKaloriDengesi': toplamKaloriDengesi,
      'ortalamaDengesi': ortalamaDengesi,
      'haftalikTahminKiloEtkisi': haftalikTahminKiloEtkisi,
      'gunSayisi': gunSayisi,
      'tutarlilik': await _tutarlilikHesapla(kullaniciId)
    };
  }
  
  /// Makrobesin dengesi ile kilo kalitesi analizi
  static Map<String, dynamic> makrobesinKalitesiAnaliziYap(String kullaniciId, DateTime tarih) {
    final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
    
    if (gunlukBeslenme == null) {
      return {
        'proteinYeterli': false,
        'karbonhidratDengeli': false,
        'yagSaglikli': false,
        'kiloKalitesiSkoru': 0,
        'aciklama': 'Beslenme verisi yok'
      };
    }
    
    final toplamKalori = gunlukBeslenme.toplamKalori;
    if (toplamKalori == 0) {
      return {
        'proteinYeterli': false,
        'karbonhidratDengeli': false,
        'yagSaglikli': false,
        'kiloKalitesiSkoru': 0,
        'aciklama': 'Kalori verisi yok'
      };
    }
    
    // Makrobesin yüzdeleri
    final proteinYuzdesi = (gunlukBeslenme.toplamProtein * 4) / toplamKalori * 100;
    final karbonhidratYuzdesi = (gunlukBeslenme.toplamKarbonhidrat * 4) / toplamKalori * 100;
    final yagYuzdesi = (gunlukBeslenme.toplamYag * 9) / toplamKalori * 100;
    
    // Optimal aralıklar
    final proteinYeterli = proteinYuzdesi >= 15 && proteinYuzdesi <= 30;
    final karbonhidratDengeli = karbonhidratYuzdesi >= 45 && karbonhidratYuzdesi <= 65;
    final yagSaglikli = yagYuzdesi >= 20 && yagYuzdesi <= 35;
    
    // Kilo kalitesi skoru (0-100)
    int skor = 0;
    if (proteinYeterli) skor += 40; // Protein kas koruması için kritik
    if (karbonhidratDengeli) skor += 30;
    if (yagSaglikli) skor += 30;
    
    String aciklama = _makrobesinAciklamaOlustur(proteinYeterli, karbonhidratDengeli, yagSaglikli, proteinYuzdesi, karbonhidratYuzdesi, yagYuzdesi);
    
    return {
      'proteinYuzdesi': proteinYuzdesi,
      'karbonhidratYuzdesi': karbonhidratYuzdesi,
      'yagYuzdesi': yagYuzdesi,
      'proteinYeterli': proteinYeterli,
      'karbonhidratDengeli': karbonhidratDengeli,
      'yagSaglikli': yagSaglikli,
      'kiloKalitesiSkoru': skor,
      'aciklama': aciklama
    };
  }
  
  /// BMR güncellemesi kilo değiştiğinde
  static Future<void> kiloDegistitindeBMRGuncelle(String kullaniciId, double yeniKilo) async {
    final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
    if (kullanici == null) return;
    
    final eskiBMR = kullanici.bmr;
    final eskiKaloriHedefi = kullanici.gunlukKaloriHedefi;
    
    // Yeni kilo ile kullanıcıyı güncelle
    kullanici.bilgileriGuncelle(kilo: yeniKilo);
    
    print('KiloAnalizServisi: Kilo değişimi tespit edildi');
    print('  Eski BMR: ${eskiBMR.toStringAsFixed(0)} -> Yeni BMR: ${kullanici.bmr.toStringAsFixed(0)}');
    print('  Eski Hedef: ${eskiKaloriHedefi.toStringAsFixed(0)} -> Yeni Hedef: ${kullanici.gunlukKaloriHedefi.toStringAsFixed(0)}');
    
    // Kullanıcıyı kaydet
    await VeriTabaniServisi.kullaniciGuncelle(kullanici);
  }
  
  /// Hedef kilo ve süre hesaplaması
  static Future<Map<String, dynamic>> hedefKiloAnalizi(String kullaniciId, double hedefKilo) async {
    final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
    final kiloIstatistikleri = VeriTabaniServisi.kiloIstatistikleriniGetir(kullaniciId);
    
    if (kullanici == null) {
      return {'hata': 'Kullanıcı bulunamadı'};
    }
    
    final mevcutKilo = kiloIstatistikleri['mevcutKilo'] ?? kullanici.kilo;
    final kiloFarki = hedefKilo - mevcutKilo;
    
    // Sağlıklı kilo kaybı/artışı: haftada 0.5-1 kg
    final onerilenHaftalikDegisim = kiloFarki > 0 ? 0.5 : -0.5;
    final gerekenKaloriDegisimi = onerilenHaftalikDegisim * KALORI_PER_KG / 7; // Günlük
    
    final tahminiHaftalar = (kiloFarki / onerilenHaftalikDegisim).abs().ceil();
    final yeniKaloriHedefi = kullanici.gunlukKaloriHedefi + gerekenKaloriDegisimi;
    
    return {
      'mevcutKilo': mevcutKilo,
      'hedefKilo': hedefKilo,
      'kiloFarki': kiloFarki,
      'tahminiHaftalar': tahminiHaftalar,
      'tahminiAylar': (tahminiHaftalar / 4.33).ceil(),
      'onerilenHaftalikDegisim': onerilenHaftalikDegisim,
      'gerekenKaloriDegisimi': gerekenKaloriDegisimi,
      'yeniKaloriHedefi': yeniKaloriHedefi,
      'saglikliMi': _saglikliHedefMi(mevcutKilo, hedefKilo, kullanici.boy),
    };
  }
  
  /// Gelecek kilo tahmini
  static Future<Map<String, dynamic>> gelecekKiloTahmini(String kullaniciId, int gunSayisi) async {
    final haftalikAnaliz = await haftalikKaloriAnaliziYap(kullaniciId);
    final kiloIstatistikleri = VeriTabaniServisi.kiloIstatistikleriniGetir(kullaniciId);
    
    final mevcutKilo = kiloIstatistikleri['mevcutKilo'] ?? 0.0;
    final haftalikKaloriDengesi = haftalikAnaliz['toplamKaloriDengesi'] as double;
    
    // Gelecek tahmini
    final gunlukOrtalamaDengesi = haftalikKaloriDengesi / 7;
    final toplamKaloriEtkisi = gunlukOrtalamaDengesi * gunSayisi;
    final tahminiKiloDegisimi = toplamKaloriEtkisi / KALORI_PER_KG;
    final tahminiKilo = mevcutKilo + tahminiKiloDegisimi;
    
    return {
      'mevcutKilo': mevcutKilo,
      'gunSayisi': gunSayisi,
      'tahminiKilo': tahminiKilo,
      'tahminiKiloDegisimi': tahminiKiloDegisimi,
      'gunlukOrtalamaDengesi': gunlukOrtalamaDengesi,
      'guvenilirlik': _tahminGuvenilirlik(haftalikAnaliz['gunSayisi'] as int)
    };
  }
  
  /// Kapsamlı kilo analizi
  static Future<Map<String, dynamic>> kapsamliKiloAnaliziYap(String kullaniciId) async {
    final bugun = DateTime.now();
    final kaloriAnalizi = await kaloriDengesiAnaliziYap(kullaniciId, bugun);
    final makroAnaliz = makrobesinKalitesiAnaliziYap(kullaniciId, bugun);
    final kiloIstatistikleri = VeriTabaniServisi.kiloIstatistikleriniGetir(kullaniciId);
    
    return {
      'gunlukKaloriAnalizi': kaloriAnalizi,
      'makrobesinAnalizi': makroAnaliz,
      'kiloIstatistikleri': kiloIstatistikleri,
      'tarih': bugun.toIso8601String()
    };
  }
  
  /// Kilo takip raporu (kapsamlı analiz)
  static Future<Map<String, dynamic>> kapsamliKiloRaporu(String kullaniciId) async {
    final bugun = DateTime.now();
    final kaloriAnalizi = await kaloriDengesiAnaliziYap(kullaniciId, bugun);
    final haftalikAnaliz = await haftalikKaloriAnaliziYap(kullaniciId);
    final makroAnaliz = makrobesinKalitesiAnaliziYap(kullaniciId, bugun);
    final gelecekTahmini = await gelecekKiloTahmini(kullaniciId, 30); // 30 günlük tahmin
    
    // Genel skor hesaplama
    int genelSkor = 0;
    String genelDurum = '';
    List<String> oneriler = [];
    
    // Kalori dengesi skoru - SAĞLIK ODAKLI
    final kaloriDurum = kaloriAnalizi['durum'] as String;
    final kaloriDengesi = kaloriAnalizi['kaloriDengesi'] as double;
    
    if (kaloriDengesi > 500) {
      // Çok fazla aşım = TEHLİKELİ
      genelSkor += 5; // Çok düşük skor
      oneriler.add('🚨 TEHLİKE! Çok fazla kalori - ACİL egzersiz gerekli!');
    } else if (kaloriDengesi > 300) {
      // Fazla aşım = ZARARI
      genelSkor += 10; // Düşük skor
      oneriler.add('⚠️ ZARARI! Kalori fazlası - aktivite artırın!');
    } else if (kaloriDengesi > 100) {
      // Hafif aşım = DİKKAT
      genelSkor += 15; // Orta-düşük skor
      oneriler.add('🟡 DİKKAT! Kalori fazlası var - kontrol edin!');
    } else if (kaloriDurum == 'Dengede') {
      genelSkor += 30;
    } else if (kaloriDurum == 'Açık') {
      genelSkor += 20;
      oneriler.add('Kalori açığın var, sağlıklı atıştırmalıklar ekle');
    }
    
    // Makrobesin skoru
    genelSkor += (makroAnaliz['kiloKalitesiSkoru'] as int) ~/ 3;
    
    // Tutarlılık skoru
    final tutarlilik = haftalikAnaliz['tutarlilik'] as double;
    genelSkor += (tutarlilik * 30).round();
    
    // Kalori aşımı varsa asla mükemmel/iyi deme
    if (kaloriDengesi > 100) {
      if (kaloriDengesi > 500) {
        genelDurum = 'TEHLİKELİ';
      } else if (kaloriDengesi > 300) {
        genelDurum = 'ZARARI';
      } else {
        genelDurum = 'RİSKLİ';
      }
    } else if (genelSkor >= 80) {
      genelDurum = 'Mükemmel';
    } else if (genelSkor >= 60) {
      genelDurum = 'İyi';
    } else if (genelSkor >= 40) {
      genelDurum = 'Orta';
    } else {
      genelDurum = 'Geliştirilmeli';
    }
    
    return {
      'gunlukKaloriAnalizi': kaloriAnalizi,
      'haftalikAnaliz': haftalikAnaliz,
      'makrobesinAnalizi': makroAnaliz,
      'gelecekTahmini': gelecekTahmini,
      'genelSkor': genelSkor,
      'genelDurum': genelDurum,
      'oneriler': oneriler,
      'tarih': bugun.toIso8601String()
    };
  }
  
  // Yardımcı metodlar
  static Future<double> _tutarlilikHesapla(String kullaniciId) async {
    final bugun = DateTime.now();
    int tutarliGunler = 0;
    int toplamGun = 0;
    
    for (int i = 0; i < 14; i++) {
      final tarih = bugun.subtract(Duration(days: i));
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
      if (gunlukBeslenme != null && gunlukBeslenme.toplamKalori > 500) {
        toplamGun++;
        final kaloriAnalizi = await kaloriDengesiAnaliziYap(kullaniciId, tarih);
        if ((kaloriAnalizi['kaloriDengesi'] as double).abs() < 500) {
          tutarliGunler++;
        }
      }
    }
    
    return toplamGun > 0 ? tutarliGunler / toplamGun : 0.0;
  }
  
  static String _makrobesinAciklamaOlustur(bool proteinYeterli, bool karbonhidratDengeli, bool yagSaglikli, 
      double proteinYuzdesi, double karbonhidratYuzdesi, double yagYuzdesi) {
    List<String> sorunlar = [];
    List<String> iyiYonler = [];
    
    if (proteinYeterli) {
      iyiYonler.add('Protein oranın ideal (${proteinYuzdesi.toStringAsFixed(1)}%)');
    } else {
      sorunlar.add('Protein oranını artır (${proteinYuzdesi.toStringAsFixed(1)}%, ideal: 15-30%)');
    }
    
    if (karbonhidratDengeli) {
      iyiYonler.add('Karbonhidrat dengeli (${karbonhidratYuzdesi.toStringAsFixed(1)}%)');
    } else {
      sorunlar.add('Karbonhidrat dengesini ayarla (${karbonhidratYuzdesi.toStringAsFixed(1)}%, ideal: 45-65%)');
    }
    
    if (yagSaglikli) {
      iyiYonler.add('Yağ oranın sağlıklı (${yagYuzdesi.toStringAsFixed(1)}%)');
    } else {
      sorunlar.add('Yağ oranını düzenle (${yagYuzdesi.toStringAsFixed(1)}%, ideal: 20-35%)');
    }
    
    String aciklama = '';
    if (iyiYonler.isNotEmpty) {
      aciklama += 'İyi: ${iyiYonler.join(', ')}. ';
    }
    if (sorunlar.isNotEmpty) {
      aciklama += 'Geliştirilecek: ${sorunlar.join(', ')}.';
    }
    
    return aciklama.isEmpty ? 'Makrobesin dengesi analiz edilemiyor.' : aciklama;
  }
  
  static bool _saglikliHedefMi(double mevcutKilo, double hedefKilo, double boy) {
    final hedefBmi = hedefKilo / ((boy / 100) * (boy / 100));
    return hedefBmi >= 18.5 && hedefBmi <= 24.9;
  }
  
  static String _tahminGuvenilirlik(int veriGunSayisi) {
    if (veriGunSayisi >= 7) return 'Yüksek';
    if (veriGunSayisi >= 4) return 'Orta';
    if (veriGunSayisi >= 2) return 'Düşük';
    return 'Çok Düşük';
  }
} 