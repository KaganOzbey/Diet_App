import 'package:hive/hive.dart';
import 'yemek_ogesi_modeli.dart';

part 'ogun_girisi_modeli.g.dart';

@HiveType(typeId: 2)
class OgunGirisiModeli extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String kullaniciId;

  @HiveField(2)
  String yemekId;

  @HiveField(3)
  String yemekIsmi;

  @HiveField(4)
  double tuketilenGram;

  @HiveField(5)
  double kalori;

  @HiveField(6)
  double protein;

  @HiveField(7)
  double karbonhidrat;

  @HiveField(8)
  double yag;

  @HiveField(9)
  double lif;

  @HiveField(10)
  String ogunTipi; // Kahvaltı, Ara Öğün, Öğle Yemeği, Akşam Yemeği

  @HiveField(11)
  DateTime tuketimTarihi;

  @HiveField(12)
  DateTime kayitTarihi;

  OgunGirisiModeli({
    required this.id,
    required this.kullaniciId,
    required this.yemekId,
    required this.yemekIsmi,
    required this.tuketilenGram,
    required this.kalori,
    required this.protein,
    required this.karbonhidrat,
    required this.yag,
    required this.lif,
    required this.ogunTipi,
    required this.tuketimTarihi,
    required this.kayitTarihi,
  });

  // Yemek ögesinden öğün girişi oluştur
  static OgunGirisiModeli yemektenOlustur({
    required String kullaniciId,
    required YemekOgesiModeli yemekOgesi,
    required double gramMiktari,
    required String ogunTipi,
    DateTime? tuketimTarihi,
  }) {
    final besinDegerleri = yemekOgesi.besinDegerleriGetir(gramMiktari);
    final simdi = DateTime.now();
    
    return OgunGirisiModeli(
      id: '${yemekOgesi.id}_${simdi.millisecondsSinceEpoch}',
      kullaniciId: kullaniciId,
      yemekId: yemekOgesi.id,
      yemekIsmi: yemekOgesi.isim,
      tuketilenGram: gramMiktari,
      kalori: besinDegerleri['kalori']!,
      protein: besinDegerleri['protein']!,
      karbonhidrat: besinDegerleri['karbonhidrat']!,
      yag: besinDegerleri['yag']!,
      lif: besinDegerleri['lif'] ?? 0.0,
      ogunTipi: ogunTipi,
      tuketimTarihi: tuketimTarihi ?? simdi,
      kayitTarihi: simdi,
    );
  }

  // Kısa özet metni
  String get ozetMetni {
    return '$yemekIsmi (${tuketilenGram.toStringAsFixed(0)}g) - ${kalori.toStringAsFixed(0)} kcal';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kullaniciId': kullaniciId,
      'yemekId': yemekId,
      'yemekIsmi': yemekIsmi,
      'tuketilenGram': tuketilenGram,
      'kalori': kalori,
      'protein': protein,
      'karbonhidrat': karbonhidrat,
      'yag': yag,
      'lif': lif,
      'ogunTipi': ogunTipi,
      'tuketimTarihi': tuketimTarihi.toIso8601String(),
      'kayitTarihi': kayitTarihi.toIso8601String(),
    };
  }

  static OgunGirisiModeli fromJson(Map<String, dynamic> json) {
    return OgunGirisiModeli(
      id: json['id'],
      kullaniciId: json['kullaniciId'],
      yemekId: json['yemekId'],
      yemekIsmi: json['yemekIsmi'],
      tuketilenGram: json['tuketilenGram'].toDouble(),
      kalori: json['kalori'].toDouble(),
      protein: json['protein'].toDouble(),
      karbonhidrat: json['karbonhidrat'].toDouble(),
      yag: json['yag'].toDouble(),
      lif: json['lif']?.toDouble() ?? 0.0,
      ogunTipi: json['ogunTipi'],
      tuketimTarihi: DateTime.parse(json['tuketimTarihi']),
      kayitTarihi: DateTime.parse(json['kayitTarihi']),
    );
  }
} 