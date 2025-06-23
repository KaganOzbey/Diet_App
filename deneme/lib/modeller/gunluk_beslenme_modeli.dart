import 'package:hive/hive.dart';
import 'ogun_girisi_modeli.dart';

part 'gunluk_beslenme_modeli.g.dart';

@HiveType(typeId: 3)
class GunlukBeslenmeModeli extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String kullaniciId;

  @HiveField(2)
  DateTime tarih;

  @HiveField(3)
  double toplamKalori;

  @HiveField(4)
  double toplamProtein;

  @HiveField(5)
  double toplamKarbonhidrat;

  @HiveField(6)
  double toplamYag;

  @HiveField(7)
  double toplamLif;

  @HiveField(8)
  double kaloriHedefi;

  @HiveField(9)
  int ogunSayisi;

  @HiveField(10)
  List<String> ogunGirisiIdleri; // Öğün giriş ID'leri

  @HiveField(11)
  DateTime olusturulmaTarihi;

  @HiveField(12)
  DateTime guncellemeTarihi;

  GunlukBeslenmeModeli({
    required this.id,
    required this.kullaniciId,
    required this.tarih,
    this.toplamKalori = 0.0,
    this.toplamProtein = 0.0,
    this.toplamKarbonhidrat = 0.0,
    this.toplamYag = 0.0,
    this.toplamLif = 0.0,
    required this.kaloriHedefi,
    this.ogunSayisi = 0,
    List<String>? ogunGirisiIdleri,
    required this.olusturulmaTarihi,
    required this.guncellemeTarihi,
  }) : ogunGirisiIdleri = ogunGirisiIdleri ?? [];

  // Öğün girişlerinden günlük beslenme verilerini güncelle
  void ogunGirisleridenGuncelle(List<OgunGirisiModeli> ogunGirisleri) {
    toplamKalori = ogunGirisleri.fold(0.0, (toplam, ogun) => toplam + ogun.kalori);
    toplamProtein = ogunGirisleri.fold(0.0, (toplam, ogun) => toplam + ogun.protein);
    toplamKarbonhidrat = ogunGirisleri.fold(0.0, (toplam, ogun) => toplam + ogun.karbonhidrat);
    toplamYag = ogunGirisleri.fold(0.0, (toplam, ogun) => toplam + ogun.yag);
    toplamLif = ogunGirisleri.fold(0.0, (toplam, ogun) => toplam + ogun.lif);
    ogunSayisi = ogunGirisleri.length;
    ogunGirisiIdleri = ogunGirisleri.map((o) => o.id).toList();
    guncellemeTarihi = DateTime.now();
  }

  // Kalan kalori
  double get kalanKalori => kaloriHedefi - toplamKalori;

  // Kalori hedefinin yüzdesi
  double get kaloriIlerlemeYuzdesi => (toplamKalori / kaloriHedefi).clamp(0.0, 1.0);

  // Makro besin yüzdeleri (toplam kaloriye göre)
  double get proteinYuzdesi => toplamKalori > 0 ? (toplamProtein * 4) / toplamKalori : 0.0;
  double get karbonhidratYuzdesi => toplamKalori > 0 ? (toplamKarbonhidrat * 4) / toplamKalori : 0.0;
  double get yagYuzdesi => toplamKalori > 0 ? (toplamYag * 9) / toplamKalori : 0.0;

  // Kalori hedefi karşılandı mı
  bool get kaloriHedefiKarsilandi => toplamKalori >= kaloriHedefi * 0.9; // %90 ve üzeri

  // Beslenme kalitesi puanı (basit hesaplama) - SAĞLIK ODAKLI
  double get beslenmeSkoru {
    double puan = 0.0;
    
    // Kalori aşımı kontrolü - ÇOK KRİTİK!
    final kaloriAsimi = toplamKalori - kaloriHedefi;
    if (kaloriAsimi > 500) {
      return 5.0; // TEHLİKELİ - çok düşük puan
    } else if (kaloriAsimi > 300) {
      return 15.0; // ZARARI - düşük puan
    } else if (kaloriAsimi > 100) {
      return 25.0; // RİSKLİ - orta-düşük puan
    }
    
    // Normal kalori hedefi puanı (0-25 puan)
    if (toplamKalori >= kaloriHedefi * 0.8 && toplamKalori <= kaloriHedefi * 1.05) {
      puan += 25.0;
    } else if (toplamKalori >= kaloriHedefi * 0.6) {
      puan += 15.0;
    }
    
    // Protein yüzdesi puanı (0-25 puan) - ideal %15-30
    if (proteinYuzdesi >= 0.15 && proteinYuzdesi <= 0.30) {
      puan += 25.0;
    } else if (proteinYuzdesi >= 0.10) {
      puan += 15.0;
    }
    
    // Karbonhidrat yüzdesi puanı (0-25 puan) - ideal %45-65
    if (karbonhidratYuzdesi >= 0.45 && karbonhidratYuzdesi <= 0.65) {
      puan += 25.0;
    } else if (karbonhidratYuzdesi >= 0.30) {
      puan += 15.0;
    }
    
    // Yağ yüzdesi puanı (0-25 puan) - ideal %20-35
    if (yagYuzdesi >= 0.20 && yagYuzdesi <= 0.35) {
      puan += 25.0;
    } else if (yagYuzdesi >= 0.15) {
      puan += 15.0;
    }
    
    return puan;
  }

  // Günlük öneriler listesi
  List<String> get gunlukOneriler {
    List<String> oneriler = [];
    
    if (toplamKalori < kaloriHedefi * 0.8) {
      oneriler.add("Günlük kalori hedefinin altındasınız. Sağlıklı ara öğünler ekleyebilirsiniz.");
    } else if (toplamKalori > kaloriHedefi * 1.5) {
      oneriler.add("🚨 TEHLİKELİ SEVYYE! ${(toplamKalori - kaloriHedefi).round()} kcal fazla. ACİL 60+ dk yoğun egzersiz!");
    } else if (toplamKalori > kaloriHedefi * 1.2) {
      oneriler.add("⚠️ ZARARI! ${(toplamKalori - kaloriHedefi).round()} kcal fazla. En az 45 dk kardio egzersiz şart!");
    } else if (toplamKalori > kaloriHedefi * 0.95) {
      oneriler.add("🟡 DİKKAT! Kalori hedefinize yaklaştınız. Daha fazla yemek yemeyin!");
    }
    
    if (proteinYuzdesi < 0.15) {
      oneriler.add("Protein alımınız düşük. Et, balık, yumurta veya baklagil tüketin.");
    }
    
    if (karbonhidratYuzdesi > 0.70) {
      oneriler.add("Karbonhidrat alımınız yüksek. Sebze ve protein ağırlıklı beslenin.");
    }
    
    if (yagYuzdesi < 0.15) {
      oneriler.add("Sağlıklı yağ alımınız düşük. Avokado, kuruyemiş veya zeytinyağı ekleyin.");
    }
    
    if (ogunSayisi < 3) {
      oneriler.add("Düzenli öğün alımı için günde en az 3 öğün tüketin.");
    }
    
    return oneriler;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kullaniciId': kullaniciId,
      'tarih': tarih.toIso8601String(),
      'toplamKalori': toplamKalori,
      'toplamProtein': toplamProtein,
      'toplamKarbonhidrat': toplamKarbonhidrat,
      'toplamYag': toplamYag,
      'toplamLif': toplamLif,
      'kaloriHedefi': kaloriHedefi,
      'ogunSayisi': ogunSayisi,
      'ogunGirisiIdleri': ogunGirisiIdleri,
      'olusturulmaTarihi': olusturulmaTarihi.toIso8601String(),
      'guncellemeTarihi': guncellemeTarihi.toIso8601String(),
    };
  }

  static GunlukBeslenmeModeli fromJson(Map<String, dynamic> json) {
    return GunlukBeslenmeModeli(
      id: json['id'],
      kullaniciId: json['kullaniciId'],
      tarih: DateTime.parse(json['tarih']),
      toplamKalori: json['toplamKalori'].toDouble(),
      toplamProtein: json['toplamProtein'].toDouble(),
      toplamKarbonhidrat: json['toplamKarbonhidrat'].toDouble(),
      toplamYag: json['toplamYag'].toDouble(),
      toplamLif: json['toplamLif']?.toDouble() ?? 0.0,
      kaloriHedefi: json['kaloriHedefi'].toDouble(),
      ogunSayisi: json['ogunSayisi'],
      ogunGirisiIdleri: List<String>.from(json['ogunGirisiIdleri']),
      olusturulmaTarihi: DateTime.parse(json['olusturulmaTarihi']),
      guncellemeTarihi: DateTime.parse(json['guncellemeTarihi']),
    );
  }
} 