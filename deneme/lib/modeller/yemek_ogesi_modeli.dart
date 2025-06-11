import 'package:hive/hive.dart';

part 'yemek_ogesi_modeli.g.dart';

@HiveType(typeId: 1)
class YemekOgesiModeli extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String isim;

  @HiveField(2)
  int fdcId; // USDA veritabanı ID'si

  @HiveField(3)
  double yuzGramKalori;

  @HiveField(4)
  double yuzGramProtein;

  @HiveField(5)
  double yuzGramKarbonhidrat;

  @HiveField(6)
  double yuzGramYag;

  @HiveField(7)
  double yuzGramLif;

  @HiveField(8)
  double yuzGramSeker;

  @HiveField(9)
  String kategori; // Kahvaltı, Ara Öğün, Öğle Yemeği, Akşam Yemeği

  @HiveField(10)
  DateTime eklenmeTarihi;

  @HiveField(11)
  bool favoriMi;

  YemekOgesiModeli({
    required this.id,
    required this.isim,
    required this.fdcId,
    required this.yuzGramKalori,
    this.yuzGramProtein = 0.0,
    this.yuzGramKarbonhidrat = 0.0,
    this.yuzGramYag = 0.0,
    this.yuzGramLif = 0.0,
    this.yuzGramSeker = 0.0,
    this.kategori = 'Genel',
    required this.eklenmeTarihi,
    this.favoriMi = false,
  });

  // Belirli gram miktarı için besin değerlerini hesapla
  Map<String, double> besinDegerleriGetir(double gramMiktari) {
    double carpan = gramMiktari / 100.0;
    return {
      'kalori': yuzGramKalori * carpan,
      'protein': yuzGramProtein * carpan,
      'karbonhidrat': yuzGramKarbonhidrat * carpan,
      'yag': yuzGramYag * carpan,
      'lif': yuzGramLif * carpan,
      'seker': yuzGramSeker * carpan,
    };
  }

  // Favori durumunu değiştir
  void favoriDurumunuDegistir() {
    favoriMi = !favoriMi;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isim': isim,
      'fdcId': fdcId,
      'yuzGramKalori': yuzGramKalori,
      'yuzGramProtein': yuzGramProtein,
      'yuzGramKarbonhidrat': yuzGramKarbonhidrat,
      'yuzGramYag': yuzGramYag,
      'yuzGramLif': yuzGramLif,
      'yuzGramSeker': yuzGramSeker,
      'kategori': kategori,
      'eklenmeTarihi': eklenmeTarihi.toIso8601String(),
      'favoriMi': favoriMi,
    };
  }

  static YemekOgesiModeli fromJson(Map<String, dynamic> json) {
    return YemekOgesiModeli(
      id: json['id'],
      isim: json['isim'],
      fdcId: json['fdcId'],
      yuzGramKalori: json['yuzGramKalori'].toDouble(),
      yuzGramProtein: json['yuzGramProtein']?.toDouble() ?? 0.0,
      yuzGramKarbonhidrat: json['yuzGramKarbonhidrat']?.toDouble() ?? 0.0,
      yuzGramYag: json['yuzGramYag']?.toDouble() ?? 0.0,
      yuzGramLif: json['yuzGramLif']?.toDouble() ?? 0.0,
      yuzGramSeker: json['yuzGramSeker']?.toDouble() ?? 0.0,
      kategori: json['kategori'] ?? 'Genel',
      eklenmeTarihi: DateTime.parse(json['eklenmeTarihi']),
      favoriMi: json['favoriMi'] ?? false,
    );
  }
} 