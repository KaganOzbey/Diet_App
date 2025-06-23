import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/grafikler/kalori_trend_grafigi.dart';
import '../widgets/grafikler/makro_besin_grafigi.dart';
import '../widgets/grafikler/kilo_takip_grafigi.dart';
import '../widgets/grafikler/ogun_dagilimi_grafigi.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../hizmetler/grafik_servisi.dart';
import '../hizmetler/beslenme_analiz_servisi.dart';
import '../hizmetler/aylik_analiz_servisi.dart';
import '../modeller/kullanici_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import '../widgets/yukleme_gostergesi.dart';
import '../servisler/tema_servisi.dart';
import 'profil_yonetimi_ekrani.dart';

class IstatistiklerEkrani extends StatefulWidget {
  @override
  _IstatistiklerEkraniState createState() => _IstatistiklerEkraniState();
}

class _IstatistiklerEkraniState extends State<IstatistiklerEkrani>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  KullaniciModeli? kullanici;
  GunlukBeslenmeModeli? bugunBeslenme;
  List<OgunGirisiModeli> bugunOgunleri = [];
  bool yukleniyor = true;
  bool haftalikGornum = true; // true: haftalık, false: aylık

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      print('İstatistikler: Kullanıcı verileri yükleniyor...');
      
      // Önce demo kullanıcısını kontrol et
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        print('İstatistikler: Demo kullanıcısı bulundu: ${demoKullanici.email}');
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
      
      // Sonra yerel veritabanından kontrol et
      final mevcutKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (mevcutKullanici != null) {
        print('İstatistikler: Yerel kullanıcı bulundu: ${mevcutKullanici.email}');
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
      
      print('İstatistikler: Hiçbir kullanıcı bulunamadı');
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
        title: Text('İstatistikler ve Analiz'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Dark Mode Toggle İkonu
          Consumer<TemaServisi>(
            builder: (context, temaServisi, child) {
              return IconButton(
                icon: Icon(
                  temaServisi.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 26,
                ),
                tooltip: temaServisi.isDarkMode ? 'Açık Tema' : 'Koyu Tema',
                onPressed: () {
                  temaServisi.toggleTheme();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            temaServisi.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            temaServisi.isDarkMode 
                              ? '🌙 Koyu tema aktifleştirildi' 
                              : '☀️ Açık tema aktifleştirildi',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      backgroundColor: temaServisi.isDarkMode ? Colors.grey[800] : Colors.green[600],
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          // Profil İkonu
          IconButton(
            icon: Icon(Icons.person, size: 26),
            tooltip: 'Profil Yönetimi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilYonetimiEkrani()),
              );
            },
          ),
          
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
            Tab(icon: Icon(Icons.timeline), text: 'Trendler'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Dağılım'),
            Tab(icon: Icon(Icons.assessment), text: 'Analiz'),
          ],
        ),
      ),
      body: yukleniyor
          ? Center(child: YuklemeHelper.pulseLogo(mesaj: 'İstatistikler yükleniyor...'))
          : kullanici == null
              ? _buildKullaniciYokMesaji()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTrendlerTab(),
                    _buildDagilimlTab(),
                    _buildAnalizTab(),
                  ],
                ),
    );
  }

  Widget _buildTrendlerTab() {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        final isDark = temaServisi.isDarkMode;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Zaman seçici
              _buildZamanSecici(isDark),
              
              SizedBox(height: 16),
              
              // Aylık özet kartları (sadece aylık görünümde)
              if (!haftalikGornum) ...[
                _buildAylikOzetKartlari(isDark),
                SizedBox(height: 16),
              ],
          
          // Kalori trend grafigi
          KaloriTrendGrafigi(
            kullaniciId: kullanici!.id,
            haftalikMi: haftalikGornum,
            hedefKalori: kullanici!.gunlukKaloriHedefi,
          ),
          
          SizedBox(height: 16),
          
          // Temel özet kartlar
          _buildOzetKartlari(),
          
              // Aylık özel analizler
              if (!haftalikGornum) ...[
                SizedBox(height: 16),
                _buildAylikTrendAnalizi(isDark),
                SizedBox(height: 16),
                _buildEnCokTuketilenBesinler(isDark),
                SizedBox(height: 16),
                _buildAylikBeslenmeKalitesiKarti(isDark),
                SizedBox(height: 16),
                _buildHaftalikAylikKarsilastirma(isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDagilimlTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Makro besin dağılımı
          MakroBesinGrafigi(
            beslenmeVerisi: bugunBeslenme,
            yukseklik: 280,
          ),
          
          SizedBox(height: 16),
          
          // Günlük hedef vs gerçek kart
          _buildHedefGercekKarti(),
          
          SizedBox(height: 16),
          
          // Öğün dağılımı
          OgunDagilimiGrafigi(
            gunlukOgunler: bugunOgunleri,
            yukseklik: 250,
          ),
          
          SizedBox(height: 16)
          
          // Kilo takip grafiki kaldırıldı - kullanıcı talebiyle
        ],
      ),
    );
  }

  Widget _buildAnalizTab() {
    if (kullanici == null) return Center(child: Text('Kullanıcı bilgisi yok'));
    
    final besinAnalizi = BeslenmeAnalizServisi.besinEksikligiAnalizi(kullanici!, bugunBeslenme);
    final oneriler = BeslenmeAnalizServisi.kisisellestirilmisOneriler(kullanici!, bugunBeslenme, besinAnalizi);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Besin eksikliği analizi
          _buildBesinAnaliziKarti(besinAnalizi),
          
          SizedBox(height: 16),
          
          // Detaylı beslenme kalitesi
          _buildBeslenmeKalitesiKarti(),
          
          SizedBox(height: 16),
          
          // Öğün zamanlaması analizi
          _buildOgunZamanlamasiKarti(),
          
          SizedBox(height: 16),
          
          // Kişiselleştirilmiş öneriler
          _buildOnerilerKartiYeni(oneriler),
          
          SizedBox(height: 16),
          
          // Su önerisi
          _buildSuOneriKarti(),
          
          SizedBox(height: 16),
          
          // Haftalık özet
          _buildHaftalikOzetKarti(),
          
          SizedBox(height: 16),
          
          // Beslenme skoru
          _buildBeslenmeSkoruKarti(),
        ],
      ),
    );
  }

  Widget _buildZamanSecici(bool isDark) {
    return Card(
      color: isDark ? Color(0xFF2E3440) : null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Zaman Aralığı:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text('Haftalık'),
                    icon: Icon(Icons.view_week),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Aylık'),
                    icon: Icon(Icons.calendar_month),
                  ),
                ],
                selected: {haftalikGornum},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() {
                    haftalikGornum = selection.first;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOzetKartlari() {
    return Row(
      children: [
        Expanded(
          child: _buildOzetKarti(
            baslik: 'Bugün',
            deger: '${bugunBeslenme?.toplamKalori.toInt() ?? 0}',
            birim: 'kcal',
            ikon: Icons.today,
            renk: Colors.blue,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildOzetKarti(
            baslik: 'Hedef',
            deger: '${kullanici!.gunlukKaloriHedefi.toInt()}',
            birim: 'kcal',
            ikon: Icons.track_changes,
            renk: Colors.green,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildOzetKarti(
            baslik: 'Kalan',
            deger: '${(kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0)).toInt()}',
            birim: 'kcal',
            ikon: Icons.timer,
            renk: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildOzetKarti({
    required String baslik,
    required String deger,
    required String birim,
    required IconData ikon,
    required Color renk,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(ikon, color: renk, size: 24),
            SizedBox(height: 8),
            Text(
              baslik,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: deger,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: renk,
                    ),
                  ),
                  TextSpan(
                    text: ' $birim',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHedefGercekKarti() {
    if (kullanici == null) return Container();
    
    final analiz = GrafikServisi.hedefGercekKarsilastirmasi(kullanici!, bugunBeslenme);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Günlük Hedef Analizi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: (analiz['basariOrani'] as num).toDouble() / 100,
              backgroundColor: Colors.grey[300],
              color: analiz['durumRengi'],
              minHeight: 8,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${analiz['gercekKalori'].toInt()} kcal'),
                Text(
                  '${analiz['basariOrani'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: analiz['durumRengi'],
                  ),
                ),
                Text('${analiz['hedefKalori'].toInt()} kcal'),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (analiz['durumRengi'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                analiz['durumMesaji'],
                style: TextStyle(color: analiz['durumRengi']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOgunDagilimiPlaceholder() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Öğün Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 32),
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Yakında Gelecek',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            Text(
              'Öğün bazında kalori dağılımı grafiği',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenelDurumKarti() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Durum',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            _buildDurumSatiri('BMR', '${kullanici!.bmr.toInt()} kcal/gün'),
            _buildDurumSatiri('Günlük Hedef', '${kullanici!.gunlukKaloriHedefi.toInt()} kcal'),
            _buildDurumSatiri('Bugün Alınan', '${bugunBeslenme?.toplamKalori.toInt() ?? 0} kcal'),
            _buildDurumSatiri('Aktivite Seviyesi', _aktiviteSeviyesiText(kullanici!.aktiviteSeviyesi)),
          ],
        ),
      ),
    );
  }

  Widget _buildDurumSatiri(String baslik, String deger) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(baslik),
          Text(
            deger,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _aktiviteSeviyesiText(int seviye) {
    switch (seviye) {
      case 1: return 'Sedanter';
      case 2: return 'Az Aktif';
      case 3: return 'Orta Aktif';
      case 4: return 'Aktif';
      case 5: return 'Çok Aktif';
      default: return 'Bilinmiyor';
    }
  }

  Widget _buildOnerilerKarti() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Öneriler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            _buildOneriItem(
              Icons.local_fire_department,
              'Günlük kalori hedefinize ulaşmaya çalışın',
              Colors.orange,
            ),
            _buildOneriItem(
              Icons.fitness_center,
              'Düzenli egzersiz yapmayı unutmayın',
              Colors.blue,
            ),
            _buildOneriItem(
              Icons.local_drink,
              'Günde en az 8 bardak su için',
              Colors.cyan,
            ),
            _buildOneriItem(
              Icons.bedtime,
              'Düzenli uyku düzeninizi koruyun',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneriItem(IconData ikon, String metin, Color renk) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(ikon, color: renk, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              metin,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHaftalikOzetKarti() {
    if (kullanici == null) return Container();
    
    return FutureBuilder<Map<String, dynamic>>(
      future: BeslenmeAnalizServisi.haftalikBeslenmeOzeti(kullanici!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Haftalık analiz yükleniyor...'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Haftalık analiz yüklenirken hata oluştu',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        
        final haftalikVeri = snapshot.data!;
        return _buildHaftalikAnalizKarti(haftalikVeri);
      },
    );
  }

  Widget _buildHaftalikAnalizKarti(Map<String, dynamic> haftalikVeri) {
    final ortalamalar = haftalikVeri['ortalamalar'] as Map<String, dynamic>;
    final tutarlilik = haftalikVeri['tutarlilik'] as double;
    final haftalikVeriler = haftalikVeri['haftalikVeriler'] as List<dynamic>;
    
    // Aktif günlerin sayısı
    final aktifGunler = haftalikVeriler.where((v) => v != null).length;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Haftalık Analiz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tutarlilikRengiGetir(tutarlilik).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _tutarlilikRengiGetir(tutarlilik)),
                  ),
                  child: Text(
                    '$aktifGunler/7 gün',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _tutarlilikRengiGetir(tutarlilik),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Ortalama değerler
            _buildHaftalikOrtalamaLari(ortalamalar),
            
            SizedBox(height: 16),
            
            // Tutarlılık skoru
            _buildTutarlilikGostergesi(tutarlilik),
            
            SizedBox(height: 16),
            
            // Haftalık trendler
            _buildHaftalikTrendler(haftalikVeriler),
            
            SizedBox(height: 16),
            
            // Haftalık öneriler
            _buildHaftalikOneriler(ortalamalar, tutarlilik, aktifGunler),
          ],
        ),
      ),
    );
  }

  Widget _buildHaftalikOrtalamaLari(Map<String, dynamic> ortalamalar) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Ortalamalar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOrtalamaItem(
                  'Kalori',
                  '${ortalamalar['kalori'].toInt()}',
                  'kcal',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildOrtalamaItem(
                  'Protein',
                  '${ortalamalar['protein'].toStringAsFixed(1)}',
                  'g',
                  Icons.fitness_center,
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOrtalamaItem(
                  'Karbonhidrat',
                  '${ortalamalar['karbonhidrat'].toStringAsFixed(1)}',
                  'g',
                  Icons.grain,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildOrtalamaItem(
                  'Yağ',
                  '${ortalamalar['yag'].toStringAsFixed(1)}',
                  'g',
                  Icons.opacity,
                  Colors.yellow[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrtalamaItem(String baslik, String deger, String birim, IconData ikon, Color renk) {
    return Column(
      children: [
        Icon(ikon, color: renk, size: 20),
        SizedBox(height: 4),
        Text(
          baslik,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: deger,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
              TextSpan(
                text: ' $birim',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTutarlilikGostergesi(double tutarlilik) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tutarlılık Skoru',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${tutarlilik.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _tutarlilikRengiGetir(tutarlilik),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: tutarlilik / 100,
          backgroundColor: Colors.grey[300],
          color: _tutarlilikRengiGetir(tutarlilik),
          minHeight: 8,
        ),
        SizedBox(height: 4),
        Text(
          _tutarlilikMesajiGetir(tutarlilik),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHaftalikTrendler(List<dynamic> haftalikVeriler) {
    final gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haftalık Aktivite',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final veri = haftalikVeriler[index];
            final aktifMi = veri != null;
            
            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: aktifMi ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      aktifMi ? Icons.check : Icons.close,
                      color: aktifMi ? Colors.white : Colors.grey[600],
                      size: 16,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  gunler[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: aktifMi ? Colors.green : Colors.grey[600],
                    fontWeight: aktifMi ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHaftalikOneriler(Map<String, dynamic> ortalamalar, double tutarlilik, int aktifGunler) {
    List<String> oneriler = [];
    
    if (aktifGunler < 5) {
      oneriler.add('📅 Daha düzenli kayıt tutmaya çalışın (${aktifGunler}/7 gün)');
    }
    
    if (tutarlilik < 70) {
      oneriler.add('⚖️ Kalori alımınızda daha tutarlı olmaya çalışın');
    }
    
    final hedefKalori = kullanici!.gunlukKaloriHedefi;
    final ortalamaKalori = ortalamalar['kalori'] as double;
    final kaloriAsimi = ortalamaKalori - hedefKalori;
    
    if (ortalamaKalori < hedefKalori * 0.8) {
      oneriler.add('⬆️ Kalori alımınızı artırmalısınız (Hedef: ${hedefKalori.toInt()})');
    } else if (kaloriAsimi > hedefKalori * 0.3) {
      // %30'dan fazla aşım = TEHLİKELİ
      oneriler.add('🚨 TEHLİKE! Çok fazla kalori alıyorsunuz (+${kaloriAsimi.toInt()} kcal)');
      oneriler.add('🏃‍♂️ ACİL: Günde en az 1 saat yoğun egzersiz yapın');
    } else if (kaloriAsimi > hedefKalori * 0.2) {
      // %20'den fazla aşım = ZARARI
      oneriler.add('⚠️ ZARARI! Kalori hedefini aşıyorsunuz (+${kaloriAsimi.toInt()} kcal)');
      oneriler.add('🚶‍♂️ En az 45 dk hızlı yürüyüş yapmalısınız');
    } else if (kaloriAsimi > hedefKalori * 0.1) {
      // %10'dan fazla aşım = DİKKAT
      oneriler.add('🟡 DİKKAT! Kalori hedefinizden fazla alıyorsunuz');
      oneriler.add('🏃‍♂️ Ek aktivite yaparak dengelemeye çalışın');
    } else if (ortalamaKalori >= hedefKalori * 0.9 && ortalamaKalori <= hedefKalori * 1.1) {
      oneriler.add('✅ Kalori dengesi ideal seviyede');
    }
    
    if (aktifGunler >= 6 && tutarlilik >= 80) {
             // Kalori aşımı kontrolü - harika demeden önce kalori durumunu kontrol et
       bool kaloriAsimVarMi = false;
       final bugun = DateTime.now();
       for (int i = 0; i < 7; i++) {
         final tarih = bugun.subtract(Duration(days: i));
        final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(kullanici!.id, tarih);
        if (gunlukBeslenme != null) {
          final kaloriAsimi = gunlukBeslenme.toplamKalori - kullanici!.gunlukKaloriHedefi;
          if (kaloriAsimi > 100) {
            kaloriAsimVarMi = true;
            break;
          }
        }
      }
      
      if (kaloriAsimVarMi) {
        oneriler.add('⚠️ Tutarlısınız ama kalori aşımı var. Egzersiz ekleyin!');
      } else {
        oneriler.add('🎉 Harika bir hafta geçirdiniz!');
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bu Hafta İçin Öneriler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...oneriler.map((oneri) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.green[600])),
                  Expanded(
                    child: Text(
                      oneri,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // Yardımcı metodlar
  Color _tutarlilikRengiGetir(double tutarlilik) {
    if (tutarlilik >= 80) return Colors.green;
    if (tutarlilik >= 60) return Colors.orange;
    return Colors.red;
  }

  String _tutarlilikMesajiGetir(double tutarlilik) {
    if (tutarlilik >= 80) return 'Çok tutarlısınız!';
    if (tutarlilik >= 60) return 'Orta seviye tutarlılık';
    if (tutarlilik >= 40) return 'Tutarlılığınızı artırın';
    return 'Çok düzensiz beslenme';
  }

  Widget _buildKullaniciYokMesaji() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Kullanıcı Bulunamadı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Lütfen giriş yapın',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBesinAnaliziKarti(Map<String, dynamic> analiz) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beslenme Analizi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            
            // Protein analizi
            _buildMakroBesinSatiri('Protein', analiz['protein']),
            SizedBox(height: 12),
            
            // Karbonhidrat analizi
            _buildMakroBesinSatiri('Karbonhidrat', analiz['karbonhidrat']),
            SizedBox(height: 12),
            
            // Yağ analizi
            _buildMakroBesinSatiri('Yağ', analiz['yag']),
            SizedBox(height: 16),
            
            // Genel durum
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _genelDurumRengiGetir(analiz['genelDurum']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _genelDurumRengiGetir(analiz['genelDurum'])),
              ),
              child: Row(
                children: [
                  Icon(
                    _genelDurumIkonuGetir(analiz['genelDurum']),
                    color: _genelDurumRengiGetir(analiz['genelDurum']),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Genel Durum: ${_genelDurumMesajiGetir(analiz['genelDurum'])}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _genelDurumRengiGetir(analiz['genelDurum']),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMakroBesinSatiri(String besinAdi, Map<String, dynamic> besinVerisi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              besinAdi,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${besinVerisi['yuzde'].toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _besinDurumRengiGetir(besinVerisi['durum']),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: (besinVerisi['yuzde'] as num).toDouble() / 100,
          backgroundColor: Colors.grey[300],
          color: _besinDurumRengiGetir(besinVerisi['durum']),
          minHeight: 6,
        ),
        SizedBox(height: 4),
        Text(
          besinVerisi['mesaj'],
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOnerilerKartiYeni(List<String> oneriler) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kişiselleştirilmiş Öneriler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            ...oneriler.map((oneri) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.green[600], fontSize: 16)),
                      Expanded(
                        child: Text(
                          oneri,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuOneriKarti() {
    if (kullanici == null) return Container();
    
    final suOnerisi = BeslenmeAnalizServisi.suOnerisi(kullanici!);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue[600], size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Su İçme Önerisi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    suOnerisi,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yardımcı metodlar
  Color _besinDurumRengiGetir(String durum) {
    switch (durum) {
      case 'iyi': return Colors.green;
      case 'orta': return Colors.orange;
      case 'eksik': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _genelDurumRengiGetir(String durum) {
    switch (durum) {
      case 'mukemmel': return Colors.green;
      case 'iyi': return Colors.lightGreen;
      case 'orta': return Colors.orange;
      case 'kotu': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _genelDurumIkonuGetir(String durum) {
    switch (durum) {
      case 'mukemmel': return Icons.star;
      case 'iyi': return Icons.thumb_up;
      case 'orta': return Icons.warning;
      case 'kotu': return Icons.error;
      default: return Icons.help;
    }
  }

  String _genelDurumMesajiGetir(String durum) {
    switch (durum) {
      case 'mukemmel': return 'Mükemmel';
      case 'iyi': return 'İyi';
      case 'orta': return 'Orta';
      case 'kotu': return 'Geliştirilmeli';
      default: return 'Belirsiz';
    }
  }

  Widget _buildAylikOzetKartlari(bool isDark) {
    final aylikOrtalama = AylikAnalizServisi.aylikOrtalamaKalori(kullanici!.id);
    final hedefOrani = AylikAnalizServisi.hedefTutturmaOrani(kullanici!.id, kullanici!.gunlukKaloriHedefi);
    final makrolar = AylikAnalizServisi.aylikOrtalamaMakrolar(kullanici!.id);
    final kalitePuani = AylikAnalizServisi.beslenmeKalitesiPuani(kullanici!.id, kullanici!);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [Color(0xFF2E3440), Color(0xFF3B4252)]
            : [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Son 30 Gün Özeti',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildAylikOzetKutusu(
                  'Ortalama Kalori',
                  '${aylikOrtalama.toInt()} kcal',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAylikOzetKutusu(
                  'Hedef Tutturma',
                  '%${hedefOrani.toInt()}',
                  Icons.track_changes,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildAylikOzetKutusu(
                  'Kalite Puanı',
                  '${kalitePuani['puan'] ?? 0}/100',
                  Icons.star,
                  Colors.yellow[700]!,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAylikOzetKutusu(
                  'Ort. Protein',
                  '${(makrolar['protein'] ?? 0.0).toInt()}g',
                  Icons.fitness_center,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAylikOzetKutusu(String baslik, String deger, IconData icon, Color renk) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 24),
          SizedBox(height: 8),
          Text(
            baslik,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          Text(
            deger,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAylikTrendAnalizi(bool isDark) {
    final trendAnalizi = AylikAnalizServisi.aylikTrendAnalizi(kullanici!.id);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2E3440) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3) 
              : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up, 
                color: isDark ? Colors.blue[300] : Colors.blue[800], 
                size: 24
              ),
              SizedBox(width: 12),
              Text(
                'Aylık Trend Analizi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blue[300] : Colors.blue[800],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTrendRengi(trendAnalizi['trend']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getTrendRengi(trendAnalizi['trend']).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTrendIkon(trendAnalizi['trend']),
                      color: _getTrendRengi(trendAnalizi['trend']),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child:                       Text(
                        trendAnalizi['aciklama'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (trendAnalizi['trend'] != 'yetersiz_veri') ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTrendDetay(
                        'İlk Hafta',
                        '${trendAnalizi['ilkHaftaOrtalama'].toInt()} kcal',
                        isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        isDark: isDark,
                      ),
                      Icon(
                        Icons.arrow_forward, 
                        color: isDark ? Colors.grey[500] : Colors.grey[400]
                      ),
                      _buildTrendDetay(
                        'Son Hafta',
                        '${trendAnalizi['sonHaftaOrtalama'].toInt()} kcal',
                        _getTrendRengi(trendAnalizi['trend']),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  Center(
                    child: Text(
                      'Değişim: ${trendAnalizi['degisim'] > 0 ? '+' : ''}${trendAnalizi['degisim'].toInt()} kcal (%${trendAnalizi['yuzdelikDegisim'].toStringAsFixed(1)})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getTrendRengi(trendAnalizi['trend']),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendDetay(String baslik, String deger, Color renk, {bool isDark = false}) {
    return Column(
      children: [
        Text(
          baslik,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          deger,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: renk,
          ),
        ),
      ],
    );
  }

  Widget _buildEnCokTuketilenBesinler(bool isDark) {
    final besinler = AylikAnalizServisi.enCokTuketilenBesinler(kullanici!.id, limit: 5);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2E3440) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3) 
              : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant, 
                color: isDark ? Colors.green[300] : Colors.green[800], 
                size: 24
              ),
              SizedBox(width: 12),
              Text(
                'En Çok Tüketilen Besinler (30 Gün)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.green[300] : Colors.green[800],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          if (besinler.isEmpty)
            Center(
              child: Text(
                'Henüz yeterli veri yok',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
          else
            Column(
              children: besinler.asMap().entries.map((entry) {
                final index = entry.key;
                final besin = entry.value;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.green[900] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.green[600]! : Colors.green[200]!
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              besin['isim'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : null,
                              ),
                            ),
                            Text(
                              '${besin['tuketimSayisi']} kez tüketildi',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${besin['toplamKalori'].toInt()} kcal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'toplam',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBeslenmeKalitesiKarti() {
    if (kullanici == null || bugunBeslenme == null) return Container();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beslenme Kalitesi Analizi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 16),
            
            Text(
              'Günlük beslenme kalitesi analizi burada gösterilecek.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOgunZamanlamasiKarti() {
    if (kullanici == null || bugunBeslenme == null) return Container();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Öğün Zamanlaması Analizi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            SizedBox(height: 16),
            
            Text(
              'Öğün zamanlaması analizi burada gösterilecek.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeslenmeSkoruKarti() {
    if (kullanici == null || bugunBeslenme == null) return Container();
    
    // Gerçek beslenme skorunu hesapla
    return FutureBuilder<Map<String, dynamic>>(
      future: BeslenmeAnalizServisi.gunlukBeslenmeSkoruHesapla(kullanici!.id, DateTime.now()),
      builder: (context, snapshot) {
        double skor = 0.0;
        String durum = 'Hesaplanıyor...';
        String aciklama = 'Beslenme skoru hesaplanıyor...';
        
        if (snapshot.hasData) {
          skor = (snapshot.data!['skor'] as int).toDouble();
          durum = snapshot.data!['durum'] as String;
          aciklama = snapshot.data!['aciklama'] as String;
        } else if (snapshot.hasError) {
          skor = bugunBeslenme!.beslenmeSkoru; // Fallback to model calculation
          durum = 'Hesaplandı';
          aciklama = 'Günlük beslenme verilerinize göre hesaplandı';
        }
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Günlük Beslenme Skoru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 20),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: skor / 100,
                        backgroundColor: Colors.grey[300],
                        color: _getSkorRengi(skor.toInt()),
                        strokeWidth: 12,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${skor.toInt()}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getSkorRengi(skor.toInt()),
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                Text(
                  durum,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getSkorRengi(skor.toInt()),
                  ),
                ),
                
                SizedBox(height: 8),
                
                Text(
                  aciklama,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSkorRengi(int skor) {
    // Kalori aşımı kontrolü - bugünkü beslenmeyi kontrol et
    if (bugunBeslenme != null && kullanici != null) {
      final kaloriAsimi = bugunBeslenme!.toplamKalori - kullanici!.gunlukKaloriHedefi;
      if (kaloriAsimi > 100) {
        return Colors.red; // Kalori aşımında kırmızı
      }
    }
    
    // Normal skor rengi (sadece kalori aşımı yoksa)
    if (skor >= 90) return Colors.green;
    if (skor >= 80) return Colors.lightGreen;
    if (skor >= 70) return Colors.blue;
    if (skor >= 60) return Colors.orange;
    if (skor >= 50) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _buildAylikBeslenmeKalitesiKarti(bool isDark) {
    final kaliteAnalizi = AylikAnalizServisi.beslenmeKalitesiPuani(kullanici!.id, kullanici!);
    final puan = (kaliteAnalizi['puan'] ?? 0) as int;
    final detaylarDynamic = kaliteAnalizi['detaylar'] as Map<String, dynamic>?;
    
    // Güvenli dönüştürme
    final detaylar = <String, double>{};
    if (detaylarDynamic != null) {
      detaylarDynamic.forEach((key, value) {
        detaylar[key] = (value as num?)?.toDouble() ?? 0.0;
      });
    }
    
    // Eğer veri yoksa demo veriler göster
    final bool veriVar = puan > 0 || detaylar.values.any((value) => value > 0);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [Color(0xFF4A5568), Color(0xFF2D3748)]
            : [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Beslenme Kalite Puanı (30 Gün)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          if (!veriVar) ...[
            // Veri yoksa bilgi mesajı göster
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Henüz Yeterli Veri Yok',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Beslenme kalite puanınızı görmek için en az 7 günlük beslenme verisi gerekli. Günlük beslenme kaydı yapmaya başlayın!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Veri varsa normal görünüm
            Row(
              children: [
                // Sol taraf - Genel puan
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$puan',
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
                      SizedBox(height: 8),
                      Text(
                        kaliteAnalizi['aciklama'] ?? 'Veri yetersiz',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 20),
                
                // Sağ taraf - Kategori detayları
                Expanded(
                  child: Column(
                    children: [
                      _buildKaliteKategorisi('Kalori Tutarlılığı', detaylar['kalori_tutarliligi'] ?? 0.0),
                      _buildKaliteKategorisi('Protein Yeterliliği', detaylar['protein_yeterliligi'] ?? 0.0),
                      _buildKaliteKategorisi('Besin Çeşitliliği', detaylar['beslenme_cesitliligi'] ?? 0.0),
                      _buildKaliteKategorisi('Veri Tutarlılığı', detaylar['gun_sayisi_tutarliligi'] ?? 0.0),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKaliteKategorisi(String baslik, double puan) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              baslik,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${puan.toInt()}/25',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHaftalikAylikKarsilastirma(bool isDark) {
    final karsilastirma = AylikAnalizServisi.haftalikAylikKarsilastirma(kullanici!.id);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2E3440) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3) 
              : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows, 
                color: isDark ? Colors.orange[300] : Colors.orange[800], 
                size: 24
              ),
              SizedBox(width: 12),
              Text(
                'Haftalık vs Aylık Karşılaştırma',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.orange[300] : Colors.orange[800],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildKarsilastirmaKutusu(
                  'Son 7 Gün Ort.',
                  '${karsilastirma['haftalikOrtalama'].toInt()} kcal',
                  '${karsilastirma['haftalikGunSayisi']} gün veri',
                  Colors.blue,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildKarsilastirmaKutusu(
                  'Son 30 Gün Ort.',
                  '${karsilastirma['aylikOrtalama'].toInt()} kcal',
                  '${karsilastirma['aylikGunSayisi']} gün veri',
                  Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Fark Analizi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${karsilastirma['fark'] > 0 ? '+' : ''}${karsilastirma['fark'].toInt()} kcal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: karsilastirma['fark'] > 0 ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  '(%${karsilastirma['yuzdelikFark'].toStringAsFixed(1)} değişim)',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKarsilastirmaKutusu(String baslik, String deger, String altMetin, Color renk, {bool isDark = false}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            baslik,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: renk,
            ),
          ),
          SizedBox(height: 8),
          Text(
            deger,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            altMetin,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendRengi(String trend) {
    switch (trend) {
      case 'artis': return Colors.red;
      case 'azalis': return Colors.green;
      case 'stabil': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getTrendIkon(String trend) {
    switch (trend) {
      case 'artis': return Icons.trending_up;
      case 'azalis': return Icons.trending_down;
      case 'stabil': return Icons.trending_flat;
      default: return Icons.help;
    }
  }
} 