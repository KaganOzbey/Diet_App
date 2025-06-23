import 'package:hive/hive.dart';

part 'kullanici_modeli.g.dart';

@HiveType(typeId: 0)
class KullaniciModeli extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String isim;

  @HiveField(3)
  double boy; // cm cinsinden

  @HiveField(4)
  double kilo; // kg cinsinden

  @HiveField(5)
  int yas;

  @HiveField(6)
  bool erkekMi;

  @HiveField(7)
  double bmr; // Bazal metabolizma hızı

  @HiveField(8)
  double gunlukKaloriHedefi;

  @HiveField(9)
  int aktiviteSeviyesi; // 1: Sedanter, 2: Az aktif, 3: Orta, 4: Aktif, 5: Çok aktif

  @HiveField(10)
  DateTime olusturulmaTarihi;

  @HiveField(11)
  DateTime guncellemeTarihi;

  @HiveField(12)
  bool emailDogrulandiMi;

  @HiveField(13)
  String hedef; // Kilo hedefi: 'Kilo Vermek', 'Kilo Almak', 'Kiloyu Korumak'

  KullaniciModeli({
    String? uid, // Firebase UID için (opsiyonel)
    required this.email,
    required this.isim,
    required this.boy,
    required this.kilo,
    required this.yas,
    required this.erkekMi,
    this.aktiviteSeviyesi = 2,
    DateTime? olusturulmaTarihi,
    DateTime? guncellemeTarihi,
    this.emailDogrulandiMi = false,
    this.hedef = 'Kiloyu Korumak',
  }) : 
    id = uid ?? DateTime.now().millisecondsSinceEpoch.toString(),
    olusturulmaTarihi = olusturulmaTarihi ?? DateTime.now(),
    guncellemeTarihi = guncellemeTarihi ?? DateTime.now(),
    bmr = 0.0,
    gunlukKaloriHedefi = 2000.0 {
    // BMR ve kalori hedefini hesapla
    this.bmr = bmrHesapla();
    this.gunlukKaloriHedefi = gunlukKaloriIhtiyaci();
  }

  // BMR hesaplama formülü (Mifflin-St Jeor)
  double bmrHesapla() {
    if (erkekMi) {
      return 10 * kilo + 6.25 * boy - 5 * yas + 5;
    } else {
      return 10 * kilo + 6.25 * boy - 5 * yas - 161;
    }
  }

  // Aktivite seviyesine göre günlük kalori ihtiyacı
  double gunlukKaloriIhtiyaci() {
    double carpan;
    switch (aktiviteSeviyesi) {
      case 1:
        carpan = 1.2; // Sedanter yaşam
        break;
      case 2:
        carpan = 1.375; // Hafif aktif
        break;
      case 3:
        carpan = 1.55; // Orta düzeyde aktif
        break;
      case 4:
        carpan = 1.725; // Çok aktif
        break;
      case 5:
        carpan = 1.9; // Aşırı aktif
        break;
      default:
        carpan = 1.375;
    }
    return bmr * carpan;
  }

  // Kullanıcı bilgilerini güncelle
  void bilgileriGuncelle({
    String? isim,
    double? boy,
    double? kilo,
    int? yas,
    bool? erkekMi,
    int? aktiviteSeviyesi,
  }) {
    if (isim != null) this.isim = isim;
    if (boy != null) this.boy = boy;
    if (kilo != null) this.kilo = kilo;
    if (yas != null) this.yas = yas;
    if (erkekMi != null) this.erkekMi = erkekMi;
    if (aktiviteSeviyesi != null) this.aktiviteSeviyesi = aktiviteSeviyesi;

    // Yeni değerlerle BMR ve kalori hedefini yeniden hesapla
    this.bmr = bmrHesapla();
    this.gunlukKaloriHedefi = gunlukKaloriIhtiyaci();
    this.guncellemeTarihi = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'isim': isim,
      'boy': boy,
      'kilo': kilo,
      'yas': yas,
      'erkekMi': erkekMi,
      'bmr': bmr,
      'gunlukKaloriHedefi': gunlukKaloriHedefi,
      'aktiviteSeviyesi': aktiviteSeviyesi,
      'olusturulmaTarihi': olusturulmaTarihi.toIso8601String(),
      'guncellemeTarihi': guncellemeTarihi.toIso8601String(),
      'emailDogrulandiMi': emailDogrulandiMi,
      'hedef': hedef,
    };
  }

  static KullaniciModeli fromJson(Map<String, dynamic> json) {
    return KullaniciModeli(
      uid: json['id'],
      email: json['email'],
      isim: json['isim'],
      boy: json['boy'].toDouble(),
      kilo: json['kilo'].toDouble(),
      yas: json['yas'],
      erkekMi: json['erkekMi'],
      aktiviteSeviyesi: json['aktiviteSeviyesi'] ?? 2,
      olusturulmaTarihi: DateTime.parse(json['olusturulmaTarihi']),
      guncellemeTarihi: DateTime.parse(json['guncellemeTarihi']),
      emailDogrulandiMi: json['emailDogrulandiMi'] ?? false,
      hedef: json['hedef'] ?? 'Kiloyu Korumak',
    )..bmr = json['bmr']?.toDouble() ?? 0.0
     ..gunlukKaloriHedefi = json['gunlukKaloriHedefi']?.toDouble() ?? 2000.0;
  }

  KullaniciModeli copyWith({
    String? id,
    String? email,
    String? isim,
    double? boy,
    double? kilo,
    int? yas,
    bool? erkekMi,
    double? bmr,
    double? gunlukKaloriHedefi,
    int? aktiviteSeviyesi,
    DateTime? olusturulmaTarihi,
    DateTime? guncellemeTarihi,
    bool? emailDogrulandiMi,
  }) {
    return KullaniciModeli(
      uid: id ?? this.id,
      email: email ?? this.email,
      isim: isim ?? this.isim,
      boy: boy ?? this.boy,
      kilo: kilo ?? this.kilo,
      yas: yas ?? this.yas,
      erkekMi: erkekMi ?? this.erkekMi,
      aktiviteSeviyesi: aktiviteSeviyesi ?? this.aktiviteSeviyesi,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
      emailDogrulandiMi: emailDogrulandiMi ?? this.emailDogrulandiMi,
    )..bmr = bmr ?? this.bmr
     ..gunlukKaloriHedefi = gunlukKaloriHedefi ?? this.gunlukKaloriHedefi;
  }
} 