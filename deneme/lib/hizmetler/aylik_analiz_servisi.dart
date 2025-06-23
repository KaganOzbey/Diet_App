import '../modeller/kullanici_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import 'veri_tabani_servisi.dart';

class AylikAnalizServisi {
  
  /// Son 30 günün beslenme verilerini getirir
  static List<GunlukBeslenmeModeli> son30GunVerileri(String kullaniciId) {
    final simdi = DateTime.now();
    final baslangic = simdi.subtract(Duration(days: 30));
    
    List<GunlukBeslenmeModeli> veriler = [];
    
    for (int i = 0; i < 30; i++) {
      final tarih = baslangic.add(Duration(days: i));
      final gunlukVeri = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
      
      if (gunlukVeri != null) {
        veriler.add(gunlukVeri);
      }
    }
    
    return veriler;
  }

  /// Aylık ortalama kalori hesaplar
  static double aylikOrtalamaKalori(String kullaniciId) {
    final veriler = son30GunVerileri(kullaniciId);
    
    if (veriler.isEmpty) return 0.0;
    
    final toplamKalori = veriler.fold<double>(0, (sum, item) => sum + item.toplamKalori);
    return toplamKalori / veriler.length;
  }

  /// Aylık ortalama makro besinler
  static Map<String, double> aylikOrtalamaMakrolar(String kullaniciId) {
    final veriler = son30GunVerileri(kullaniciId);
    
    if (veriler.isEmpty) {
      return <String, double>{
        'protein': 0.0,
        'karbonhidrat': 0.0,
        'yag': 0.0,
      };
    }

    final toplamProtein = veriler.fold<double>(0.0, (sum, item) => sum + item.toplamProtein);
    final toplamKarbonhidrat = veriler.fold<double>(0.0, (sum, item) => sum + item.toplamKarbonhidrat);
    final toplamYag = veriler.fold<double>(0.0, (sum, item) => sum + item.toplamYag);
    
    final gunSayisi = veriler.length.toDouble();
    
    return <String, double>{
      'protein': toplamProtein / gunSayisi,
      'karbonhidrat': toplamKarbonhidrat / gunSayisi,
      'yag': toplamYag / gunSayisi,
    };
  }

  /// Hedef tutturma oranı (30 gün)
  static double hedefTutturmaOrani(String kullaniciId, double hedefKalori) {
    final veriler = son30GunVerileri(kullaniciId);
    
    if (veriler.isEmpty) return 0.0;
    
    final hedefTuturanGunler = veriler.where((veri) {
      final tolerans = hedefKalori * 0.1; // %10 tolerans
      return (veri.toplamKalori >= hedefKalori - tolerans) && 
             (veri.toplamKalori <= hedefKalori + tolerans);
    }).length;
    
    return (hedefTuturanGunler / veriler.length) * 100;
  }

  /// En aktif günler analizi
  static Map<String, dynamic> enAktifGunlerAnalizi(String kullaniciId) {
    final simdi = DateTime.now();
    final baslangic = simdi.subtract(Duration(days: 30));
    
    Map<int, double> gunlukToplamKalori = {};
    
    for (int i = 0; i < 30; i++) {
      final tarih = baslangic.add(Duration(days: i));
      final ogunler = VeriTabaniServisi.gunlukOgunGirisleriniGetir(kullaniciId, tarih);
      final toplamKalori = ogunler.fold<double>(0, (sum, ogun) => sum + ogun.kalori);
      
      final haftaninGunu = tarih.weekday; // 1=Pazartesi, 7=Pazar
      gunlukToplamKalori[haftaninGunu] = (gunlukToplamKalori[haftaninGunu] ?? 0) + toplamKalori;
    }

    // En yüksek ortalamaya sahip günü bulma
    int enAktifGun = 1;
    double enYuksekOrtalama = 0;
    
    gunlukToplamKalori.forEach((gun, toplam) {
      final ortalama = toplam / 4; // 30 gün = yaklaşık 4 hafta
      if (ortalama > enYuksekOrtalama) {
        enYuksekOrtalama = ortalama;
        enAktifGun = gun;
      }
    });

    return {
      'enAktifGun': _gunIsmi(enAktifGun),
      'ortalama': enYuksekOrtalama,
      'gunlukVeriler': gunlukToplamKalori,
    };
  }

