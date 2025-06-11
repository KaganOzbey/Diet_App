import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../modeller/kullanici_modeli.dart';
import '../modeller/yemek_ogesi_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../veriler/mega_besin_veritabani.dart';

import '../servisler/tema_servisi.dart';
import 'istatistikler_ekrani.dart';
import 'profil_yonetimi_ekrani.dart';
import 'giris_ekrani.dart';

class AnaEkran extends StatefulWidget {
  final double bmr;

  const AnaEkran({Key? key, required this.bmr}) : super(key: key);

  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> with TickerProviderStateMixin {
  late TabController _tabController;
  KullaniciModeli? currentUser;
  GunlukBeslenmeModeli? todayNutrition;
  List<OgunGirisiModeli> todayMeals = [];
  
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String selectedMealType = "Kahvaltı";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('Ana ekran: Kullanıcı verileri yükleniyor...');
      
      // Önce demo kullanıcısını kontrol et
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        print('Ana ekran: Demo kullanıcısı bulundu: ${demoKullanici.email}');
        print('Ana ekran: Demo kullanıcı ID: ${demoKullanici.id}');
        setState(() {
          currentUser = demoKullanici;
        });
        _loadTodayData();
        return;
      }
      
      // Sonra yerel veritabanından kontrol et
      final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (kullanici != null) {
        print('Ana ekran: Yerel kullanıcı bulundu: ${kullanici.email}');
        print('Ana ekran: Yerel kullanıcı ID: ${kullanici.id}');
        setState(() {
          currentUser = kullanici;
        });
        _loadTodayData();
        return;
      }
      
