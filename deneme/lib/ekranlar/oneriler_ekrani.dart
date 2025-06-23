import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../hizmetler/beslenme_analiz_servisi.dart';
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
  Map<String, dynamic>? beslenmeSkoru;
  Map<String, dynamic>? eksikBesinler;
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
    print('🔄 Öneriler verileri yükleniyor...');
    setState(() => yukleniyor = true);
    
    try {
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        print('✅ Demo kullanıcı bulundu: ${demoKullanici.email}');
        await _analizVerieriYukle(demoKullanici);
        return;
      }
      
      final mevcutKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (mevcutKullanici != null) {
        print('✅ Yerel kullanıcı bulundu: ${mevcutKullanici.email}');
        await _analizVerieriYukle(mevcutKullanici);
        return;
      }
      
      print('❌ Hiçbir kullanıcı bulunamadı');
      setState(() {
        kullanici = null;
        bugunBeslenme = null;
        beslenmeSkoru = null;
        eksikBesinler = <String, dynamic>{};
      });
    } catch (e, stackTrace) {
      print('❌ Veri yükleme hatası: $e');
      print('Stack trace: $stackTrace');
      
      // Hata durumunda güvenli state'e geç
      setState(() {
        beslenmeSkoru = {
          'skor': 0,
          'durum': 'Hata',
          'aciklama': 'Veri yükleme sırasında bir hata oluştu',
          'detaylar': <String, dynamic>{},
        };
        eksikBesinler = <String, dynamic>{};
      });
    } finally {
      setState(() => yukleniyor = false);
      print('✅ Veri yükleme tamamlandı');
    }
  }

  Future<void> _analizVerieriYukle(KullaniciModeli user) async {
    try {
      print('Analiz verileri yükleniyor: ${user.id}');
      final bugun = DateTime.now();
      final beslenme = VeriTabaniServisi.gunlukBeslenmeGetir(user.id, bugun);
      
      print('Beslenme verisi: ${beslenme?.toplamKalori}');
      
      // Beslenme skorunu ve eksik besinleri hesapla
      Map<String, dynamic> skorAnalizi = {
        'skor': 0,
        'durum': 'Veri Yok',
        'aciklama': 'Henüz beslenme verisi yok',
        'detaylar': <String, dynamic>{},
      };
      
      try {
        skorAnalizi = await BeslenmeAnalizServisi.gunlukBeslenmeSkoruHesapla(user.id, bugun);
        print('Skor analizi tamamlandı: ${skorAnalizi['skor']}');
      } catch (e) {
        print('Skor analizi hatası: $e');
      }
      
      Map<String, dynamic> eksikler = <String, dynamic>{};
      if (beslenme != null && skorAnalizi['detaylar'] != null) {
        try {
          eksikler = BeslenmeAnalizServisi.eksikBesinleriTespitEt(skorAnalizi['detaylar']);
        } catch (e) {
          print('Eksik besin hesaplama hatası: $e');
          eksikler = <String, dynamic>{};
        }
      }
      
      print('Eksik besinler hesaplandı: ${eksikler.keys}');
      
      setState(() {
        kullanici = user;
        bugunBeslenme = beslenme;
        beslenmeSkoru = skorAnalizi;
        eksikBesinler = eksikler;
      });
      
      print('State güncellendi başarıyla');
    } catch (e, stackTrace) {
      print('_analizVerieriYukle hatası: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        kullanici = user;
        bugunBeslenme = null;
        beslenmeSkoru = {
          'skor': 0,
          'durum': 'Hata',
          'aciklama': 'Veri yükleme hatası oluştu',
          'detaylar': <String, dynamic>{},
        };
        eksikBesinler = <String, dynamic>{};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        final isDark = temaServisi.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: Text('Kişisel Öneriler'),
        backgroundColor: Color(0xFF4CAF50), // Green
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
      body: Builder(
        builder: (context) {
          print('📱 Öneriler Body Build - yukleniyor: $yukleniyor, kullanici: ${kullanici?.email}, beslenmeSkoru: ${beslenmeSkoru?['skor']}');
          
          if (yukleniyor) {
            return Center(child: YuklemeHelper.pulseLogo(mesaj: 'Öneriler yükleniyor...'));
          }
          
          if (kullanici == null) {
            print('❌ Kullanıcı yok');
            return _buildKullaniciYokMesaji();
          }
          
          if (beslenmeSkoru == null) {
            print('❌ Beslenme skoru yok');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Analiz verileri hazırlanıyor...',
                    style: TextStyle(
                      fontSize: 18, 
                      color: isDark ? Colors.white : Colors.grey[600]
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Günlük beslenme kaydı yaparsanız kişisel öneriler alabilirsiniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, 
                      color: isDark ? Colors.grey[400] : Colors.grey[500]
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _verileriYukle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                    child: Text('Verileri Yenile', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          
          print('✅ TabBarView gösteriliyor');
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBesinOnerileriTabSafe(isDark),
              _buildEgzersizTabSafe(isDark),
              _buildYasamTarziTabSafe(isDark),
            ],
          );
        },
      ),
        );
      },
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

  Widget _buildBesinOnerileriTabSafe(bool isDark) {
    try {
      print('🥗 Besin önerileri tab build ediliyor...');
      final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKisiselDurumKartiSafe(isDark),
            SizedBox(height: 20),
            
            _buildOgunOnerileriSafe(kalanKalori, isDark),
            SizedBox(height: 20),
            
            _buildVitaminMineralOnerileriSafe(isDark),
            SizedBox(height: 20),
            
            _buildSuOnayiKartiSafe(isDark),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Besin önerileri tab hatası: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Besin önerileri yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _verileriYukle,
              child: Text('Yeniden Dene'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBesinOnerileriTab(bool isDark) {
    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKisiselDurumKarti(isDark),
          SizedBox(height: 20),
          
          _buildOgunOnerileri(kalanKalori, isDark),
          SizedBox(height: 20),
          
          _buildVitaminMineralOnerileri(isDark),
          SizedBox(height: 20),
          
          _buildSuOnayiKarti(isDark),
        ],
      ),
    );
  }

  Widget _buildEgzersizTabSafe(bool isDark) {
    try {
      print('🏃‍♂️ Egzersiz tab build ediliyor...');
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBaslikKartiSafe('Günlük Egzersiz Önerileri', Icons.fitness_center, Colors.orange, isDark),
            SizedBox(height: 16),
            
            _buildEgzersizKategorileriSafe(isDark),
            SizedBox(height: 20),
            
            _buildEgzersizProgramiSafe(isDark),
            SizedBox(height: 20),
            
            _buildAktiviteHedefleriSafe(isDark),
          ],
        ),
      );
    } catch (e) {
      print('❌ Egzersiz tab hatası: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            Text('Egzersiz önerileri yüklenemedi', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ElevatedButton(onPressed: _verileriYukle, child: Text('Yeniden Dene')),
          ],
        ),
      );
    }
  }

  Widget _buildEgzersizTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBaslikKarti('Günlük Egzersiz Önerileri', Icons.fitness_center, Colors.orange, isDark),
          SizedBox(height: 16),
          
          _buildEgzersizKategorileri(isDark),
          SizedBox(height: 20),
          
          _buildEgzersizProgrami(isDark),
          SizedBox(height: 20),
          
          _buildAktiviteHedefleri(isDark),
        ],
      ),
    );
  }

  Widget _buildYasamTarziTabSafe(bool isDark) {
    try {
      print('💡 Yaşam tarzı tab build ediliyor...');
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBaslikKartiSafe('Yaşam Tarzı Önerileri', Icons.lightbulb, Colors.purple, isDark),
            SizedBox(height: 16),
            
            _buildUykuOnerileriSafe(isDark),
            SizedBox(height: 20),
            
            _buildStresYonetimiOnerileriSafe(isDark),
            SizedBox(height: 20),
            
            _buildSaglikliAliskanliklarSafe(isDark),
          ],
        ),
      );
    } catch (e) {
      print('❌ Yaşam tarzı tab hatası: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            Text('Yaşam tarzı önerileri yüklenemedi', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ElevatedButton(onPressed: _verileriYukle, child: Text('Yeniden Dene')),
          ],
        ),
      );
    }
  }

  Widget _buildYasamTarziTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBaslikKarti('Yaşam Tarzı Önerileri', Icons.lightbulb, Colors.purple, isDark),
          SizedBox(height: 16),
          
          _buildUykuOnerileri(isDark),
          SizedBox(height: 20),
          
          _buildStresYonetimiOnerileri(isDark),
          SizedBox(height: 20),
          
          _buildSaglikliAliskanliklar(isDark),
        ],
      ),
    );
  }

  Widget _buildKisiselDurumKarti(bool isDark) {
    try {
      if (beslenmeSkoru == null || kullanici == null) {
        return _buildBasitDurumKarti(isDark);
      }

      final skor = beslenmeSkoru!['skor'] as int;
      final durum = beslenmeSkoru!['durum'] as String;
      final aciklama = beslenmeSkoru!['aciklama'] as String;
      
      final detaylar = beslenmeSkoru!['detaylar'] as Map<String, dynamic>?;
      if (detaylar == null) {
        print('Detaylar null, basit kart gösteriliyor');
        return _buildBasitDurumKarti(isDark);
      }
      
      final hedefler = detaylar['hedefler'] as Map<String, double>?;
      final alinan = detaylar['alinan'] as Map<String, dynamic>?;
      
      if (hedefler == null || alinan == null) {
        print('Hedefler ya da alınan null, basit kart gösteriliyor');
        return _buildBasitDurumKarti(isDark);
      }
      
      final kalanKalori = (hedefler['kalori'] ?? 2000.0) - (alinan['kalori'] as double? ?? 0.0);
      
      print('Beslenme skoru başarıyla yüklendi: skor=$skor, durum=$durum');
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getSkorRenkGradyani(skor),
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
              Expanded(
                child: Text(
                  'Beslenme Analizi - $durum',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$skor/100',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                  'Protein',
                  '${(alinan['protein'] as double? ?? 0.0).toInt()}g/${hedefler['protein']!.toInt()}g',
                  Icons.fitness_center,
                  (alinan['protein'] as double? ?? 0.0) >= hedefler['protein']! * 0.8 ? Colors.green : Colors.orange,
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
                Icon(_getSkorIconu(skor), color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    aciklama,
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
    } catch (e) {
      print('_buildKisiselDurumKarti hatası: $e');
      return _buildBasitDurumKarti(isDark);
    }
  }

  Widget _buildBasitDurumKarti(bool isDark) {
    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[600]!],
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
                'Temel Analiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildDurumKutusu(
            'Kalan Kalori',
            '${kalanKalori.toInt()} kcal',
            Icons.local_fire_department,
            kalanKalori > 0 ? Colors.green : Colors.red,
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
                    'Daha detaylı analiz için yemek giriş yapın',
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

  List<Color> _getSkorRenkGradyani(int skor) {
    if (skor >= 80) return [Colors.green[400]!, Colors.green[600]!];
    if (skor >= 60) return [Colors.blue[400]!, Colors.blue[600]!];
    if (skor >= 40) return [Colors.orange[400]!, Colors.orange[600]!];
    return [Colors.red[400]!, Colors.red[600]!];
  }

  IconData _getSkorIconu(int skor) {
    if (skor >= 80) return Icons.sentiment_very_satisfied;
    if (skor >= 60) return Icons.sentiment_satisfied;
    if (skor >= 40) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
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

  Widget _buildOgunOnerileri(double kalanKalori, bool isDark) {
    final ogunOnerileri = _getDinamikOgunOnerileri();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black54 : Colors.black).withOpacity(0.1),
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
              Icon(Icons.restaurant_menu, color: Color(0xFF4CAF50), size: 24),
              SizedBox(width: 8),
              Text(
                'Kişisel Öğün Önerileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Eksik besinlerinize göre özel olarak seçildi',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          
          ...ogunOnerileri.map((oneri) => _buildOneriKarti(
            oneri['isim'] as String,
            oneri['kalori'] as int,
            oneri['aciklama'] as String,
            oneri['icon'] as IconData,
            oneri['renk'] as Color,
            isDark,
          )).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDinamikOgunOnerileri() {
    if (eksikBesinler == null || eksikBesinler!.isEmpty) {
      return _getVarsayilanOnerileri();
    }

    List<Map<String, dynamic>> onerileriListesi = [];

    // Kalori eksikliği varsa
    if (eksikBesinler!.containsKey('kalori')) {
      final eksikMiktar = eksikBesinler!['kalori']['eksikMiktar'] as double;
      if (eksikMiktar > 300) {
        // Mega besin veritabanından yüksek kalorili besinler öner
        final yuksekKaloriliBesin = _getYuksekKaloriliBesin();
        onerileriListesi.add({
          'isim': yuksekKaloriliBesin['isim'],
          'kalori': yuksekKaloriliBesin['kalori'],
          'aciklama': 'Sağlıklı yağlar ve protein için ${eksikMiktar.toInt()} kcal eksikliğinize yardımcı',
          'icon': Icons.grain,
          'renk': Colors.orange,
        });
      } else {
        // Orta kalorili besinler öner
        final ortaKaloriliBesin = _getOrtaKaloriliBesin();
        onerileriListesi.add({
          'isim': ortaKaloriliBesin['isim'],
          'kalori': ortaKaloriliBesin['kalori'],
          'aciklama': 'Hafif kalori takviyesi için doğal seçenek',
          'icon': Icons.apple,
          'renk': Colors.green,
        });
      }
    }

    // Protein eksikliği varsa
    if (eksikBesinler!.containsKey('protein')) {
      final eksikMiktar = eksikBesinler!['protein']['eksikMiktar'] as double;
      final proteinliBesin = _getProteinliBesin();
      onerileriListesi.add({
        'isim': proteinliBesin['isim'],
        'kalori': proteinliBesin['kalori'],
        'aciklama': '${proteinliBesin['protein']}g protein ile ${eksikMiktar.toInt()}g eksik proteine çözüm',
        'icon': Icons.local_drink,
        'renk': Colors.purple,
      });
    }

    // Lif eksikliği varsa  
    if (eksikBesinler!.containsKey('lif')) {
      final lifliBesin = _getLifliBesin();
      onerileriListesi.add({
        'isim': lifliBesin['isim'],
        'kalori': lifliBesin['kalori'],
        'aciklama': '${lifliBesin['lif']}g lif ile sindirim sağlığınızı destekler',
        'icon': Icons.local_florist,
        'renk': Colors.green,
      });
    }

    // Eksiklik yoksa dengeli öneriler
    if (onerileriListesi.isEmpty) {
      return _getVarsayilanOnerileri();
    }

    return onerileriListesi.take(3).toList();
  }

  Map<String, dynamic> _getYuksekKaloriliBesin() {
    // Mega besin veritabanından yüksek kalorili sağlıklı besinler
    final yuksekKaloriliBesinler = [
      {'isim': 'Ceviz (30g)', 'kalori': 196, 'protein': 4.3, 'yag': 18.5},
      {'isim': 'Badem (30g)', 'kalori': 173, 'protein': 6.4, 'yag': 14.8},
      {'isim': 'Avokado (100g)', 'kalori': 160, 'protein': 2.0, 'yag': 14.7},
      {'isim': 'Fındık (30g)', 'kalori': 188, 'protein': 4.2, 'yag': 17.2},
    ];
    return yuksekKaloriliBesinler[DateTime.now().millisecond % yuksekKaloriliBesinler.length];
  }

  Map<String, dynamic> _getOrtaKaloriliBesin() {
    final ortaKaloriliBesinler = [
      {'isim': 'Yoğurt + Muz', 'kalori': 150, 'protein': 8.0, 'karbonhidrat': 22},
      {'isim': 'Tam Tahıl Ekmek + Peynir', 'kalori': 180, 'protein': 12.0, 'karbonhidrat': 18},
      {'isim': 'Elma + Fıstık Ezmesi', 'kalori': 190, 'protein': 8.0, 'yag': 16},
    ];
    return ortaKaloriliBesinler[DateTime.now().millisecond % ortaKaloriliBesinler.length];
  }

  Map<String, dynamic> _getProteinliBesin() {
    final proteinliBesinler = [
      {'isim': 'Tavuk Göğsü (100g)', 'kalori': 165, 'protein': 31.0},
      {'isim': 'Yumurta (2 adet)', 'kalori': 155, 'protein': 12.6},
      {'isim': 'Ton Balığı (100g)', 'kalori': 116, 'protein': 25.4},
      {'isim': 'Yunan Yoğurdu (150g)', 'kalori': 130, 'protein': 15.0},
    ];
    return proteinliBesinler[DateTime.now().millisecond % proteinliBesinler.length];
  }

  Map<String, dynamic> _getLifliBesin() {
    final lifliBesinler = [
      {'isim': 'Yeşil Salata + Tam Tahıl', 'kalori': 180, 'lif': 8.5},
      {'isim': 'Armut + Yulaf Ezmesi', 'kalori': 220, 'lif': 9.2},
      {'isim': 'Brokoli + Esmer Pirinç', 'kalori': 160, 'lif': 7.8},
      {'isim': 'Fasulye Salatası', 'kalori': 200, 'lif': 12.0},
    ];
    return lifliBesinler[DateTime.now().millisecond % lifliBesinler.length];
  }

  List<Map<String, dynamic>> _getVarsayilanOnerileri() {
    return [
      {
        'isim': 'Meyve ve Yoğurt',
        'kalori': 180,
        'aciklama': 'Doğal şeker ve protein kaynağı',
        'icon': Icons.apple,
        'renk': Colors.green,
      },
      {
        'isim': 'Fındık ve Kuruyemiş',
        'kalori': 220,
        'aciklama': 'Sağlıklı yağlar ve enerji',
        'icon': Icons.grain,
        'renk': Colors.orange,
      },
    ];
  }

  Widget _buildOneriKarti(String isim, int kalori, String aciklama, IconData icon, Color renk, bool isDark) {
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
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  aciklama,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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

  Widget _buildVitaminMineralOnerileri(bool isDark) {
    final vitaminOnerileri = _getDinamikVitaminOnerileri();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black54 : Colors.black).withOpacity(0.1),
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
              Icon(Icons.health_and_safety, color: Colors.purple[600], size: 24),
              SizedBox(width: 8),
              Text(
                'Eksik Besin Değerleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.purple[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Günlük beslenme analizinize göre öneriler',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          
          vitaminOnerileri.isEmpty 
            ? _buildTamBesinMesaji(isDark)
            : Column(
                children: vitaminOnerileri.map((vitamin) => Container(
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
                          Expanded(
                            child: Text(
                              vitamin['isim'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: vitamin['renk'] as Color,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: vitamin['renk'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vitamin['eksikMiktar'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '📍 Kaynaklar: ${vitamin['kaynak']}',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '✨ Faydası: ${vitamin['fayda']}',
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ],
                  ),
                )).toList(),
              ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDinamikVitaminOnerileri() {
    if (eksikBesinler == null || eksikBesinler!.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> vitaminOnerileri = [];

    eksikBesinler!.forEach((besinAdi, besinBilgi) {
      final eksikMiktar = (besinBilgi['eksikMiktar'] as double?) ?? 0.0;
      final yuzde = (besinBilgi['yuzde'] as double?) ?? 0.0;
      
      switch (besinAdi) {
        case 'protein':
          vitaminOnerileri.add({
            'isim': 'Protein Eksikliği',
            'kaynak': 'Tavuk, balık, yumurta, baklagiller',
            'fayda': 'Kas gelişimi ve onarımı',
            'icon': Icons.fitness_center,
            'renk': Colors.red,
            'eksikMiktar': '${eksikMiktar.toInt()}g eksik',
          });
          break;
        case 'karbonhidrat':
          vitaminOnerileri.add({
            'isim': 'Karbonhidrat Eksikliği',
            'kaynak': 'Tam tahıllar, meyveler, sebzeler',
            'fayda': 'Enerji kaynağı',
            'icon': Icons.bolt,
            'renk': Colors.orange,
            'eksikMiktar': '${eksikMiktar.toInt()}g eksik',
          });
          break;
        case 'yag':
          vitaminOnerileri.add({
            'isim': 'Sağlıklı Yağ Eksikliği',
            'kaynak': 'Zeytinyağı, avokado, fındık',
            'fayda': 'Hücre yapısı ve vitamin emilimi',
            'icon': Icons.opacity,
            'renk': Colors.green,
            'eksikMiktar': '${eksikMiktar.toInt()}g eksik',
          });
          break;
        case 'lif':
          vitaminOnerileri.add({
            'isim': 'Lif Eksikliği',
            'kaynak': 'Sebzeler, meyveler, tam tahıllar',
            'fayda': 'Sindirim sağlığı',
            'icon': Icons.local_florist,
            'renk': Colors.purple,
            'eksikMiktar': '${eksikMiktar.toInt()}g eksik',
          });
          break;
        case 'kalori':
          if (eksikMiktar > 100) {
            vitaminOnerileri.add({
              'isim': 'Kalori Eksikliği',
              'kaynak': 'Dengeli ara öğünler',
              'fayda': 'Enerji dengesini korur',
              'icon': Icons.local_fire_department,
              'renk': Colors.blue,
              'eksikMiktar': '${eksikMiktar.toInt()} kcal',
            });
          }
          break;
      }
    });

    return vitaminOnerileri.take(3).toList(); // Maksimum 3 öneri
  }

  Widget _buildTamBesinMesaji(bool isDark) {
    // Gerçek besin verilerini kontrol et
    bool gercektenDengeli = _beslenmeGercektenDengeliMi();
    
    if (!gercektenDengeli) {
      // Besin girişi yoksa veya eksikler varsa uyarı mesajı
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 48),
            SizedBox(height: 12),
            Text(
              'Beslenme Verisi Eksik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _getBeslenmeEksiklikMesaji(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      );
    }
    
    // Gerçekten dengeli ise tebrik mesajı
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(height: 12),
          Text(
            'Tebrikler! 🎉',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bugünkü beslenmeniz gerçekten dengeli! Böyle devam edin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  bool _beslenmeGercektenDengeliMi() {
    // Kullanıcı ve günlük beslenme kontrolü
    if (kullanici == null || bugunBeslenme == null) return false;
    
    // Günlük kalori alımı kontrolü
    double alinanKalori = bugunBeslenme!.toplamKalori;
    double hedefKalori = kullanici!.gunlukKaloriHedefi;
    
    // ÖNCE KALORİ AŞIMI KONTROLÜ - aşım varsa asla dengeli değil!
    if (alinanKalori > hedefKalori + 100) return false;
    
    // En az %50 kalori alınmış olmalı
    if (alinanKalori < hedefKalori * 0.5) return false;
    
    // Makro besinlerin minimum seviyeleri
    double protein = bugunBeslenme!.toplamProtein;
    double karbonhidrat = bugunBeslenme!.toplamKarbonhidrat;
    double yag = bugunBeslenme!.toplamYag;
    
    // Minimum makro besin gereksinimleri
    bool proteinYeterli = protein >= (kullanici!.kilo * 0.8); // kg başına en az 0.8g protein
    bool karbonhidratYeterli = karbonhidrat >= (hedefKalori * 0.3 / 4); // Kalorilerin %30'u karbonhidrat
    bool yagYeterli = yag >= (hedefKalori * 0.2 / 9); // Kalorilerin %20'si yağ
    
    return proteinYeterli && karbonhidratYeterli && yagYeterli;
  }

  String _getBeslenmeEksiklikMesaji() {
    if (kullanici == null || bugunBeslenme == null) {
      return 'Henüz bugün için besin girişi yapmadınız. Yemek eklemeye başlayın!';
    }
    
    double alinanKalori = bugunBeslenme!.toplamKalori;
    double hedefKalori = kullanici!.gunlukKaloriHedefi;
    
    if (alinanKalori < hedefKalori * 0.25) {
      return 'Günlük kalori hedefinizin çok az bir kısmını aldınız. Daha fazla besin eklemelisiniz.';
    } else if (alinanKalori < hedefKalori * 0.5) {
      return 'Günlük kalori hedefinizin yarısına ulaşamadınız. Beslenme planınızı gözden geçirin.';
    } else {
      return 'Kalori hedefinin yarısından fazlasını aldınız ama makro besin dengeniz eksik. Protein, karbonhidrat ve yağ oranlarını kontrol edin.';
    }
  }

  Widget _buildSuOnayiKarti(bool isDark) {
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
                                        _buildSuOnerisi('Sabah', '2 bardak', 'Uyanır uyanmaz', isDark),
                _buildSuOnerisi('Öğün Arası', '1 bardak', 'Her öğün arası', isDark),
                _buildSuOnerisi('Egzersiz', '3 bardak', 'Spor öncesi/sonrası', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuOnerisi(String zaman, String miktar, String aciklama, bool isDark) {
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

  Widget _buildBaslikKarti(String baslik, IconData icon, Color renk, bool isDark) {
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

  Widget _buildEgzersizKategorileri(bool isDark) {
    // Kullanıcının kalori ve beslenme durumuna göre dinamik egzersiz önerileri
    final dinamikKategoriler = _getDinamikEgzersizKategorileri();

    return Column(
      children: dinamikKategoriler.map((kategori) => Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black54 : Colors.black).withOpacity(0.1),
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
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    kategori['ornekler'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    kategori['sebep'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: (kategori['renk'] as Color),
                      fontStyle: FontStyle.italic,
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

  List<Map<String, dynamic>> _getDinamikEgzersizKategorileri() {
    if (kullanici == null) return _getVarsayilanEgzersizKategorileri();

    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    final toplamKalori = bugunBeslenme?.toplamKalori ?? 0;
    final hedefKalori = kullanici!.gunlukKaloriHedefi;
    
    List<Map<String, dynamic>> kategoriler = [];

    // Kalori alımına göre egzersiz önerileri
    if (kalanKalori > 500) {
      // Çok fazla kalan kalori - yoğun egzersiz öner
      kategoriler.add({
        'isim': 'Yoğun Kardiyovasküler',
        'ornekler': 'HIIT, hızlı koşu, bisiklet',
        'sure': '45-60 dk',
        'icon': Icons.directions_run,
        'renk': Colors.red[700],
        'sebep': 'Fazla kalori yakmak için yoğun kardio öneriliyor',
      });
      
      kategoriler.add({
        'isim': 'Güç + Kardio Karışımı',
        'ornekler': 'Circuit training, crossfit',
        'sure': '40-50 dk',
        'icon': Icons.fitness_center,
        'renk': Colors.blue[700],
        'sebep': 'Kas geliştirip kalori yakmak için kombinasyon',
      });
    } else if (kalanKalori > 200) {
      // Orta düzey - normal egzersiz öner
      kategoriler.add({
        'isim': 'Orta Tempolu Kardio',
        'ornekler': 'Hızlı yürüyüş, hafif koşu, dans',
        'sure': '30-40 dk',
        'icon': Icons.directions_walk,
        'renk': Colors.orange[600],
        'sebep': 'Sağlıklı kalori yakımı için orta tempo',
      });
      
      kategoriler.add({
        'isim': 'Direnç Antrenmanı',
        'ornekler': 'Hafif ağırlık, vücut ağırlığı',
        'sure': '25-35 dk',
        'icon': Icons.fitness_center,
        'renk': Colors.blue[600],
        'sebep': 'Kas tonusunu korumak için',
      });
    } else if (kalanKalori > -200) {
      // Hedef yakın - hafif egzersiz öner
      kategoriler.add({
        'isim': 'Hafif Aktivite',
        'ornekler': 'Yürüyüş, stretching, yoga',
        'sure': '20-30 dk',
        'icon': Icons.self_improvement,
        'renk': Colors.green[600],
        'sebep': 'Kalori hedefine yakınsınız, hafif aktivite yeterli',
      });
    } else {
      // Fazla kalori alınmış - çok hafif öner
      kategoriler.add({
        'isim': 'Dinlendirici Egzersiz',
        'ornekler': 'Germe, nefes egzersizi, pilates',
        'sure': '15-20 dk',
        'icon': Icons.spa,
        'renk': Colors.purple[600],
        'sebep': 'Hedef kaloriyi aştınız, dinlendirici aktivite',
      });
    }

    // Makro besin dengesine göre ek öneriler
    if (beslenmeSkoru != null && beslenmeSkoru!['detaylar'] != null) {
      final detaylar = beslenmeSkoru!['detaylar'] as Map<String, dynamic>;
      final alinan = detaylar['alinan'] as Map<String, dynamic>?;
      final hedefler = detaylar['hedefler'] as Map<String, double>?;
      
      if (alinan != null && hedefler != null) {
        final proteinYeterli = (alinan['protein'] as double? ?? 0) >= (hedefler['protein'] ?? 0) * 0.8;
        
        if (!proteinYeterli) {
          kategoriler.add({
            'isim': 'Kas Koruyucu Egzersiz',
            'ornekler': 'Ağırlık kaldırma, resistance band',
            'sure': '20-30 dk',
            'icon': Icons.fitness_center,
            'renk': Colors.red[800],
            'sebep': 'Protein yetersiz, kas kaybını önlemek için güç antrenmanı',
          });
        }
      }
    }

    // En az 2 kategori olsun
    if (kategoriler.length < 2) {
      kategoriler.addAll(_getVarsayilanEgzersizKategorileri().take(2 - kategoriler.length));
    }

    return kategoriler;
  }

  List<Map<String, dynamic>> _getVarsayilanEgzersizKategorileri() {
    return [
      {
        'isim': 'Genel Kardiyovasküler',
        'ornekler': 'Yürüyüş, koşu, bisiklet',
        'sure': '30-45 dk',
        'icon': Icons.directions_run,
        'renk': Colors.red,
        'sebep': 'Genel sağlık için kardiyovasküler aktivite',
      },
      {
        'isim': 'Temel Güç Antrenmanı',
        'ornekler': 'Ağırlık, direnç bandı',
        'sure': '20-30 dk',
        'icon': Icons.fitness_center,
        'renk': Colors.blue,
        'sebep': 'Kas tonusu ve kemik sağlığı için',
      },
    ];
  }

  Widget _buildEgzersizProgrami(bool isDark) {
    final programDetaylari = _getDinamikEgzersizProgrami();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black54 : Colors.black).withOpacity(0.1),
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
              Icon(Icons.calendar_today, color: Colors.orange[800], size: 20),
              SizedBox(width: 8),
              Text(
                programDetaylari['baslik'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            programDetaylari['aciklama'] as String,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          
          ...(programDetaylari['gunler'] as List<Map<String, dynamic>>).map((gun) => 
            _buildGunProgrami(gun['gun'] as String, gun['tip'] as String, gun['detay'] as String, gun['renk'] as Color, isDark)
          ).toList(),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDinamikEgzersizProgrami() {
    if (kullanici == null) return _getVarsayilanProgram();

    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    final gunlukKaloriOrani = (bugunBeslenme?.toplamKalori ?? 0) / kullanici!.gunlukKaloriHedefi;

    if (kalanKalori > 500 || gunlukKaloriOrani < 0.7) {
      // Fazla kalori yakma programı
      return {
        'baslik': 'Yoğun Kalori Yakım Programı',
        'aciklama': 'Kalori açığınız fazla, yoğun egzersiz programı öneriliyor',
        'gunler': [
          {'gun': 'Pazartesi', 'tip': 'HIIT Kardio', 'detay': '45 dk yoğun interval', 'renk': Colors.red[700]},
          {'gun': 'Salı', 'tip': 'Güç Antrenmanı', 'detay': '40 dk üst vücut', 'renk': Colors.blue[700]},
          {'gun': 'Çarşamba', 'tip': 'Kardio', 'detay': '50 dk orta tempo', 'renk': Colors.orange[600]},
          {'gun': 'Perşembe', 'tip': 'Güç Antrenmanı', 'detay': '40 dk alt vücut', 'renk': Colors.blue[700]},
          {'gun': 'Cuma', 'tip': 'Mix Antrenman', 'detay': '45 dk kardio+güç', 'renk': Colors.purple[600]},
          {'gun': 'Cumartesi', 'tip': 'Uzun Kardio', 'detay': '60 dk düşük tempo', 'renk': Colors.green[600]},
        ],
      };
    } else if (kalanKalori > -200 && gunlukKaloriOrani > 0.8) {
      // Dengeli program
      return {
        'baslik': 'Dengeli Sağlık Programı',
        'aciklama': 'Kalori alımınız dengeli, genel sağlık odaklı program',
        'gunler': [
          {'gun': 'Pazartesi', 'tip': 'Kardio', 'detay': '35 dk orta tempo', 'renk': Colors.orange[600]},
          {'gun': 'Çarşamba', 'tip': 'Güç', 'detay': '30 dk tam vücut', 'renk': Colors.blue[600]},
          {'gun': 'Cuma', 'tip': 'Kardio', 'detay': '40 dk değişken tempo', 'renk': Colors.red[600]},
          {'gun': 'Pazar', 'tip': 'Esneklik', 'detay': '25 dk yoga/pilates', 'renk': Colors.purple[600]},
        ],
      };
    } else {
      // Hafif program
      return {
        'baslik': '⚠️ ACİL Kalori Yakma Programı',
        'aciklama': 'ZARARI! Kalori fazlası var - hemen yoğun egzersiz gerekli',
                  'gunler': [
            {'gun': 'Pazartesi', 'tip': 'KOŞU', 'detay': '45 dk hızlı koşu - ŞART', 'renk': Colors.red[700]},
            {'gun': 'Çarşamba', 'tip': 'KARDIO', 'detay': '60 dk yoğun kardio', 'renk': Colors.red[600]},
            {'gun': 'Cuma', 'tip': 'BİSİKLET', 'detay': '50 dk tempolu bisiklet', 'renk': Colors.orange[600]},
            {'gun': 'Pazar', 'tip': 'YÜRÜYÜş', 'detay': '90 dk hızlı yürüyüş', 'renk': Colors.red[500]},
          ],
      };
    }
  }

  Map<String, dynamic> _getVarsayilanProgram() {
    return {
      'baslik': 'Temel Haftalık Program',
      'aciklama': 'Genel sağlık için önerilen temel program',
      'gunler': [
        {'gun': 'Pazartesi', 'tip': 'Kardio', 'detay': '30 dk yürüyüş', 'renk': Colors.red},
        {'gun': 'Çarşamba', 'tip': 'Güç', 'detay': '20 dk ağırlık', 'renk': Colors.blue},
        {'gun': 'Cuma', 'tip': 'Kardio', 'detay': '40 dk koşu', 'renk': Colors.red},
        {'gun': 'Pazar', 'tip': 'Esneklik', 'detay': '30 dk yoga', 'renk': Colors.purple},
      ],
    };
  }

  Widget _buildAktiviteHedefleri(bool isDark) {
    final dinamikHedefler = _getDinamikAktiviteHedefleri();
    
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
            dinamikHedefler['baslik'] as String,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            dinamikHedefler['aciklama'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: (dinamikHedefler['hedefler'] as List<Map<String, String>>).map((hedef) =>
              _buildAktiviteHedefi(hedef['sayi']!, hedef['aciklama']!, isDark)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDinamikAktiviteHedefleri() {
    if (kullanici == null) return _getVarsayilanAktiviteHedefleri();

    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    
    if (kalanKalori > 500) {
      return {
        'baslik': 'Yoğun Aktivite Hedefleri',
        'aciklama': 'Fazla kalori yakmak için yüksek hedefler',
        'hedefler': [
          {'sayi': '12.000+', 'aciklama': 'Günlük\nAdım'},
          {'sayi': '200 dk', 'aciklama': 'Haftalık\nKardio'},
          {'sayi': '3x', 'aciklama': 'Haftalık\nGüç'},
        ],
      };
    } else if (kalanKalori > -200) {
      return {
        'baslik': 'Dengeli Aktivite Hedefleri',
        'aciklama': 'Sağlıklı yaşam için optimal hedefler',
        'hedefler': [
          {'sayi': '10.000', 'aciklama': 'Günlük\nAdım'},
          {'sayi': '150 dk', 'aciklama': 'Haftalık\nKardio'},
          {'sayi': '2x', 'aciklama': 'Haftalık\nGüç'},
        ],
      };
    } else {
      return {
        'baslik': '🚨 Kalori Yakma Hedefleri',
        'aciklama': 'TEHLİKE! Fazla kaloriyi yakmanız şart - aktif olun',
                  'hedefler': [
            {'sayi': '15.000+', 'aciklama': 'Günlük\nAdım'},
            {'sayi': '300 dk', 'aciklama': 'Haftalık\nYoğun'},
            {'sayi': '5x', 'aciklama': 'Haftalık\nEgzersiz'},
          ],
      };
    }
  }

  Map<String, dynamic> _getVarsayilanAktiviteHedefleri() {
    return {
      'baslik': 'Temel Aktivite Hedefleri',
      'aciklama': 'Genel sağlık için önerilen hedefler',
      'hedefler': [
        {'sayi': '10.000', 'aciklama': 'Günlük\nAdım'},
        {'sayi': '150 dk', 'aciklama': 'Haftalık\nKardio'},
        {'sayi': '2x', 'aciklama': 'Haftalık\nGüç'},
      ],
    };
  }

  Widget _buildGunProgrami(String gun, String tip, String detay, Color renk, bool isDark) {
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
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Text(
            '$tip - $detay',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAktiviteHedefi(String sayi, String aciklama, bool isDark) {
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

  Widget _buildUykuOnerileri(bool isDark) {
    final dinamikUykuOnerileri = _getDinamikUykuOnerileri();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black54 : Colors.black).withOpacity(isDark ? 0.3 : 0.05),
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
                dinamikUykuOnerileri['baslik'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.purple[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            dinamikUykuOnerileri['aciklama'] as String,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          
          ...(dinamikUykuOnerileri['oneriler'] as List<Map<String, String>>).map((oneri) =>
            _buildUykuOnerisi(oneri['baslik']!, oneri['aciklama']!, isDark)
          ).toList(),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDinamikUykuOnerileri() {
    if (kullanici == null) return _getVarsayilanUykuOnerileri();

    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    final gunlukKaloriOrani = (bugunBeslenme?.toplamKalori ?? 0) / kullanici!.gunlukKaloriHedefi;

    if (kalanKalori > 500) {
      // Yoğun egzersiz yapacaksa daha fazla uyku
      return {
        'baslik': 'Yoğun Aktivite İçin Uyku Önerileri',
        'aciklama': 'Fazla kalori yakacağınız için kas onarımı ve enerji için daha fazla uyku gerekli',
        'oneriler': [
          {'baslik': '8-9 saat derin uyku', 'aciklama': 'Yoğun egzersiz sonrası kas onarımı için'},
          {'baslik': 'Erken yatış (22:00-23:00)', 'aciklama': 'Sabah erken egzersiz için hazırlık'},
          {'baslik': 'Yatak odası 18-20°C', 'aciklama': 'Derin uyku için ideal sıcaklık'},
          {'baslik': 'Yatmadan 2 saat önce yemek yok', 'aciklama': 'Sindirim uyku kalitesini etkilemesin'},
          {'baslik': 'Öğle uykusu max 20 dk', 'aciklama': 'Gece uykusunu bozmaması için'},
        ],
      };
    } else if (kalanKalori < -200) {
      // Fazla kalori aldıysa stres azaltıcı uyku
      return {
        'baslik': 'Stres Azaltıcı Uyku Önerileri',
        'aciklama': 'Fazla kalori aldığınız günlerde stres hormonu dengesi için kaliteli uyku',
        'oneriler': [
          {'baslik': '7-8 saat düzenli uyku', 'aciklama': 'Hormon dengesini sağlamak için'},
          {'baslik': 'Aynı saatte yat/kalk', 'aciklama': 'Metabolizma düzeni için'},
          {'baslik': 'Gevşeme teknikleri', 'aciklama': 'Meditasyon, nefes egzersizi'},
          {'baslik': 'Yatmadan önce çay içmeyin', 'aciklama': 'Kafein uyku kalitesini düşürür'},
          {'baslik': 'Telefon/tablet yasağı', 'aciklama': 'Yatmadan 1 saat önce'},
        ],
      };
    } else {
      // Normal durumda dengeli uyku
      return {
        'baslik': 'Dengeli Yaşam İçin Uyku Önerileri',
        'aciklama': 'Kalori dengeniz normal, genel sağlık için optimal uyku rutini',
        'oneriler': [
          {'baslik': '7-8 saat kaliteli uyku', 'aciklama': 'Genel sağlık için ideal süre'},
          {'baslik': 'Düzenli uyku rutini', 'aciklama': 'Her gün aynı saatlerde yat/kalk'},
          {'baslik': 'Karanlık ve sessiz ortam', 'aciklama': 'Kaliteli uyku için gerekli'},
          {'baslik': 'Hafta sonu düzeni bozma', 'aciklama': 'Biyoritmi korumak için'},
        ],
      };
    }
  }

  Map<String, dynamic> _getVarsayilanUykuOnerileri() {
    return {
      'baslik': 'Temel Uyku Önerileri',
      'aciklama': 'Genel sağlık için temel uyku rehberi',
      'oneriler': [
        {'baslik': '7-9 saat uyku', 'aciklama': 'Yetişkinler için ideal uyku süresi'},
        {'baslik': 'Düzenli uyku saatleri', 'aciklama': 'Her gün aynı saatte yatıp kalkın'},
        {'baslik': 'Yatak odası ortamı', 'aciklama': 'Karanlık, sessiz ve serin olsun'},
        {'baslik': 'Yatmadan önce', 'aciklama': '1 saat öncesinden ekran kullanımını azaltın'},
      ],
    };
  }

  Widget _buildUykuOnerisi(String baslik, String aciklama, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.purple[900]!.withOpacity(0.3) : Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.purple[300]! : Colors.purple[200]!,
        ),
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
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  aciklama,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStresYonetimiOnerileri(bool isDark) {
    final dinamikStresOnerileri = _getDinamikStresOnerileri();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black54 : Colors.black).withOpacity(isDark ? 0.3 : 0.05),
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
                dinamikStresOnerileri['baslik'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            dinamikStresOnerileri['aciklama'] as String,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStresKarti(
                  dinamikStresOnerileri['kart1']['baslik'] as String,
                  dinamikStresOnerileri['kart1']['aciklama'] as String,
                  dinamikStresOnerileri['kart1']['icon'] as IconData,
                  dinamikStresOnerileri['kart1']['renk'] as Color,
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStresKarti(
                  dinamikStresOnerileri['kart2']['baslik'] as String,
                  dinamikStresOnerileri['kart2']['aciklama'] as String,
                  dinamikStresOnerileri['kart2']['icon'] as IconData,
                  dinamikStresOnerileri['kart2']['renk'] as Color,
                  isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStresKarti(
                  dinamikStresOnerileri['kart3']['baslik'] as String,
                  dinamikStresOnerileri['kart3']['aciklama'] as String,
                  dinamikStresOnerileri['kart3']['icon'] as IconData,
                  dinamikStresOnerileri['kart3']['renk'] as Color,
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStresKarti(
                  dinamikStresOnerileri['kart4']['baslik'] as String,
                  dinamikStresOnerileri['kart4']['aciklama'] as String,
                  dinamikStresOnerileri['kart4']['icon'] as IconData,
                  dinamikStresOnerileri['kart4']['renk'] as Color,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDinamikStresOnerileri() {
    if (kullanici == null) return _getVarsayilanStresOnerileri();

    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    final gunlukKaloriOrani = (bugunBeslenme?.toplamKalori ?? 0) / kullanici!.gunlukKaloriHedefi;

    if (kalanKalori < -300) {
      // FAZLA YEMİŞ - ACİL MÜDAHALE GEREKİR
      return {
        'baslik': '🚨 ACİL Kalori Aşımı Müdahalesi',
        'aciklama': 'ZARARI durum! Hemen harekete geçin - fazla kaloriyı yakmanız şart',
        'kart1': {'baslik': 'ACİL Egzersiz', 'aciklama': 'En az 60 dk koşu/bisiklet', 'icon': Icons.directions_run, 'renk': Colors.red},
        'kart2': {'baslik': 'Yoğun Aktivite', 'aciklama': 'Merdiven çık/in, tempolu yürü', 'icon': Icons.fitness_center, 'renk': Colors.orange},
        'kart3': {'baslik': 'Yarın Açık', 'aciklama': 'Kalori açığı yarat mutlaka', 'icon': Icons.trending_down, 'renk': Colors.blue},
        'kart4': {'baslik': 'Kontrolü Al', 'aciklama': 'Bu ciddi bir sağlık riski', 'icon': Icons.warning, 'renk': Colors.red[900]!},
      };
    } else if (kalanKalori > 400) {
      // Az yemiş, açlık stresi
      return {
        'baslik': 'Açlık Stresi Yönetimi',
        'aciklama': 'Yetersiz beslenme stres hormonu artırır, dengeyi sağlayın',
        'kart1': {'baslik': 'Sakin Nefes Al', 'aciklama': '4-7-8 tekniği', 'icon': Icons.air, 'renk': Colors.blue},
        'kart2': {'baslik': 'Sağlıklı Atıştır', 'aciklama': 'Kuruyemiş, meyve', 'icon': Icons.apple, 'renk': Colors.green},
        'kart3': {'baslik': 'Su İç', 'aciklama': 'Dehidrasyon stres artırır', 'icon': Icons.local_drink, 'renk': Colors.cyan},
        'kart4': {'baslik': 'Müzik Dinle', 'aciklama': 'Sakinleştirici müzik', 'icon': Icons.music_note, 'renk': Colors.purple},
      };
    } else {
      // Normal durum
      return {
        'baslik': 'Günlük Stres Yönetimi',
        'aciklama': 'Beslenme dengeniz iyi, genel stres yönetimi teknikleri',
        'kart1': {'baslik': 'Derin Nefes', 'aciklama': '5 dk nefes egzersizi', 'icon': Icons.air, 'renk': Colors.blue},
        'kart2': {'baslik': 'Kısa Meditasyon', 'aciklama': '10 dk farkındalık', 'icon': Icons.self_improvement, 'renk': Colors.purple},
        'kart3': {'baslik': 'Doğa İle Bağlan', 'aciklama': 'Bahçe, park, balkon', 'icon': Icons.nature_people, 'renk': Colors.green},
        'kart4': {'baslik': 'Sosyal Destek', 'aciklama': 'Sevdiğinle konuş', 'icon': Icons.people, 'renk': Colors.orange},
      };
    }
  }

  Map<String, dynamic> _getVarsayilanStresOnerileri() {
    return {
      'baslik': 'Temel Stres Yönetimi',
      'aciklama': 'Günlük yaşamda stres yönetimi için temel teknikler',
      'kart1': {'baslik': 'Nefes Egzersizi', 'aciklama': '4-7-8 tekniği', 'icon': Icons.air, 'renk': Colors.blue},
      'kart2': {'baslik': 'Meditasyon', 'aciklama': '10 dk günlük', 'icon': Icons.self_improvement, 'renk': Colors.purple},
      'kart3': {'baslik': 'Doğa Yürüyüşü', 'aciklama': 'Haftada 2-3 kez', 'icon': Icons.nature_people, 'renk': Colors.green},
      'kart4': {'baslik': 'Sosyal Aktivite', 'aciklama': 'Arkadaşlarla zaman', 'icon': Icons.people, 'renk': Colors.orange},
    };
  }

  Widget _buildStresKarti(String baslik, String aciklama, IconData icon, Color renk, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? renk.withOpacity(0.2) : renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? renk.withOpacity(0.5) : renk.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 24),
          SizedBox(height: 8),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            aciklama,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaglikliAliskanliklar(bool isDark) {
    final dinamikAliskanliklar = _getDinamikSaglikliAliskanliklar();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black54 : Colors.black).withOpacity(0.1),
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
              Icon(Icons.favorite, color: Colors.red[600], size: 24),
              SizedBox(width: 12),
              Text(
                dinamikAliskanliklar['baslik'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.red[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            dinamikAliskanliklar['aciklama'] as String,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          
          ...(dinamikAliskanliklar['aliskanliklar'] as List<String>).asMap().entries.map((entry) {
            final index = entry.key;
            final aliskanlik = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.red[600]!.withOpacity(0.2) 
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: isDark 
                    ? Border.all(color: Colors.red[600]!.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red[600],
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
                        color: isDark ? Colors.white : Colors.black87,
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

  Map<String, dynamic> _getDinamikSaglikliAliskanliklar() {
    if (kullanici == null) return _getVarsayilanAliskanliklar();

    final kalanKalori = kullanici!.gunlukKaloriHedefi - (bugunBeslenme?.toplamKalori ?? 0);
    final gunlukKaloriOrani = (bugunBeslenme?.toplamKalori ?? 0) / kullanici!.gunlukKaloriHedefi;

    if (kalanKalori > 500) {
      // Fazla kalori yakması gereken kişi
      return {
        'baslik': 'Yoğun Yaşam Tarzı Alışkanlıkları',
        'aciklama': 'Aktif kalori yakımı için güçlü alışkanlıklar',
        'aliskanliklar': [
          'Günde en az 12.000 adım atmaya çalışın - fazla kalori yakmak için',
          'Her öğün öncesi 10 dk yürüyüş yapın - metabolizmayı hızlandırır',
          'Merdiven çıkmayı tercih edin - günlük aktiviteyi artırır',
          'İşlenmiş gıdalardan tamamen kaçının - boş kalori almayın',
          'Bol proteinli besinler tüketin - kas kaybını önler',
          'Sabah erken kalkıp egzersiz yapın - gün boyu metabolizma yüksek',
          'Ara öğünlerde kuruyemiş tercih edin - sağlıklı yağlar için',
        ],
      };
    } else if (kalanKalori < -300) {
      // Fazla kalori almış kişi
      return {
        'baslik': 'Dengeyi Sağlayıcı Alışkanlıklar',
        'aciklama': 'Fazla kalori aldığınızda dengeyi tekrar kurmak için',
        'aliskanliklar': [
          'Yarın normal porsiyonlara dönün - uzun vadeli düşünün',
          'Fazla su için - toksik maddeleri atın',
          'Hafif yürüyüş yapın - sindirime yardımcı olur',
          'Stresli yemek yemeyi durdurun - farkındalık geliştirin',
          'Sebze ağırlıklı bir sonraki öğün planlayın',
          'Kendinizi suçlamayın - pozitif iç diyalog kurun',
          'Uyku düzeninizi koruyun - hormon dengesini sağlar',
        ],
      };
    } else {
      // Normal dengeli durum
      return {
        'baslik': 'Dengeli Yaşam Alışkanlıkları',
        'aciklama': 'Sağlıklı dengeyi korumak için sürdürülebilir alışkanlıklar',
        'aliskanliklar': [
          'Günde 10.000 adım atmaya çalışın - genel sağlık için',
          'Günde 5 porsiyon meyve ve sebze tüketin',
          'Haftada 2-3 kez balık yiyin - omega-3 için',
          'Düzenli kan değerlerinizi kontrol ettirin',
          'Sosyal bağlantılarınızı güçlü tutun - mental sağlık',
          'Günlük güneş ışığından D vitamini alın',
          'Mindful eating yapın - yavaş ve bilinçli yiyin',
        ],
      };
    }
  }

  Map<String, dynamic> _getVarsayilanAliskanliklar() {
    return {
      'baslik': 'Temel Sağlıklı Alışkanlıklar',
      'aciklama': 'Genel sağlık için temel yaşam tarzı önerileri',
      'aliskanliklar': [
        'Her gün en az 10.000 adım atmaya çalışın',
        'Günde 5 porsiyon meyve ve sebze tüketin',
        'İşlenmiş gıdaları minimuma indirin',
        'Düzenli olarak kan değerlerinizi kontrol ettirin',
        'Günlük güneş ışığından D vitamini alın',
        'Sosyal bağlantılarınızı güçlü tutun',
      ],
    };
  }

  // ======== GÜVENLİ SAFE METODLAR ========
  
  Widget _buildKisiselDurumKartiSafe(bool isDark) {
    try {
      return _buildKisiselDurumKarti(isDark);
    } catch (e) {
      print('❌ Kişisel durum kartı hatası: $e');
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2D2D2D) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Analiz verisi hazırlanıyor...',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildOgunOnerileriSafe(double kalanKalori, bool isDark) {
    try {
      return _buildOgunOnerileri(kalanKalori, isDark);
    } catch (e) {
      print('❌ Öğün önerileri hatası: $e');
      return _buildBasitOgunOnerisi(kalanKalori, isDark);
    }
  }

  Widget _buildBasitOgunOnerisi(double kalanKalori, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Öğün Önerileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            kalanKalori > 0 
              ? 'Günlük ${kalanKalori.toInt()} kcal daha alabilirsiniz'
              : 'Günlük kalori hedefinizi aştınız',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitaminMineralOnerileriSafe(bool isDark) {
    try {
      return _buildVitaminMineralOnerileri(isDark);
    } catch (e) {
      print('❌ Vitamin mineral önerileri hatası: $e');
      return _buildBasitVitaminOnerisi(isDark);
    }
  }

  Widget _buildBasitVitaminOnerisi(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vitamin & Mineral Önerileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Dengeli beslenme için günlük vitamin ve mineral ihtiyaçlarınızı karşılamaya odaklanın.',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuOnayiKartiSafe(bool isDark) {
    try {
      return _buildSuOnayiKarti(isDark);
    } catch (e) {
      print('❌ Su öneri kartı hatası: $e');
      return _buildBasitSuOnerisi(isDark);
    }
  }

  Widget _buildBasitSuOnerisi(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Su Önerisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Günde en az 2-3 litre su içmeye özen gösterin.',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaslikKartiSafe(String baslik, IconData icon, Color renk, bool isDark) {
    try {
      return _buildBaslikKarti(baslik, icon, renk, isDark);
    } catch (e) {
      print('❌ Başlık kartı hatası: $e');
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: renk, size: 24),
            SizedBox(width: 12),
            Text(
              baslik,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEgzersizKategorileriSafe(bool isDark) {
    try {
      return _buildEgzersizKategorileri(isDark);
    } catch (e) {
      return _buildBasitEgzersizOnerisi(isDark);
    }
  }

  Widget _buildBasitEgzersizOnerisi(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Günlük 30 dakika yürüyüş yapın.',
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildEgzersizProgramiSafe(bool isDark) {
    try {
      return _buildEgzersizProgrami(isDark);
    } catch (e) {
      return Container();
    }
  }

  Widget _buildAktiviteHedefleriSafe(bool isDark) {
    try {
      return _buildAktiviteHedefleri(isDark);
    } catch (e) {
      return Container();
    }
  }

  Widget _buildUykuOnerileriSafe(bool isDark) {
    try {
      return _buildUykuOnerileri(isDark);
    } catch (e) {
      return Container();
    }
  }

  Widget _buildStresYonetimiOnerileriSafe(bool isDark) {
    try {
      return _buildStresYonetimiOnerileri(isDark);
    } catch (e) {
      return Container();
    }
  }

  Widget _buildSaglikliAliskanliklarSafe(bool isDark) {
    try {
      return _buildSaglikliAliskanliklar(isDark);
    } catch (e) {
      return Container();
    }
  }
}