  /// Aylık trend analizi
  static Map<String, dynamic> aylikTrendAnalizi(String kullaniciId) {
    final veriler = son30GunVerileri(kullaniciId);
    
    if (veriler.length < 7) {
      return <String, dynamic>{
        'trend': 'yetersiz_veri',
        'degisim': 0.0,
        'aciklama': 'Trend analizi için en az 7 günlük veri gerekli',
        'ilkHaftaOrtalama': 0.0,
        'sonHaftaOrtalama': 0.0,
        'yuzdelikDegisim': 0.0,
      };
    }

    // İlk hafta vs son hafta karşılaştırması
    final ilkHaftaOrtalama = veriler.take(7).fold<double>(0.0, (sum, item) => sum + item.toplamKalori) / 7.0;
    final sonHaftaOrtalama = veriler.skip(veriler.length - 7).fold<double>(0.0, (sum, item) => sum + item.toplamKalori) / 7.0;
    
    final degisim = sonHaftaOrtalama - ilkHaftaOrtalama;
    final yuzdelikDegisim = ilkHaftaOrtalama > 0 ? (degisim / ilkHaftaOrtalama) * 100.0 : 0.0;

    String trend;
    String aciklama;
    
    if (yuzdelikDegisim > 5.0) {
      trend = 'artis';
      aciklama = 'Kalori alımınız artış gösteriyor';
    } else if (yuzdelikDegisim < -5.0) {
      trend = 'azalis';
      aciklama = 'Kalori alımınız azalış gösteriyor';
    } else {
      trend = 'stabil';
      aciklama = 'Kalori alımınız stabil seyrediyor';
    }

    return <String, dynamic>{
      'trend': trend,
      'degisim': degisim,
      'yuzdelikDegisim': yuzdelikDegisim,
      'aciklama': aciklama,
      'ilkHaftaOrtalama': ilkHaftaOrtalama,
      'sonHaftaOrtalama': sonHaftaOrtalama,
    };
  }

  /// En çok tüketilen besinler (30 gün)
  static List<Map<String, dynamic>> enCokTuketilenBesinler(String kullaniciId, {int limit = 10}) {
    final simdi = DateTime.now();
    final baslangic = simdi.subtract(Duration(days: 30));
    
    Map<String, double> besinTuketimleri = {};
    Map<String, int> besinSayilari = {};
    
    for (int i = 0; i < 30; i++) {
      final tarih = baslangic.add(Duration(days: i));
      final ogunler = VeriTabaniServisi.gunlukOgunGirisleriniGetir(kullaniciId, tarih);
      
      for (final ogun in ogunler) {
        besinTuketimleri[ogun.yemekIsmi] = (besinTuketimleri[ogun.yemekIsmi] ?? 0) + ogun.kalori;
        besinSayilari[ogun.yemekIsmi] = (besinSayilari[ogun.yemekIsmi] ?? 0) + 1;
      }
    }

    // Toplam kalori miktarına göre sıralama
    final siraliBesinler = besinTuketimleri.entries.map((entry) => {
      'isim': entry.key,
      'toplamKalori': entry.value,
      'tuketimSayisi': besinSayilari[entry.key] ?? 0,
      'ortalamaKalori': entry.value / (besinSayilari[entry.key] ?? 1),
    }).toList();

    siraliBesinler.sort((a, b) => (b['toplamKalori'] as double).compareTo(a['toplamKalori'] as double));
    
    return siraliBesinler.take(limit).toList();
  }

