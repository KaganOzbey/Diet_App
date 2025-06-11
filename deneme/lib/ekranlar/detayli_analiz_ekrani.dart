import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../hizmetler/beslenme_analiz_servisi.dart';
import '../modeller/kullanici_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import '../widgets/yukleme_gostergesi.dart';
import '../servisler/tema_servisi.dart';

class DetayliAnalizEkrani extends StatefulWidget {
  @override
  _DetayliAnalizEkraniState createState() => _DetayliAnalizEkraniState();
}

class _DetayliAnalizEkraniState extends State<DetayliAnalizEkrani> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  KullaniciModeli? kullanici;
  GunlukBeslenmeModeli? bugunBeslenme;
  List<OgunGirisiModeli> bugunOgunleri = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verileriYukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => yukleniyor = true);
    
    try {
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        final bugun = DateTime.now();
        final beslenme = VeriTabaniServisi.gunlukBeslenmeGetir(demoKullanici.id, bugun);
        final ogunler = VeriTabaniServisi.gunlukOgunGirisleriniGetir(demoKullanici.id, bugun);
        
        setState(() {
          kullanici = demoKullanici;
          bugunBeslenme = beslenme;
          bugunOgunleri = ogunler;
        });
        return;
      }
      
      final mevcutKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (mevcutKullanici != null) {
        final bugun = DateTime.now();
        final beslenme = VeriTabaniServisi.gunlukBeslenmeGetir(mevcutKullanici.id, bugun);
        final ogunler = VeriTabaniServisi.gunlukOgunGirisleriniGetir(mevcutKullanici.id, bugun);
        
        setState(() {
          kullanici = mevcutKullanici;
          bugunBeslenme = beslenme;
          bugunOgunleri = ogunler;
        });
        return;
      }
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: Text('Detaylı Analiz'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _verileriYukle,
            tooltip: 'Verileri Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.analytics), text: 'Besin Analizi'),
            Tab(icon: Icon(Icons.article), text: 'Raporlar'),
          ],
        ),
      ),
      body: yukleniyor
          ? Center(child: YuklemeHelper.pulseLogo(mesaj: 'Analiz yükleniyor...'))
          : kullanici == null
              ? _buildKullaniciYokMesaji()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBesinAnaliziTab(),
                    _buildRaporlarTab(),
                  ],
                ),
    );
  }

  Widget _buildKullaniciYokMesaji() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Kullanıcı bilgisi bulunamadı',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Lütfen önce giriş yapın',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBesinAnaliziTab() {
    if (kullanici == null) return _buildKullaniciYokMesaji();
    
    final besinAnalizi = BeslenmeAnalizServisi.besinEksikligiAnalizi(kullanici!, bugunBeslenme);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalizBasligi('Besin Değerleri Analizi'),
          SizedBox(height: 16),
          
          _buildMakroBesinAnalizi(),
          SizedBox(height: 20),
          
          _buildVitaminMineralAnalizi(besinAnalizi),
          SizedBox(height: 20),
          
          _buildGunlukPerformans(),
        ],
      ),
    );
  }

  Widget _buildRaporlarTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalizBasligi('Haftalık Rapor'),
          SizedBox(height: 16),
          
          _buildHaftalikOzet(),
          SizedBox(height: 20),
          
          _buildBeslenmePuani(),
          SizedBox(height: 20),
          
          _buildIlerlemeRaporu(),
          SizedBox(height: 20),
          
          _buildSaglikOnerileri(),
        ],
      ),
    );
  }

  Widget _buildAnalizBasligi(String baslik) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            baslik,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMakroBesinAnalizi() {
    if (bugunBeslenme == null) {
      return _buildVeriYokKarti('Makro Besin Analizi');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toplamKalori = bugunBeslenme!.toplamKalori;
    final hedefKalori = kullanici!.gunlukKaloriHedefi;
    final kaloriYuzdesi = hedefKalori > 0 ? (toplamKalori / hedefKalori * 100).toDouble() : 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Makro Besin Dağılımı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xFFF0F0F0) : Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          
          _buildMakroSatiri(
            'Kalori', 
            toplamKalori, 
            hedefKalori, 
            'kcal', 
            Colors.red,
            kaloriYuzdesi,
          ),
          _buildMakroSatiri(
            'Protein', 
            bugunBeslenme!.toplamProtein, 
            hedefKalori * 0.3 / 4,
            'g', 
            Colors.blue,
            bugunBeslenme!.toplamProtein / (hedefKalori * 0.3 / 4) * 100,
          ),
          _buildMakroSatiri(
            'Karbonhidrat', 
            bugunBeslenme!.toplamKarbonhidrat, 
            hedefKalori * 0.4 / 4,
            'g', 
            Colors.orange,
            bugunBeslenme!.toplamKarbonhidrat / (hedefKalori * 0.4 / 4) * 100,
          ),
          _buildMakroSatiri(
            'Yağ', 
            bugunBeslenme!.toplamYag, 
            hedefKalori * 0.3 / 9,
            'g', 
            Colors.purple,
            bugunBeslenme!.toplamYag / (hedefKalori * 0.3 / 9) * 100,
          ),
        ],
      ),
    );
  }

  Widget _buildMakroSatiri(String isim, double gercek, double hedef, String birim, Color renk, double yuzde) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isim,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${gercek.toStringAsFixed(1)} / ${hedef.toStringAsFixed(1)} $birim',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          LinearProgressIndicator(
            value: (yuzde / 100).clamp(0.0, 1.0),
            backgroundColor: renk.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(renk),
          ),
          SizedBox(height: 4),
          Text(
            '%${yuzde.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 12,
              color: renk,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitaminMineralAnalizi(Map<String, dynamic> besinAnalizi) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Gerçek beslenme verilerine göre tahmini vitamin/mineral değerleri
    double proteinOrani = (besinAnalizi['protein']['yuzde'] ?? 0.0).toDouble();
    double karbonhidratOrani = (besinAnalizi['karbonhidrat']['yuzde'] ?? 0.0).toDouble();
    double yagOrani = (besinAnalizi['yag']['yuzde'] ?? 0.0).toDouble();
    
    // Makro besin dengesine göre vitamin/mineral tahmini
    double vitaminC = (proteinOrani * 0.3 + karbonhidratOrani * 0.6 + yagOrani * 0.1).clamp(0.0, 100.0);
    double vitaminD = (proteinOrani * 0.5 + yagOrani * 0.4 + karbonhidratOrani * 0.1).clamp(0.0, 100.0);
    double demir = (proteinOrani * 0.7 + karbonhidratOrani * 0.2 + yagOrani * 0.1).clamp(0.0, 100.0);
    double kalsiyum = (proteinOrani * 0.6 + karbonhidratOrani * 0.3 + yagOrani * 0.1).clamp(0.0, 100.0);
    double magnezyum = (proteinOrani * 0.4 + karbonhidratOrani * 0.4 + yagOrani * 0.2).clamp(0.0, 100.0);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vitamin & Mineral Durumu (Tahmini)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xFFF0F0F0) : Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Makro besin dengenize göre tahmini değerler',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Color(0xFFBDBDBD) : Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          
          _buildVitaminSatiri('Vitamin C', vitaminC, 100, '%', Colors.orange),
          _buildVitaminSatiri('Vitamin D', vitaminD, 100, '%', Colors.yellow[700]!),
          _buildVitaminSatiri('Demir', demir, 100, '%', Colors.red[700]!),
          _buildVitaminSatiri('Kalsiyum', kalsiyum, 100, '%', Colors.blue[700]!),
          _buildVitaminSatiri('Magnezyum', magnezyum, 100, '%', Colors.purple[700]!),
        ],
      ),
    );
  }

  Widget _buildVitaminSatiri(String isim, double gercek, double hedef, String birim, Color renk) {
    final yuzde = (gercek / hedef * 100).clamp(0.0, 100.0);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              isim,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: yuzde / 100,
              backgroundColor: renk.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(renk),
            ),
          ),
          SizedBox(width: 12),
          Text(
            '%${yuzde.round()}',
            style: TextStyle(
              fontSize: 12,
              color: renk,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGunlukPerformans() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Gerçek beslenme verilerine göre performans hesapla
    double kaloriYuzdesi = 0.0;
    double beslenmeSkoru = 0.0;
    
    if (bugunBeslenme != null && kullanici != null) {
      kaloriYuzdesi = (bugunBeslenme!.toplamKalori / kullanici!.gunlukKaloriHedefi * 100).clamp(0.0, 150.0);
      
      // Makro besin dengesine göre beslenme skoru
      final proteinOrani = bugunBeslenme!.toplamProtein > 0 ? 
        (bugunBeslenme!.toplamProtein / (kullanici!.kilo * 1.2) * 100).clamp(0.0, 100.0) : 0.0;
      final karbonhidratOrani = bugunBeslenme!.toplamKarbonhidrat > 0 ? 
        (bugunBeslenme!.toplamKarbonhidrat / (kullanici!.gunlukKaloriHedefi * 0.45 / 4) * 100).clamp(0.0, 100.0) : 0.0;
      final yagOrani = bugunBeslenme!.toplamYag > 0 ? 
        (bugunBeslenme!.toplamYag / (kullanici!.gunlukKaloriHedefi * 0.25 / 9) * 100).clamp(0.0, 100.0) : 0.0;
      
      beslenmeSkoru = (proteinOrani + karbonhidratOrani + yagOrani) / 3;
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Performans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xFFF0F0F0) : Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPerformansKarti(
                  'Kalori Hedefi',
                  '${kaloriYuzdesi.round()}%',
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPerformansKarti(
                  'Öğün Sayısı',
                  '${bugunOgunleri.length}',
                  Icons.restaurant_menu,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPerformansKarti(
                  'Protein',
                  '${bugunBeslenme?.toplamProtein.round() ?? 0}g',
                  Icons.fitness_center,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPerformansKarti(
                  'Beslenme Skoru',
                  '${beslenmeSkoru.round()}%',
                  Icons.star,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformansKarti(String baslik, String yuzde, IconData icon, Color renk) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 24),
          SizedBox(height: 8),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            yuzde,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHaftalikOzet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Haftalık veriler
    if (kullanici == null) {
      return _buildVeriYokKarti('Bu Haftanın Özeti');
    }
    
    final bugun = DateTime.now();
    double haftalikToplamKalori = 0.0;
    double haftalikToplamProtein = 0.0;
    int hedefTutturanGunler = 0;
    
    // Son 7 günün verilerini hesapla
    for (int i = 0; i < 7; i++) {
      final tarih = bugun.subtract(Duration(days: i));
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullanici!.id, tarih);
      
      if (gunlukBeslenme != null) {
        haftalikToplamKalori += gunlukBeslenme.toplamKalori;
        haftalikToplamProtein += gunlukBeslenme.toplamProtein;
        
        // Hedef kalori toleransı %20
        if (gunlukBeslenme.toplamKalori >= kullanici!.gunlukKaloriHedefi * 0.8 &&
            gunlukBeslenme.toplamKalori <= kullanici!.gunlukKaloriHedefi * 1.2) {
          hedefTutturanGunler++;
        }
      }
    }
    
    final ortalamaDayKalori = haftalikToplamKalori / 7;
    final ortalamaDayProtein = haftalikToplamProtein / 7;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu Haftanın Özeti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xFFF0F0F0) : Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          
          _buildOzetSatiri('Günlük Ortalama Kalori', '${ortalamaDayKalori.round()} kcal', Icons.local_fire_department, Colors.red),
          _buildOzetSatiri('Hedef Tutturma', '$hedefTutturanGunler/7 gün', Icons.track_changes, hedefTutturanGunler >= 5 ? Colors.green : Colors.orange),
          _buildOzetSatiri('Ortalama Protein', '${ortalamaDayProtein.round()}g', Icons.fitness_center, Colors.blue),
          _buildOzetSatiri('Toplam Öğün', '${bugunOgunleri.length} öğün', Icons.restaurant_menu, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildOzetSatiri(String baslik, String deger, IconData icon, Color renk) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: renk, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              baslik,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            deger,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeslenmePuani() {
    // Gerçek beslenme verilerine göre puan hesapla
    double puan = 0.0;
    String durum = 'Veri bulunamadı';
    
    if (bugunBeslenme != null && kullanici != null) {
      // Kalori hedefine yakınlık (40 puan)
      final kaloriYuzdesi = (bugunBeslenme!.toplamKalori / kullanici!.gunlukKaloriHedefi * 100);
      final kaloriPuani = kaloriYuzdesi >= 80 && kaloriYuzdesi <= 120 ? 40.0 : 
                         kaloriYuzdesi >= 60 && kaloriYuzdesi <= 140 ? 25.0 : 10.0;
      
      // Protein hedefine yakınlık (30 puan)
      final hedefProtein = kullanici!.kilo * 1.2;
      final proteinYuzdesi = (bugunBeslenme!.toplamProtein / hedefProtein * 100);
      final proteinPuani = proteinYuzdesi >= 80 ? 30.0 : proteinYuzdesi >= 60 ? 20.0 : 10.0;
      
      // Öğün düzenliliği (20 puan)
      final ogunPuani = bugunOgunleri.length >= 3 ? 20.0 : bugunOgunleri.length >= 2 ? 15.0 : 5.0;
      
      // Çeşitlilik (10 puan)
      final cesitlilikPuani = bugunOgunleri.length > 2 ? 10.0 : 5.0;
      
      puan = kaloriPuani + proteinPuani + ogunPuani + cesitlilikPuani;
      
      if (puan >= 80) durum = 'Mükemmel! Çok dengeli besleniyorsunuz.';
      else if (puan >= 60) durum = 'İyi! Küçük iyileştirmelerle daha da iyi olabilir.';
      else if (puan >= 40) durum = 'Orta seviye. Beslenmenizi gözden geçirmelisiniz.';
      else durum = 'Beslenmenizde önemli eksiklikler var.';
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Beslenme Puanı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          Text(
                          '${puan.round()}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '100 üzerinden',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          
          Text(
            durum,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIlerlemeRaporu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (kullanici == null) {
      return _buildVeriYokKarti('İlerleme Raporu');
    }
    
    // Son 30 günün kalori ortalamalarını hesapla
    final bugun = DateTime.now();
    double son15GunOrtalama = 0.0;
    double onceki15GunOrtalama = 0.0;
    int son15GunSayisi = 0;
    int onceki15GunSayisi = 0;
    
    // Son 15 gün
    for (int i = 0; i < 15; i++) {
      final tarih = bugun.subtract(Duration(days: i));
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullanici!.id, tarih);
      if (gunlukBeslenme != null) {
        son15GunOrtalama += gunlukBeslenme.toplamKalori;
        son15GunSayisi++;
      }
    }
    
    // Önceki 15 gün (16-30 gün arası)
    for (int i = 15; i < 30; i++) {
      final tarih = bugun.subtract(Duration(days: i));
      final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullanici!.id, tarih);
      if (gunlukBeslenme != null) {
        onceki15GunOrtalama += gunlukBeslenme.toplamKalori;
        onceki15GunSayisi++;
      }
    }
    
    if (son15GunSayisi > 0) son15GunOrtalama /= son15GunSayisi;
    if (onceki15GunSayisi > 0) onceki15GunOrtalama /= onceki15GunSayisi;
    
    final kaloriFarki = son15GunOrtalama - onceki15GunOrtalama;
    final hedefKaloriFarki = kullanici!.gunlukKaloriHedefi - son15GunOrtalama;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlerleme Raporu (Son 30 Gün)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xFFF0F0F0) : Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          
          if (son15GunSayisi > 0 && onceki15GunSayisi > 0)
            _buildIlerlemeSatiri(
              'Son 15 Gün vs Önceki 15 Gün', 
              kaloriFarki > 0 
                ? '+${kaloriFarki.round()} kcal/gün artış'
                : '${kaloriFarki.round()} kcal/gün azalma',
              kaloriFarki > 0 ? Colors.orange : Colors.green, 
              kaloriFarki < 0
            ),
          
          if (son15GunSayisi > 0)
            _buildIlerlemeSatiri(
              'Hedefe Yakınlık', 
              hedefKaloriFarki.abs() <= 200 
                ? 'Hedefte! ±${hedefKaloriFarki.abs().round()} kcal'
                : hedefKaloriFarki > 0 
                  ? '${hedefKaloriFarki.round()} kcal eksik'
                  : '${(-hedefKaloriFarki).round()} kcal fazla',
              hedefKaloriFarki.abs() <= 200 ? Colors.green : Colors.orange, 
              hedefKaloriFarki.abs() <= 200
            ),
          
          _buildIlerlemeSatiri(
            'Toplam Kayıt', 
            '${son15GunSayisi}/15 son gün, ${onceki15GunSayisi}/15 önceki gün',
            son15GunSayisi >= 10 ? Colors.green : Colors.orange, 
            son15GunSayisi >= 10
          ),
          
          if (son15GunSayisi > 0)
            _buildIlerlemeSatiri(
              'Ortalama Kalori', 
              '${son15GunOrtalama.round()} kcal/gün',
              Colors.blue, 
              true
            ),
        ],
      ),
    );
  }

  Widget _buildIlerlemeSatiri(String donem, String aciklama, Color renk, bool pozitif) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: renk.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            pozitif ? Icons.trending_up : Icons.trending_down,
            color: renk,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donem,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Color(0xFFBDBDBD) : Colors.grey[600],
                  ),
                ),
                Text(
                  aciklama,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Color(0xFFF0F0F0) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaglikOnerileri() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (kullanici == null || bugunBeslenme == null) {
      return _buildVeriYokKarti('Kişisel Sağlık Önerileri');
    }
    
    // Gerçek beslenme verilerine göre analiz yap
    final besinAnalizi = BeslenmeAnalizServisi.besinEksikligiAnalizi(kullanici!, bugunBeslenme);
    
    // Kişiselleştirilmiş öneriler al
    List<String> oneriler = BeslenmeAnalizServisi.kisisellestirilmisOneriler(
      kullanici!, 
      bugunBeslenme, 
      besinAnalizi
    );
    
    // Su önerisi ekle
    final suOnerisi = BeslenmeAnalizServisi.suOnerisi(kullanici!);
    oneriler.add('💧 $suOnerisi');
    
    // Aktivite seviyesine göre ek öneriler
    if (kullanici!.aktiviteSeviyesi <= 2) {
      oneriler.add('🚶‍♂️ Aktivite seviyenizi artırın, günde 30 dakika yürüyüş yapın');
    } else if (kullanici!.aktiviteSeviyesi >= 4) {
      oneriler.add('💪 Yüksek aktiviteniz için toparlanma dönemlerine dikkat edin');
    }
    
    // Yaş grubuna göre öneriler
    final yas = kullanici!.yas;
    if (yas > 50) {
      oneriler.add('🦴 Kalsiyum ve D vitamini alımınıza dikkat edin');
    } else if (yas < 25) {
      oneriler.add('🌱 Büyüme döneminde protein alımını ihmal etmeyin');
    }
    
    // BMI'ye göre öneriler
    final bmi = kullanici!.kilo / ((kullanici!.boy / 100) * (kullanici!.boy / 100));
    if (bmi < 18.5) {
      oneriler.add('⚖️ Kilonuz idealin altında, kalori alımınızı artırın');
    } else if (bmi > 25) {
      oneriler.add('⚖️ Sağlıklı kilo verme için porsiyon kontrolü yapın');
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kişisel Sağlık Önerileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xFFF0F0F0) : Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Beslenme verilerinize göre kişiselleştirilmiş öneriler',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Color(0xFFBDBDBD) : Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          
          ...oneriler.take(6).toList().asMap().entries.map((entry) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF3A3A3C) : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Color(0xFF404040) : Colors.blue[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Color(0xFFF0F0F0) : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVeriYokKarti(String baslik) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.data_usage_outlined, size: 48, color: isDark ? Color(0xFF8E8E93) : Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xFFBDBDBD) : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Henüz yeterli veri yok',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Color(0xFF8E8E93) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 