      print('Ana ekran: Hiçbir kullanıcı bulunamadı');
    } catch (e) {
      print('Kullanıcı veri yükleme hatası: $e');
    }
  }

  void _loadTodayData() {
    if (currentUser == null) {
      print('Ana ekran: currentUser null, veri yüklenemiyor');
      return;
    }
    
    print('Ana ekran: Bugünkü veriler yükleniyor - Kullanıcı ID: ${currentUser!.id}');
    final bugun = DateTime.now();
    
    final ogunGirisleri = VeriTabaniServisi.gunlukOgunGirisleriniGetir(currentUser!.id, bugun);
    final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(currentUser!.id, bugun);
    
    print('Ana ekran: Bugün için ${ogunGirisleri.length} öğün girişi bulundu');
    print('Ana ekran: Günlük beslenme verisi: ${gunlukBeslenme?.toplamKalori ?? 0} kalori');
    
    if (ogunGirisleri.isNotEmpty) {
      for (int i = 0; i < ogunGirisleri.length; i++) {
        final ogun = ogunGirisleri[i];
        print('Ana ekran: Öğün $i - ${ogun.yemekIsmi}: ${ogun.kalori.toStringAsFixed(1)} kcal, ${ogun.tuketilenGram.toStringAsFixed(1)}g');
      }
    }
    
    setState(() {
      todayMeals = ogunGirisleri;
      todayNutrition = gunlukBeslenme;
    });
    
    print('Ana ekran: setState çağrıldı - UI güncellenecek');
  }

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      // Kapsamlı besin veritabanından ara
      final kapsamliBesinler = MegaBesinVeritabani.besinAra(query);
      
      // Bulunan besinleri veritabanına ekle
      for (final besinAdi in kapsamliBesinler) {
        final besinDegerleri = MegaBesinVeritabani.tumBesinler[besinAdi];
        
        // Zaten veritabanında var mı kontrol et
        final mevcutBesin = VeriTabaniServisi.fdcIdIleYemekOgesiBul(besinAdi.hashCode);
        if (mevcutBesin == null && besinDegerleri != null) {
          try {
            await VeriTabaniServisi.yemekOgesiKaydet(
              isim: besinAdi.substring(0, 1).toUpperCase() + besinAdi.substring(1),
              fdcId: besinAdi.hashCode,
              yuzGramKalori: besinDegerleri['k']!.toDouble(),
              yuzGramProtein: besinDegerleri['p']!.toDouble(),
              yuzGramKarbonhidrat: besinDegerleri['c']!.toDouble(),
              yuzGramYag: besinDegerleri['y']!.toDouble(),
              yuzGramLif: besinDegerleri['l']?.toDouble() ?? 0.0,
              kategori: 'Türk Mutfağı',
            );
          } catch (e) {
            // Hata varsa devam et
          }
        }
      }
      
      // Güncellenmiş sonuçları getir
      final guncelSonuclar = VeriTabaniServisi.isimIleYemekAra(query);
      setState(() {
        searchResults = guncelSonuclar;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama hatası: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addMealEntry(dynamic foodData) async {
    if (currentUser == null) {
      print('Ana ekran: currentUser null, yemek eklenemiyor');
      return;
    }

    final yemekOgesi = foodData as YemekOgesiModeli;
    print('Ana ekran: Yemek ekleme başlıyor - ${yemekOgesi.isim}');
    
    // Besin veritabanından ölçü bilgisini al
    final besinVerisi = MegaBesinVeritabani.tumBesinler[yemekOgesi.isim.toLowerCase()];
    String varsayilanOlcu = besinVerisi?['o'] ?? 'gram';
    int gramKarsiligi = besinVerisi?['g'] ?? 100;
    
    final miktarController = TextEditingController(text: '1');
    String secilenOlcu = varsayilanOlcu;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Miktar Belirle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                yemekOgesi.isim,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              // Miktar ve ölçü seçimi
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: miktarController,
                      decoration: InputDecoration(
                        labelText: 'Miktar',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: secilenOlcu,
                      decoration: InputDecoration(
                        labelText: 'Ölçü',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'gram',
                        'fincan',
                        'bardak',
                        'adet',
                        'dilim',
                        'porsiyon',
                        'y.kaşığı',
                        't.kaşığı',
                        'avuç',
                        'kase',
                        'parça',
                        'top',
                        'kare',
                        'demet',
                        'yaprak',
                        'diş',
                        'yarım'
                      ].map((olcu) => DropdownMenuItem(
                            value: olcu,
                            child: Text(_olcuAdiCevir(olcu)),
                          ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => secilenOlcu = value!),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Varsayılan ölçü bilgisi
              Text(
                'Varsayılan: 1 ${_olcuAdiCevir(varsayilanOlcu)} = ${gramKarsiligi}g',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              
              SizedBox(height: 16),
              
              // Öğün tipi seçimi
              DropdownButton<String>(
                value: selectedMealType,
                isExpanded: true,
                items: ['Kahvaltı', 'Ara Öğün', 'Öğle Yemeği', 'Akşam Yemeği']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setDialogState(() => selectedMealType = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      print('Ana ekran: Yemek ekleme iptal edildi');
      return;
    }

    try {
      final miktar = double.tryParse(miktarController.text) ?? 1.0;
      print('Ana ekran: Miktar: $miktar ${secilenOlcu}');
      
      // Ölçü birimini gram'a çevir
      double gramMiktari = _olcuBirimiGramaCevir(yemekOgesi.isim, miktar, secilenOlcu);
      print('Ana ekran: Gram miktarı: ${gramMiktari}g');
      
      print('Ana ekran: Veritabanına kayıt işlemi başlıyor...');
      
      final eklenenOgun = await VeriTabaniServisi.ogunGirisiEkle(
        kullaniciId: currentUser!.id,
        yemekOgesi: yemekOgesi,
        gramMiktari: gramMiktari,
        ogunTipi: selectedMealType,
      );
      
      print('Ana ekran: Öğün başarıyla eklendi - ID: ${eklenenOgun.id}');
      print('Ana ekran: Eklenen kalori: ${eklenenOgun.kalori.toStringAsFixed(1)} kcal');

      print('Ana ekran: UI verileri yeniden yükleniyor...');
      _loadTodayData();
      
      _searchController.clear();
      setState(() => searchResults = []);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${yemekOgesi.isim} eklendi! (${eklenenOgun.kalori.toStringAsFixed(1)} kcal)'),
          backgroundColor: Colors.green,
        ),
      );
      
      print('Ana ekran: Yemek ekleme işlemi tamamlandı');
    } catch (e) {
      print('Ana ekran: Yemek ekleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ekleme hatası: $e')),
      );
    }
  }

  // Ölçü adını Türkçeye çevir
  String _olcuAdiCevir(String olcu) {
    final ceviri = {
      'gram': 'gram',
      'fincan': 'fincan',
      'bardak': 'bardak',
      'adet': 'adet',
      'dilim': 'dilim',
      'porsiyon': 'porsiyon',
      'y.kaşığı': 'yemek kaşığı',
      't.kaşığı': 'tatlı kaşığı',
      'avuç': 'avuç',
      'kase': 'kase',
      'parça': 'parça',
      'top': 'top',
      'kare': 'kare',
      'demet': 'demet',
      'yaprak': 'yaprak',
      'diş': 'diş',
      'yarım': 'yarım',
    };
    return ceviri[olcu] ?? olcu;
  }

  // Ölçü birimini gram'a çevir
  double _olcuBirimiGramaCevir(String besinAdi, double miktar, String olcu) {
            final besinVerisi = MegaBesinVeritabani.tumBesinler[besinAdi.toLowerCase()];
    if (besinVerisi == null) return miktar * 100; // Varsayılan
    
    final varsayilanOlcu = besinVerisi['o'] as String;
    final gramKarsiligi = besinVerisi['g'] as int;
    
    // Eğer seçilen ölçü varsayılan ölçü ile aynıysa
    if (olcu == varsayilanOlcu) {
      return miktar * gramKarsiligi;
    }
    
    // Farklı ölçü birimleri için yaklaşık değerler
    switch (olcu) {
      case 'gram':
        return miktar;
      case 'fincan':
        return miktar * 125; // Ortalama fincan
      case 'bardak':
        return miktar * 200; // Ortalama bardak
      case 'y.kaşığı':
        return miktar * 15; // Yemek kaşığı
      case 't.kaşığı':
        return miktar * 5; // Tatlı kaşığı
      case 'adet':
        return miktar * gramKarsiligi; // Varsayılan ölçüye göre
      case 'dilim':
        return miktar * 25; // Ortalama dilim
      case 'porsiyon':
        return miktar * 150; // Ortalama porsiyon
      case 'avuç':
        return miktar * 30; // Ortalama avuç
      case 'kase':
        return miktar * 200; // Ortalama kase
      case 'parça':
        return miktar * gramKarsiligi; // Varsayılan ölçüye göre
      default:
        return miktar * gramKarsiligi;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        return Scaffold(
          backgroundColor: temaServisi.isDarkMode ? Color(0xFF1A1A1A) : null,
          appBar: AppBar(
        title: Text('Beslenme Takibi'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.add_circle), text: 'Yemek Ekle'),
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.recommend), text: 'Öneriler'),
          ],
        ),
        actions: [
          // Dropdown menü butonu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            tooltip: 'Daha Fazla Seçenek',
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilYonetimiEkrani()),
                  );
                  break;
                case 'stats':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => IstatistiklerEkrani()),
                  );
                  break;
                case 'logout':
                  _cikisYap();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Profil Yönetimi'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stats', 
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('İstatistikler'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFoodSearchTab(temaServisi),
              _buildDashboardTab(temaServisi),
              _buildRecommendationsTab(temaServisi),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodSearchTab(TemaServisi temaServisi) {
    return Container(
      color: temaServisi.isDarkMode ? Color(0xFF1A1A1A) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
          // Arama çubuğu
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Yemek ara... (çay, kıyma, çiğ köfte)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _searchFood,
            enableSuggestions: true,
            autocorrect: true,
            textInputAction: TextInputAction.search,
          ),
          
          SizedBox(height: 16),
          
          // Arama sonuçları
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                    ? _buildEmptySearchState()
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final food = searchResults[index];
                          return _buildFoodListItem(food);
                        },
                      ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEmptySearchState() {
    final populerBesinler = [
      'yumurta', 'tavuk göğsü', 'pirinç', 'ekmek', 'süt',
      'peynir', 'elma', 'muz', 'domates', 'salatalık'
    ];
    
    return Column(
      children: [
        SizedBox(height: 40),
        Icon(Icons.search, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Yemek aramaya başlayın',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
        SizedBox(height: 8),
        Text(
          'Besin değerlerini görmek için yemek adını yazın',
          style: TextStyle(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Text(
          'Popüler Besinler:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: populerBesinler.length,
            itemBuilder: (context, index) {
              final besin = populerBesinler[index];
              return Card(
                child: InkWell(
                  onTap: () {
                    _searchController.text = besin;
                    _searchFood(besin);
                  },
                  child: Center(
                    child: Text(
                      besin.substring(0, 1).toUpperCase() + besin.substring(1),
                      style: TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoodListItem(dynamic food) {
                  final yemekOgesi = food as YemekOgesiModeli;
    final isim = yemekOgesi.isim;
    final kalori = yemekOgesi.yuzGramKalori;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(
            yemekOgesi.favoriMi ? Icons.favorite : Icons.restaurant,
            color: Colors.green,
          ),
        ),
        title: Text(
          isim,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${kalori.toStringAsFixed(0)} kcal / 100g'),
        trailing: IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _addMealEntry(yemekOgesi),
        ),
      ),
    );
  }

  Widget _buildDashboardTab(TemaServisi temaServisi) {
    // Kullanıcı kartını her zaman göster (kullanıcı verisi olmasa bile)
    return Container(
      color: temaServisi.isDarkMode ? Color(0xFF1A1A1A) : null,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Kullanıcı bilgi kartı (üstte) - Her zaman göster
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green[600],
                    child: Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba, ${currentUser?.isim ?? "Kullanıcı"}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now())}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Aktif Kullanıcı',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Dark Mode Toggle butonu
                  Consumer<TemaServisi>(
                    builder: (context, temaServisi, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: temaServisi.isDarkMode ? Colors.amber[600] : Colors.grey[700],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (temaServisi.isDarkMode ? Colors.amber : Colors.grey).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            temaServisi.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white,
                            size: 26,
                          ),
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
                          tooltip: temaServisi.isDarkMode ? 'Açık Tema' : 'Koyu Tema',
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  // Profil Yönetimi butonu - daha büyük ve dikkat çekici
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.settings, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilYonetimiEkrani()),
                        );
                      },
                      tooltip: 'Profil Yönetimi',
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8),

          // Kullanıcı verisi yok ise uyarı göster
          if (currentUser == null)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Kullanıcı verileri yükleniyor...'),
                    ],
                  ),
                ),
              ),
            ),



          // Kalori ve diğer veriler - Sadece kullanıcı verisi varken göster
          if (currentUser != null) ...[
            // Kalori özeti - Sadece kullanıcı verisi varken göster
            Builder(
              builder: (context) {
                final kaloriHedefi = currentUser!.gunlukKaloriHedefi;
                final tuketilenKalori = todayNutrition?.toplamKalori ?? 0;
                final kalanKalori = kaloriHedefi - tuketilenKalori;
                final ilerleme = (tuketilenKalori / kaloriHedefi).clamp(0.0, 1.0);
                
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Günlük Kalori',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        CircularPercentIndicator(
                          radius: 80,
                          lineWidth: 12,
                          percent: ilerleme,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${tuketilenKalori.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text('/ ${kaloriHedefi.toStringAsFixed(0)}'),
                            ],
                          ),
                          progressColor: ilerleme > 1.0 ? Colors.red : Colors.green,
                        ),
                        SizedBox(height: 8),
                        Text(
                          kalanKalori > 0 
                              ? '${kalanKalori.toStringAsFixed(0)} kcal kaldı'
                              : '${(-kalanKalori).toStringAsFixed(0)} kcal fazla',
                          style: TextStyle(
                            color: kalanKalori > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

                      SizedBox(height: 16),

            // Makro besinler
            if (todayNutrition != null) _buildMacroNutrients(),

            SizedBox(height: 16),

            // Bugünkü öğünler
            Text(
              'Bugünkü Öğünler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            if (todayMeals.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Henüz öğün eklenmedi',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            else
              ...todayMeals.map((meal) => _buildMealCard(meal)),
          ], // else bloğunu kapatıyoruz
        ],
      ),
    ),
    );
  }

  Widget _buildMacroNutrients() {
    final protein = todayNutrition!.toplamProtein;
    final karbonhidrat = todayNutrition!.toplamKarbonhidrat;
    final yag = todayNutrition!.toplamYag;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Makro Besinler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem('Protein', protein, Colors.red),
                _buildMacroItem('Karbonhidrat', karbonhidrat, Colors.orange),
                _buildMacroItem('Yağ', yag, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String name, double value, Color color) {
    // Her makro besin için günlük önerilen hedefler (gram)
    double hedef = 0;
    if (currentUser != null) {
      final gunlukKalori = currentUser!.gunlukKaloriHedefi;
      switch (name) {
        case 'Protein':
          hedef = (gunlukKalori * 0.25) / 4; // Kalorilerin %25'i protein (4 kcal/g)
          break;
        case 'Karbonhidrat':
          hedef = (gunlukKalori * 0.50) / 4; // Kalorilerin %50'si karbonhidrat (4 kcal/g)
          break;
        case 'Yağ':
          hedef = (gunlukKalori * 0.25) / 9; // Kalorilerin %25'i yağ (9 kcal/g)
          break;
      }
    }
    
    final yuzde = hedef > 0 ? (value / hedef).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 30,
          lineWidth: 6,
          percent: yuzde,
          center: Text(
            '${value.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          progressColor: color,
          backgroundColor: color.withOpacity(0.2),
        ),
        SizedBox(height: 4),
        Text(name, style: TextStyle(fontSize: 12)),
        if (hedef > 0)
          Text(
            '/ ${hedef.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildMealCard(OgunGirisiModeli meal) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMealTypeColor(meal.ogunTipi),
          child: Icon(
            _getMealTypeIcon(meal.ogunTipi),
            color: Colors.white,
          ),
        ),
        title: Text(meal.yemekIsmi),
        subtitle: Text(
          '${meal.ogunTipi} • ${meal.tuketilenGram.toStringAsFixed(0)}g',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${meal.kalori.toStringAsFixed(0)} kcal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('HH:mm').format(meal.tuketimTarihi),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onLongPress: () => _deleteMeal(meal),
      ),
    );
  }

  Widget _buildRecommendationsTab(TemaServisi temaServisi) {
    if (todayNutrition == null) {
      return Container(
        color: temaServisi.isDarkMode ? Color(0xFF1A1A1A) : null,
        child: Center(
          child: Text('Veri yok'),
        ),
      );
    }

    final recommendations = todayNutrition!.gunlukOneriler;
    final score = todayNutrition!.beslenmeSkoru;

    return Container(
      color: temaServisi.isDarkMode ? Color(0xFF1A1A1A) : null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Beslenme skoru
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 40,
                    lineWidth: 8,
                    percent: score / 100,
                    center: Text(
                      '${score.toInt()}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    progressColor: score > 75 ? Colors.green : score > 50 ? Colors.orange : Colors.red,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beslenme Skoru',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          score > 75 ? 'Mükemmel!' : score > 50 ? 'İyi' : 'Geliştirilmeli',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          Text(
            'Öneriler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),

          if (recommendations.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Harika! Bugün için önerimiz yok.',
                    style: TextStyle(color: Colors.green[600]),
                  ),
                ),
              ),
            )
          else
            ...recommendations.map((recommendation) => Card(
              child: ListTile(
                leading: Icon(Icons.lightbulb, color: Colors.orange),
                title: Text(recommendation),
              ),
            )),
        ],
      ),
    ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'Kahvaltı': return Colors.orange;
      case 'Ara Öğün': return Colors.purple;
      case 'Öğle Yemeği': return Colors.blue;
      case 'Akşam Yemeği': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'Kahvaltı': return Icons.wb_sunny;
      case 'Ara Öğün': return Icons.local_cafe;
      case 'Öğle Yemeği': return Icons.lunch_dining;
      case 'Akşam Yemeği': return Icons.dinner_dining;
      default: return Icons.restaurant;
    }
  }

  Future<void> _deleteMeal(OgunGirisiModeli meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Öğünü Sil'),
        content: Text('${meal.yemekIsmi} öğününü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
              await VeriTabaniServisi.ogunGirisiSil(meal.id);
      _loadTodayData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğün silindi')),
      );
    }
  }

  void _showUserProfile() {
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İsim: ${currentUser!.isim}'),
            Text('Boy: ${currentUser!.boy.toInt()} cm'),
            Text('Kilo: ${currentUser!.kilo.toInt()} kg'),
            Text('Yaş: ${currentUser!.yas}'),
            Text('BMR: ${currentUser!.bmr.toStringAsFixed(0)} kcal'),
            Text('Günlük Hedef: ${currentUser!.gunlukKaloriHedefi.toStringAsFixed(0)} kcal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _cikisYap() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap'),
        content: Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    await FirebaseAuthServisi.cikisYap();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => GirisEkrani()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