  /// Beslenme kalitesi puanı (30 gün)
  static Map<String, dynamic> beslenmeKalitesiPuani(String kullaniciId, KullaniciModeli kullanici) {
    final veriler = son30GunVerileri(kullaniciId);
    
    if (veriler.isEmpty) {
      return <String, dynamic>{
        'puan': 0,
        'aciklama': 'Veri yetersiz',
        'detaylar': <String, dynamic>{},
      };
    }

    double toplamPuan = 0;
    Map<String, dynamic> kategorilerPuani = <String, dynamic>{
      'kalori_tutarliligi': 0.0,
      'protein_yeterliligi': 0.0,
      'beslenme_cesitliligi': 0.0,
      'gun_sayisi_tutarliligi': 0.0,
    };

    // 1. Kalori tutarlılığı (hedefin %10 toleransında)
    final hedefKalori = kullanici.gunlukKaloriHedefi;
    final tutarliGunler = veriler.where((veri) {
      final tolerans = hedefKalori * 0.1;
      return (veri.toplamKalori >= hedefKalori - tolerans) && 
             (veri.toplamKalori <= hedefKalori + tolerans);
    }).length;
    kategorilerPuani['kalori_tutarliligi'] = (tutarliGunler / veriler.length) * 25.0;

    // 2. Protein yeterliliği (günlük hedefin en az %80'i)
    final proteinHedefi = hedefKalori * 0.3 / 4; // %30 protein
    final yeterliProteinGunleri = veriler.where((veri) => 
      veri.toplamProtein >= proteinHedefi * 0.8
    ).length;
    kategorilerPuani['protein_yeterliligi'] = (yeterliProteinGunleri / veriler.length) * 25.0;

    // 3. Beslenme çeşitliliği (farklı besin sayısı)
    final tumBesinler = <String>{};
    for (int i = 0; i < 30; i++) {
      final tarih = DateTime.now().subtract(Duration(days: 29 - i));
      final ogunler = VeriTabaniServisi.gunlukOgunGirisleriniGetir(kullaniciId, tarih);
      tumBesinler.addAll(ogunler.map((ogun) => ogun.yemekIsmi));
    }
    kategorilerPuani['beslenme_cesitliligi'] = (tumBesinler.length / 20).clamp(0.0, 1.0) * 25.0; // Max 20 farklı besin

    // 4. Günlük veri girişi tutarlılığı
    kategorilerPuani['gun_sayisi_tutarliligi'] = (veriler.length / 30.0) * 25.0;

    toplamPuan = kategorilerPuani.values.fold<double>(0.0, (sum, puan) => sum + (puan as double));

    // Kalori aşımı kontrolü - son 7 günü kontrol et
    bool kaloriAsimVarMi = false;
    final son7Gun = veriler.take(7);
    for (final gunlukVeri in son7Gun) {
      final kaloriAsimi = gunlukVeri.toplamKalori - hedefKalori;
      if (kaloriAsimi > 100) {
        kaloriAsimVarMi = true;
        break;
      }
    }
    
    String aciklama;
    if (kaloriAsimVarMi) {
      // Kalori aşımı varsa asla mükemmel deme
      aciklama = '⚠️ Kalori aşımı tespit edildi! Egzersiz artırın.';
      toplamPuan = (toplamPuan * 0.6).clamp(0.0, 60.0); // Puan düşür ve maks 60 yap
    } else if (toplamPuan >= 80) {
      aciklama = 'Mükemmel! Beslenme düzeniniz ideal seviyede';
    } else if (toplamPuan >= 60) {
      aciklama = 'İyi! Bazı alanlarda iyileştirme yapabilirsiniz';
    } else if (toplamPuan >= 40) {
      aciklama = 'Orta! Beslenme düzeninizi geliştirmelisiniz';
    } else {
      aciklama = 'Geliştirilmeli! Daha tutarlı beslenme gerekli';
    }

    return <String, dynamic>{
      'puan': toplamPuan.round(),
      'aciklama': aciklama,
      'detaylar': kategorilerPuani,
    };
  }

  /// Haftalık vs aylık karşılaştırma
  static Map<String, dynamic> haftalikAylikKarsilastirma(String kullaniciId) {
    final simdi = DateTime.now();
    
    // Son 7 gün
    final son7Gun = <GunlukBeslenmeModeli>[];
    for (int i = 0; i < 7; i++) {
      final tarih = simdi.subtract(Duration(days: i));
      final veri = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
      if (veri != null) son7Gun.add(veri);
    }

    // Son 30 gün
    final son30Gun = son30GunVerileri(kullaniciId);

    final haftalikOrtalama = son7Gun.isNotEmpty 
      ? son7Gun.fold<double>(0.0, (sum, item) => sum + item.toplamKalori) / son7Gun.length.toDouble()
      : 0.0;
    
    final aylikOrtalama = son30Gun.isNotEmpty
      ? son30Gun.fold<double>(0.0, (sum, item) => sum + item.toplamKalori) / son30Gun.length.toDouble()
      : 0.0;

    return <String, dynamic>{
      'haftalikOrtalama': haftalikOrtalama,
      'aylikOrtalama': aylikOrtalama,
      'fark': haftalikOrtalama - aylikOrtalama,
      'yuzdelikFark': aylikOrtalama > 0 ? ((haftalikOrtalama - aylikOrtalama) / aylikOrtalama) * 100.0 : 0.0,
      'haftalikGunSayisi': son7Gun.length,
      'aylikGunSayisi': son30Gun.length,
    };
  }

  /// Gün ismini döndürür
  static String _gunIsmi(int gunNumarasi) {
    switch (gunNumarasi) {
      case 1: return 'Pazartesi';
      case 2: return 'Salı';
      case 3: return 'Çarşamba';
      case 4: return 'Perşembe';
      case 5: return 'Cuma';
      case 6: return 'Cumartesi';
      case 7: return 'Pazar';
      default: return 'Bilinmeyen';
    }
  }

  /// İlerleme özetini getirir
  static Map<String, dynamic> ilerlemeoOzeti(String kullaniciId, KullaniciModeli kullanici) {
    final aylikVeriler = son30GunVerileri(kullaniciId);
    final trendAnalizi = aylikTrendAnalizi(kullaniciId);
    final kalitePuani = beslenmeKalitesiPuani(kullaniciId, kullanici);
    final hedefOrani = hedefTutturmaOrani(kullaniciId, kullanici.gunlukKaloriHedefi);

    return <String, dynamic>{
      'toplamGun': aylikVeriler.length,
      'trend': trendAnalizi,
      'kalitePuani': kalitePuani,
      'hedefTutturmaOrani': hedefOrani,
      'ortalamalar': aylikOrtalamaMakrolar(kullaniciId),
    };
  }
} 