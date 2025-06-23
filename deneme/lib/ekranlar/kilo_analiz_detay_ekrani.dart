import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../hizmetler/kilo_analiz_servisi.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../modeller/kullanici_modeli.dart';

class KiloAnalizDetayEkrani extends StatefulWidget {
  const KiloAnalizDetayEkrani({super.key});

  @override
  State<KiloAnalizDetayEkrani> createState() => _KiloAnalizDetayEkraniState();
}

class _KiloAnalizDetayEkraniState extends State<KiloAnalizDetayEkrani> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _kapsamliAnaliz;
  Map<String, dynamic>? _hedefAnalizi;
  Map<String, dynamic>? _gelecekTahmini;
  bool _yukleniyor = true;
  String? _kullaniciId;
  final _hedefKiloController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analizleriYukle();
  }

  Future<void> _analizleriYukle() async {
    setState(() => _yukleniyor = true);
    
    try {
      final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (kullanici != null) {
        _kullaniciId = kullanici.id;
        _hedefKiloController.text = kullanici.kilo.toStringAsFixed(1);
        
        final kapsamli = await KiloAnalizServisi.kapsamliKiloAnaliziYap(kullanici.id);
        final hedef = await KiloAnalizServisi.hedefKiloAnalizi(kullanici.id, kullanici.kilo);
        final gelecek = await KiloAnalizServisi.gelecekKiloTahmini(kullanici.id, 30);
        
        setState(() {
          _kapsamliAnaliz = kapsamli;
          _hedefAnalizi = hedef;
          _gelecekTahmini = gelecek;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      print('Analiz yükleme hatası: $e');
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _hedefKiloAnalizi() async {
    final hedefKilo = double.tryParse(_hedefKiloController.text);
    if (hedefKilo == null || _kullaniciId == null) return;

    setState(() => _yukleniyor = true);
    
    try {
      final hedefAnalizi = await KiloAnalizServisi.hedefKiloAnalizi(_kullaniciId!, hedefKilo);
      setState(() {
        _hedefAnalizi = hedefAnalizi;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Kilo Analiz Merkezi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.analytics), text: 'Genel'),
            Tab(icon: Icon(Icons.flag), text: 'Hedef'),
            Tab(icon: Icon(Icons.timeline), text: 'Tahmin'),
            Tab(icon: Icon(Icons.science), text: 'BMR'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _yukleniyor
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGenelAnaliz(),
                _buildHedefAnalizi(),
                _buildGelecekTahmini(),
                _buildBMRAnalizi(),
              ],
            ),
    );
  }

  Widget _buildGenelAnaliz() {
    if (_kapsamliAnaliz == null) return Center(child: Text('Veri yok'));
    
    final kaloriAnalizi = _kapsamliAnaliz!['gunlukKaloriAnalizi'] as Map<String, dynamic>;
    final makroAnalizi = _kapsamliAnaliz!['makrobesinAnalizi'] as Map<String, dynamic>;
    final kiloIstatistikleri = _kapsamliAnaliz!['kiloIstatistikleri'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genel durum kartı
          _buildKart(
            'Günlük Kalori Dengesi',
            Icons.local_fire_department,
            [Colors.red, Colors.orange],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem('Hedef Kalori', '${kaloriAnalizi['kaloriHedefi'].toStringAsFixed(0)} kcal'),
                _buildStatItem('Alınan Kalori', '${kaloriAnalizi['alinanKalori'].toStringAsFixed(0)} kcal'),
                _buildStatItem('Denge', '${kaloriAnalizi['kaloriDengesi'].toStringAsFixed(0)} kcal'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getKaloriRengi(kaloriAnalizi['durum']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kaloriAnalizi['aciklama'],
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Makrobesin kalitesi
          _buildKart(
            'Makrobesin Kalitesi',
            Icons.pie_chart,
            [Colors.green, Colors.blue],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kilo Kalitesi Skoru'),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSkorRengi(makroAnalizi['kiloKalitesiSkoru']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${makroAnalizi['kiloKalitesiSkoru']}/100',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildMakroBar('Protein', makroAnalizi['proteinYuzdesi'], makroAnalizi['proteinYeterli']),
                _buildMakroBar('Karbonhidrat', makroAnalizi['karbonhidratYuzdesi'], makroAnalizi['karbonhidratDengeli']),
                _buildMakroBar('Yağ', makroAnalizi['yagYuzdesi'], makroAnalizi['yagSaglikli']),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Kilo istatistikleri
          _buildKart(
            'Kilo İstatistikleri',
            Icons.scale,
            [Colors.purple, Colors.indigo],
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Mevcut', '${kiloIstatistikleri['mevcutKilo']?.toStringAsFixed(1) ?? '0.0'} kg')),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Haftalık', '${kiloIstatistikleri['haftalikDegisim']?.toStringAsFixed(1) ?? '0.0'} kg')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Aylık', '${kiloIstatistikleri['aylikDegisim']?.toStringAsFixed(1) ?? '0.0'} kg')),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Toplam Kayıt', '${kiloIstatistikleri['toplamKayit'] ?? 0}')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHedefAnalizi() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKart(
            'Hedef Kilo Belirleme',
            Icons.flag,
            [Colors.orange, Colors.red],
            Column(
              children: [
                TextFormField(
                  controller: _hedefKiloController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Hedef Kilo (kg)',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calculate),
                      onPressed: _hedefKiloAnalizi,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (_hedefAnalizi != null && !_hedefAnalizi!.containsKey('hata')) ...[
                  _buildStatItem('Mevcut Kilo', '${_hedefAnalizi!['mevcutKilo'].toStringAsFixed(1)} kg'),
                  _buildStatItem('Kilo Farkı', '${_hedefAnalizi!['kiloFarki'].toStringAsFixed(1)} kg'),
                  _buildStatItem('Tahmini Süre', '${_hedefAnalizi!['tahminiHaftalar']} hafta (${_hedefAnalizi!['tahminiAylar']} ay)'),
                  _buildStatItem('Gereken Kalori Değişimi', '${_hedefAnalizi!['gerekenKaloriDegisimi'].toStringAsFixed(0)} kcal/gün'),
                  _buildStatItem('Yeni Kalori Hedefi', '${_hedefAnalizi!['yeniKaloriHedefi'].toStringAsFixed(0)} kcal/gün'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hedefAnalizi!['saglikliMi'] ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hedefAnalizi!['saglikliMi'] ? Icons.check_circle : Icons.warning,
                          color: _hedefAnalizi!['saglikliMi'] ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _hedefAnalizi!['saglikliMi'] 
                                ? 'Hedef kilonuz sağlıklı BMI aralığında'
                                : 'Hedef kilonuz sağlıklı BMI aralığının dışında',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
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

  Widget _buildGelecekTahmini() {
    if (_gelecekTahmini == null) return Center(child: Text('Veri yok'));
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKart(
            '30 Günlük Kilo Tahmini',
            Icons.timeline,
            [Colors.blue, Colors.purple],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem('Mevcut Kilo', '${_gelecekTahmini!['mevcutKilo'].toStringAsFixed(1)} kg'),
                _buildStatItem('Tahmini Kilo (30 gün)', '${_gelecekTahmini!['tahminiKilo'].toStringAsFixed(1)} kg'),
                                 _buildStatItem('Beklenen Değişim', '${_gelecekTahmini!['tahminiKiloDegisimi'].toStringAsFixed(2)} kg'),
                _buildStatItem('Günlük Kalori Ortalaması', '${_gelecekTahmini!['gunlukOrtalamaDengesi'].toStringAsFixed(0)} kcal'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Güvenilirlik: ${_gelecekTahmini!['guvenilirlik']}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu tahmin mevcut beslenme alışkanlıklarınızın devam edeceği varsayımına dayanır.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMRAnalizi() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKart(
            'BMR & Kalori Entegrasyonu',
            Icons.science,
            [Colors.teal, Colors.green],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kilo Takibi ile BMR Entegrasyonu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Otomatik BMR Güncellemesi', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Kilo girişi yaptığınızda BMR ve kalori hedeflerin otomatik güncellenir.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Kalori Dengesi Analizi', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Günlük kalori alımınız hedefle karşılaştırılarak kilo etkisi hesaplanır.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Gelecek Tahminleri', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Beslenme alışkanlıklarınıza göre gelecek kilo değişimi tahmin edilir.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Makrobesin Kalitesi', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Protein, karbonhidrat ve yağ oranlarına göre kilo kalitesi değerlendirilir.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKart(String baslik, IconData icon, List<Color> gradientColors, Widget content) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                baslik,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8))),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMakroBar(String isim, double yuzde, bool optimal) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isim, style: TextStyle(color: Colors.white.withOpacity(0.8))),
              Row(
                children: [
                  Icon(
                    optimal ? Icons.check_circle : Icons.warning,
                    color: optimal ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text('${yuzde.toStringAsFixed(1)}%', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: yuzde / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(optimal ? Colors.green : Colors.orange),
          ),
        ],
      ),
    );
  }

  Color _getKaloriRengi(String durum) {
    switch (durum) {
      case 'Dengede': return Colors.green;
      case 'Açık': return Colors.orange;
      case 'Fazla': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getSkorRengi(int skor) {
    // Kalori aşımı kontrolü - kırmızı renk ver
    if (bugunBeslenme != null && kullanici != null) {
      final kaloriAsimi = bugunBeslenme!.toplamKalori - kullanici!.gunlukKaloriHedefi;
      if (kaloriAsimi > 100) {
        return Colors.red; // Kalori aşımında kırmızı
      }
    }
    
    // Normal skor rengi
    if (skor >= 80) return Colors.green;
    if (skor >= 60) return Colors.orange;
    if (skor >= 40) return Colors.yellow[700]!;
    return Colors.red;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hedefKiloController.dispose();
    super.dispose();
  }
} 