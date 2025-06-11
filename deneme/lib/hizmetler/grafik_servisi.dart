import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import '../modeller/kullanici_modeli.dart';
import 'veri_tabani_servisi.dart';

class GrafikServisi {
  // Haftalık kalori trendleri için veri hazırla
  static Future<List<FlSpot>> haftalikKaloriVerisiGetir(String kullaniciId) async {
    final bugun = DateTime.now();
    final haftaBaslangici = bugun.subtract(Duration(days: 6)); // Son 7 gün
    
    List<FlSpot> veriler = [];
    
    for (int i = 0; i < 7; i++) {
      final tarih = haftaBaslangici.add(Duration(days: i));
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
      
      final kalori = gunlukBeslenme?.toplamKalori ?? 0.0;
      veriler.add(FlSpot(i.toDouble(), kalori));
    }
    
    return veriler;
  }
  
  // Aylık kalori trendleri için veri hazırla
  static Future<List<FlSpot>> aylikKaloriVerisiGetir(String kullaniciId) async {
    final bugun = DateTime.now();
    final ayBaslangici = DateTime(bugun.year, bugun.month, 1);
    final gun = bugun.day;
    
    List<FlSpot> veriler = [];
    
    for (int i = 0; i < gun; i++) {
      final tarih = DateTime(bugun.year, bugun.month, i + 1);
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullaniciId, tarih);
      
      final kalori = gunlukBeslenme?.toplamKalori ?? 0.0;
      veriler.add(FlSpot(i.toDouble(), kalori));
    }
    
    return veriler;
  }
  
  // Makro besin dağılımı için pie chart verisi
  static List<PieChartSectionData> makroBesinDagilimiGetir(GunlukBeslenmeModeli? beslenme) {
    if (beslenme == null) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 100,
          title: 'Veri Yok',
          radius: 50,
        ),
      ];
    }
    
    final toplamKalori = beslenme.toplamKalori;
    if (toplamKalori == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 100,
          title: 'Veri Yok',
          radius: 50,
        ),
      ];
    }
    
    // Makro besinlerin kalori değerleri
    final proteinKalori = beslenme.toplamProtein * 4; // 1g protein = 4 kalori
    final karbonhidratKalori = beslenme.toplamKarbonhidrat * 4; // 1g karbonhidrat = 4 kalori
    final yagKalori = beslenme.toplamYag * 9; // 1g yağ = 9 kalori
    
    final toplamMakroKalori = proteinKalori + karbonhidratKalori + yagKalori;
    
    return [
      PieChartSectionData(
        color: Colors.red[400],
        value: proteinKalori,
        title: 'Protein\n${(proteinKalori / toplamMakroKalori * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.blue[400],
        value: karbonhidratKalori,
        title: 'Karbonhidrat\n${(karbonhidratKalori / toplamMakroKalori * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange[400],
        value: yagKalori,
        title: 'Yağ\n${(yagKalori / toplamMakroKalori * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
  
  // Kilo takibi için veri (şimdilik simüle edilmiş)
  static Future<List<FlSpot>> kiloTakipVerisiGetir(String kullaniciId) async {
    final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
    if (kullanici == null) return [];
    
    // Şimdilik statik veri döndürelim, ileride kilo takip sistemi eklenecek
    final bugun = DateTime.now();
    List<FlSpot> veriler = [];
    
    for (int i = 0; i < 30; i++) {
      final tarih = bugun.subtract(Duration(days: 29 - i));
      // Basit bir simulasyon - gerçekte kullanıcının kilo kayıtları olacak
      final kiloDegisimi = (i * 0.05) + (i % 3 == 0 ? -0.1 : 0.05);
      final kilo = kullanici.kilo - kiloDegisimi;
      veriler.add(FlSpot(i.toDouble(), kilo));
    }
    
    return veriler;
  }
  
  // Öğün dağılımı bar chart verisi
  static List<BarChartGroupData> ogunDagilimiGetir(List<OgunGirisiModeli> gunlukOgunler) {
    Map<String, double> ogunKalorileri = {
      'Kahvaltı': 0,
      'Ara Öğün': 0,
      'Öğle Yemeği': 0,
      'Akşam Yemeği': 0,
    };
    
    for (final ogun in gunlukOgunler) {
      ogunKalorileri[ogun.ogunTipi] = (ogunKalorileri[ogun.ogunTipi] ?? 0) + ogun.kalori;
    }
    
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    
    ogunKalorileri.forEach((ogunTipi, kalori) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: kalori,
              color: _ogunRengiGetir(ogunTipi),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      index++;
    });
    
    return barGroups;
  }
  
  // Hedef vs Gerçek karşılaştırması
  static Map<String, dynamic> hedefGercekKarsilastirmasi(
    KullaniciModeli kullanici,
    GunlukBeslenmeModeli? beslenme,
  ) {
    final hedefKalori = kullanici.gunlukKaloriHedefi;
    final gercekKalori = beslenme?.toplamKalori ?? 0;
    
    final basariOrani = gercekKalori / hedefKalori * 100;
    final fark = gercekKalori - hedefKalori;
    
    return {
      'hedefKalori': hedefKalori,
      'gercekKalori': gercekKalori,
      'basariOrani': basariOrani,
      'fark': fark,
      'durumRengi': _basariDurumuRengiGetir(basariOrani),
      'durumMesaji': _basariDurumuMesajiGetir(basariOrani),
    };
  }
  
  // Yardımcı metodlar
  static Color _ogunRengiGetir(String ogunTipi) {
    switch (ogunTipi) {
      case 'Kahvaltı':
        return Colors.orange[400]!;
      case 'Ara Öğün':
        return Colors.purple[400]!;
      case 'Öğle Yemeği':
        return Colors.blue[400]!;
      case 'Akşam Yemeği':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
  }
  
  static Color _basariDurumuRengiGetir(num oran) {
    if (oran >= 80 && oran <= 120) {
      return Colors.green; // İdeal aralık
    } else if (oran >= 60 && oran < 140) {
      return Colors.orange; // Orta
    } else {
      return Colors.red; // Kötü
    }
  }
  
  static String _basariDurumuMesajiGetir(num oran) {
    if (oran >= 80 && oran <= 120) {
      return 'Mükemmel! Hedefinize çok yakınsınız.';
    } else if (oran < 80) {
      return 'Daha fazla kalori almalısınız.';
    } else if (oran > 120 && oran <= 140) {
      return 'Hedefi biraz aştınız, dikkatli olun.';
    } else {
      return 'Hedefi çok aştınız, dikkat edin.';
    }
  }
  
  // Hafta günü etiketleri
  static List<String> get haftaGunleri => [
    'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'
  ];
  
  // Öğün etiketleri
  static List<String> get ogunEtiketleri => [
    'Kahvaltı', 'Ara Öğün', 'Öğle', 'Akşam'
  ];
} 