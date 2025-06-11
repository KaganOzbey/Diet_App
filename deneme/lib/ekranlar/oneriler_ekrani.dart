import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../modeller/kullanici_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../widgets/yukleme_gostergesi.dart';
import '../servisler/tema_servisi.dart';

class OnerilerEkrani extends StatefulWidget {
  @override
  _OnerilerEkraniState createState() => _OnerilerEkraniState();
}

class _OnerilerEkraniState extends State<OnerilerEkrani> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  KullaniciModeli? kullanici;
  GunlukBeslenmeModeli? bugunBeslenme;
  bool yukleniyor = true;

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
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        final bugun = DateTime.now();
        final beslenme = VeriTabaniServisi.gunlukBeslenmeGetir(demoKullanici.id, bugun);
        
        setState(() {
          kullanici = demoKullanici;
          bugunBeslenme = beslenme;
        });
        return;
      }
      
      final mevcutKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (mevcutKullanici != null) {
        final bugun = DateTime.now();
        final beslenme = VeriTabaniServisi.gunlukBeslenmeGetir(mevcutKullanici.id, bugun);
        
        setState(() {
          kullanici = mevcutKullanici;
          bugunBeslenme = beslenme;
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
        title: Text('Kişisel Öneriler'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _verileriYukle,
            tooltip: 'Önerileri Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.restaurant), text: 'Besin Önerileri'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Egzersiz'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Yaşam Tarzı'),
          ],
        ),
      ),
      body: yukleniyor
          ? Center(child: YuklemeHelper.pulseLogo(mesaj: 'Öneriler yükleniyor...'))
          : kullanici == null
              ? _buildKullaniciYokMesaji()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBesinOnerileriTab(),
                    _buildEgzersizTab(),
                    _buildYasamTarziTab(),
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

  Widget _buildBesinOnerileriTab() {
    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKisiselDurumKarti(),
          SizedBox(height: 20),
          
          _buildOgunOnerileri(kalanKalori),
          SizedBox(height: 20),
          
          _buildVitaminMineralOnerileri(),
          SizedBox(height: 20),
          
          _buildSuOnayiKarti(),
        ],
      ),
    );
  }

  Widget _buildEgzersizTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBaslikKarti('Günlük Egzersiz Önerileri', Icons.fitness_center, Colors.orange),
          SizedBox(height: 16),
          
          _buildEgzersizKategorileri(),
          SizedBox(height: 20),
          
          _buildEgzersizProgrami(),
          SizedBox(height: 20),
          
          _buildAktiviteHedefleri(),
        ],
      ),
    );
  }

  Widget _buildYasamTarziTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBaslikKarti('Yaşam Tarzı Önerileri', Icons.lightbulb, Colors.purple),
          SizedBox(height: 16),
          
          _buildUykuOnerileri(),
          SizedBox(height: 20),
          
          _buildStresYonetimiOnerileri(),
          SizedBox(height: 20),
          
          _buildSaglikliAliskanliklar(),
        ],
      ),
    );
  }

  Widget _buildKisiselDurumKarti() {
    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    final proteinYuzdesi = bugunBeslenme != null ? 
        (bugunBeslenme!.toplamProtein * 4 / bugunBeslenme!.toplamKalori * 100) : 0;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
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
              Icon(Icons.analytics, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Günlük Durum Analizi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDurumKutusu(
                  'Kalan Kalori',
                  '${kalanKalori.toInt()} kcal',
                  Icons.local_fire_department,
                  kalanKalori > 0 ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDurumKutusu(
                  'Protein Oranı',
                  '%${proteinYuzdesi.toInt()}',
                  Icons.fitness_center,
                  proteinYuzdesi >= 25 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kalanKalori > 500 ? 
                      'Günlük hedefinizde yer var, dengeli beslenmeye devam edin.' :
                      kalanKalori > 0 ?
                        'Hedefinize yaklaşıyorsunuz, hafif yiyecekler tercih edin.' :
                        'Günlük hedefinizi aştınız, yarın daha dikkatli olun.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumKutusu(String baslik, String deger, IconData icon, Color renk) {
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOgunOnerileri(double kalanKalori) {
    final ogunOnerileri = _getOgunOnerileri(kalanKalori);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Öğün Önerileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          
          ...ogunOnerileri.map((oneri) => _buildOneriKarti(
            oneri['isim'] as String,
            oneri['kalori'] as int,
            oneri['aciklama'] as String,
            oneri['icon'] as IconData,
            oneri['renk'] as Color,
          )).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getOgunOnerileri(double kalanKalori) {
    if (kalanKalori > 500) {
      return [
        {
          'isim': 'Avokado Tost',
          'kalori': 320,
          'aciklama': 'Tam tahıllı ekmek + avokado + domates',
          'icon': Icons.breakfast_dining,
          'renk': Colors.green,
        },
        {
          'isim': 'Protein Smoothie',
          'kalori': 280,
          'aciklama': 'Muz + süt + protein tozu + yulaf',
          'icon': Icons.local_drink,
          'renk': Colors.purple,
        },
        {
          'isim': 'Izgara Tavuk Salata',
          'kalori': 350,
          'aciklama': 'Izgara tavuk + karışık yeşillik + zeytinyağı',
          'icon': Icons.restaurant,
          'renk': Colors.orange,
        },
      ];
    } else if (kalanKalori > 200) {
      return [
        {
          'isim': 'Yoğurt & Meyve',
          'kalori': 150,
          'aciklama': 'Doğal yoğurt + karışık meyveler',
          'icon': Icons.breakfast_dining,
          'renk': Colors.pink,
        },
        {
          'isim': 'Fındık & Kuruyemiş',
          'kalori': 180,
          'aciklama': 'Karışık fındık (1 avuç)',
          'icon': Icons.eco,
          'renk': Colors.brown,
        },
      ];
    } else {
      return [
        {
          'isim': 'Elma',
          'kalori': 95,
          'aciklama': 'Orta boy taze elma',
          'icon': Icons.apple,
          'renk': Colors.red,
        },
        {
          'isim': 'Yeşil Çay',
          'kalori': 5,
          'aciklama': 'Şekersiz yeşil çay',
          'icon': Icons.local_cafe,
          'renk': Colors.green,
        },
      ];
    }
  }

  Widget _buildOneriKarti(String isim, int kalori, String aciklama, IconData icon, Color renk) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: renk,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isim,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  aciklama,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: renk,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$kalori kcal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitaminMineralOnerileri() {
    final vitaminOnerileri = [
      {
        'isim': 'Vitamin C',
        'kaynak': 'Portakal, limon, brokoli',
        'fayda': 'Bağışıklık sistemi güçlendirir',
        'icon': Icons.coronavirus,
        'renk': Colors.orange,
      },
      {
        'isim': 'Demir',
        'kaynak': 'Kırmızı et, ıspanak, mercimek',
        'fayda': 'Kan yapımını destekler',
        'icon': Icons.bloodtype,
        'renk': Colors.red,
      },
      {
        'isim': 'Kalsiyum',
        'kaynak': 'Süt, peynir, yeşil yapraklı sebzeler',
        'fayda': 'Kemik sağlığını korur',
        'icon': Icons.accessibility_new,
        'renk': Colors.blue,
      },
    ];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vitamin & Mineral Önerileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 16),
          
          ...vitaminOnerileri.map((vitamin) => Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (vitamin['renk'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (vitamin['renk'] as Color).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(vitamin['icon'] as IconData, color: vitamin['renk'] as Color, size: 24),
                    SizedBox(width: 12),
                    Text(
                      vitamin['isim'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: vitamin['renk'] as Color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '📍 Kaynaklar: ${vitamin['kaynak']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 4),
                Text(
                  '✨ Faydası: ${vitamin['fayda']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSuOnayiKarti() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan[400]!, Colors.cyan[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.local_drink, color: Colors.white, size: 48),
          SizedBox(height: 12),
          Text(
            'Su İçme Önerisi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Günde en az 2.5 litre su içmeyi hedefleyin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSuOnerisi('Sabah', '2 bardak', 'Uyanır uyanmaz'),
              _buildSuOnerisi('Öğün Arası', '1 bardak', 'Her öğün arası'),
              _buildSuOnerisi('Egzersiz', '3 bardak', 'Spor öncesi/sonrası'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuOnerisi(String zaman, String miktar, String aciklama) {
    return Column(
      children: [
        Text(
          zaman,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          miktar,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        Text(
          aciklama,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBaslikKarti(String baslik, IconData icon, Color renk) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [renk, renk.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
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

  Widget _buildEgzersizKategorileri() {
    final kategoriler = [
      {
        'isim': 'Kardiyovasküler',
        'ornekler': 'Yürüyüş, koşu, bisiklet',
        'sure': '30-45 dk',
        'icon': Icons.directions_run,
        'renk': Colors.red,
      },
      {
        'isim': 'Güç Antrenmanı',
        'ornekler': 'Ağırlık, direnç bandı',
        'sure': '20-30 dk',
        'icon': Icons.fitness_center,
        'renk': Colors.blue,
      },
      {
        'isim': 'Esneklik',
        'ornekler': 'Yoga, pilates, germe',
        'sure': '15-20 dk',
        'icon': Icons.self_improvement,
        'renk': Colors.purple,
      },
    ];

    return Column(
      children: kategoriler.map((kategori) => Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (kategori['renk'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                kategori['icon'] as IconData,
                color: kategori['renk'] as Color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kategori['isim'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    kategori['ornekler'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kategori['renk'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                kategori['sure'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEgzersizProgrami() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Haftalık Egzersiz Programı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          SizedBox(height: 16),
          
          _buildGunProgrami('Pazartesi', 'Kardio', '30 dk yürüyüş', Colors.red),
          _buildGunProgrami('Çarşamba', 'Güç', '20 dk ağırlık', Colors.blue),
          _buildGunProgrami('Cuma', 'Kardio', '40 dk koşu', Colors.red),
          _buildGunProgrami('Pazar', 'Esneklik', '30 dk yoga', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildGunProgrami(String gun, String tip, String detay, Color renk) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: renk,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              gun,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '$tip - $detay',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAktiviteHedefleri() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.track_changes, color: Colors.white, size: 48),
          SizedBox(height: 12),
          Text(
            'Aktivite Hedefleriniz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAktiviteHedefi('10.000', 'Günlük\nAdım'),
              _buildAktiviteHedefi('150 dk', 'Haftalık\nKardio'),
              _buildAktiviteHedefi('2x', 'Haftalık\nGüç'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAktiviteHedefi(String sayi, String aciklama) {
    return Column(
      children: [
        Text(
          sayi,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          aciklama,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUykuOnerileri() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.bedtime, color: Colors.purple[800], size: 24),
              SizedBox(width: 12),
              Text(
                'Uyku Önerileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildUykuOnerisi('7-9 saat uyku', 'Yetişkinler için ideal uyku süresi'),
          _buildUykuOnerisi('Düzenli uyku saatleri', 'Her gün aynı saatte yatıp kalkın'),
          _buildUykuOnerisi('Yatak odası ortamı', 'Karanlık, sessiz ve serin olsun'),
          _buildUykuOnerisi('Yatmadan önce', '1 saat öncesinden ekran kullanımını azaltın'),
        ],
      ),
    );
  }

  Widget _buildUykuOnerisi(String baslik, String aciklama) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.purple, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  aciklama,
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
    );
  }

  Widget _buildStresYonetimiOnerileri() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.psychology, color: Colors.green[800], size: 24),
              SizedBox(width: 12),
              Text(
                'Stres Yönetimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStresKarti(
                  'Nefes Egzersizi',
                  '4-7-8 tekniği',
                  Icons.air,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStresKarti(
                  'Meditasyon',
                  '10 dk günlük',
                  Icons.self_improvement,
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStresKarti(
                  'Doğa Yürüyüşü',
                  'Haftada 2-3 kez',
                  Icons.nature_people,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStresKarti(
                  'Sosyal Aktivite',
                  'Arkadaşlarla zaman',
                  Icons.group,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStresKarti(String baslik, String aciklama, IconData icon, Color renk) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 32),
          SizedBox(height: 8),
          Text(
            baslik,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            aciklama,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaglikliAliskanliklar() {
    final aliskanliklar = [
      'Her gün en az 10.000 adım atmaya çalışın',
      'Günde 5 porsiyon meyve ve sebze tüketin',
      'İşlenmiş gıdaları minimuma indirin',
      'Düzenli olarak kan değerlerinizi kontrol ettirin',
      'Günlük güneş ışığından D vitamini alın',
      'Sosyal bağlantılarınızı güçlü tutun',
    ];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.favorite, color: Colors.red[800], size: 24),
              SizedBox(width: 12),
              Text(
                'Sağlıklı Alışkanlıklar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          ...aliskanliklar.asMap().entries.map((entry) {
            final index = entry.key;
            final aliskanlik = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
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
                      aliskanlik,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
} 