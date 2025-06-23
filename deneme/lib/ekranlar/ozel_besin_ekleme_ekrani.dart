import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../modeller/ozel_besin_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import '../modeller/yemek_ogesi_modeli.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../servisler/tema_servisi.dart';

class OzelBesinEklemeEkrani extends StatefulWidget {
  @override
  _OzelBesinEklemeEkraniState createState() => _OzelBesinEklemeEkraniState();
}

class _OzelBesinEklemeEkraniState extends State<OzelBesinEklemeEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _besinIsmiController = TextEditingController();
  final _kaloriController = TextEditingController();
  final _proteinController = TextEditingController();
  final _karbonhidratController = TextEditingController();
  final _yagController = TextEditingController();
  final _lifController = TextEditingController();

  String _secilenKategori = 'Özel Besin';
  bool _yukleniyor = false;

  final List<String> _kategoriler = [
    'Özel Besin',
    'Ana Yemek',
    'Atıştırmalık',
    'İçecek',
    'Tatlı',
    'Meyve',
    'Sebze',
    'Et/Balık',
    'Süt Ürünü',
    'Tahıl',
    'Diğer'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        return Scaffold(
          backgroundColor: temaServisi.isDarkMode ? Color(0xFF1A1A1A) : Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text(
              'Özel Besin Ekle',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: temaServisi.isDarkMode ? Color(0xFF1E3A8A) : Color(0xFF2E7D32),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: temaServisi.isDarkMode 
                  ? [
                      Color(0xFF1A1A1A),
                      Color(0xFF2A2A2A),
                      Color(0xFF1E1E1E),
                    ]
                  : [
                      Color(0xFFF8F9FA),
                      Color(0xFFF1F5F9),
                      Color(0xFFE8F5E8),
                    ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBilgiKarti(temaServisi),
                    const SizedBox(height: 20),
                    _buildTemelBilgilerKarti(temaServisi),
                    const SizedBox(height: 20),
                    _buildBesinDegerleriKarti(temaServisi),
                    const SizedBox(height: 30),
                    _buildKaydetButonu(temaServisi),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBilgiKarti(TemaServisi temaServisi) {
    return Card(
      elevation: temaServisi.isDarkMode ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: temaServisi.isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: temaServisi.isDarkMode 
              ? [Color(0xFF2A2A2A), Color(0xFF353535)]
              : [Colors.blue.shade50, Colors.green.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: temaServisi.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kendi özel besinlerinizi ekleyerek daha kişiselleştirilmiş beslenme takibi yapabilirsiniz.',
                style: TextStyle(
                  color: temaServisi.isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemelBilgilerKarti(TemaServisi temaServisi) {
    return Card(
      elevation: temaServisi.isDarkMode ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: temaServisi.isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: temaServisi.isDarkMode ? Colors.green.shade400 : Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Temel Bilgiler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: temaServisi.isDarkMode ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _besinIsmiController,
              label: 'Besin Adı',
              hint: 'Örn: Ev Yapımı Kek',
              icon: Icons.edit,
              temaServisi: temaServisi,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Besin adı zorunludur';
                }
                if (value.trim().length < 2) {
                  return 'Besin adı en az 2 karakter olmalıdır';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              value: _secilenKategori,
              items: _kategoriler,
              label: 'Kategori',
              icon: Icons.category,
              temaServisi: temaServisi,
              onChanged: (value) {
                setState(() {
                  _secilenKategori = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBesinDegerleriKarti(TemaServisi temaServisi) {
    return Card(
      elevation: temaServisi.isDarkMode ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: temaServisi.isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: temaServisi.isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Besin Değerleri (100g için)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: temaServisi.isDarkMode ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _kaloriController,
              label: 'Kalori (kcal) *',
              hint: 'Örn: 250',
              icon: Icons.local_fire_department,
              keyboardType: TextInputType.number,
              temaServisi: temaServisi,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kalori değeri zorunludur';
                }
                final kalori = double.tryParse(value);
                if (kalori == null || kalori < 0) {
                  return 'Geçerli bir kalori değeri girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _proteinController,
                    label: 'Protein (g)',
                    hint: '0.0',
                    icon: Icons.fitness_center,
                    keyboardType: TextInputType.number,
                    temaServisi: temaServisi,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextFormField(
                    controller: _karbonhidratController,
                    label: 'Karbonhidrat (g)',
                    hint: '0.0',
                    icon: Icons.grain,
                    keyboardType: TextInputType.number,
                    temaServisi: temaServisi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _yagController,
                    label: 'Yağ (g)',
                    hint: '0.0',
                    icon: Icons.opacity,
                    keyboardType: TextInputType.number,
                    temaServisi: temaServisi,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextFormField(
                    controller: _lifController,
                    label: 'Lif (g)',
                    hint: '0.0',
                    icon: Icons.eco,
                    keyboardType: TextInputType.number,
                    temaServisi: temaServisi,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TemaServisi temaServisi,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: temaServisi.isDarkMode ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: temaServisi.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        hintStyle: TextStyle(
          color: temaServisi.isDarkMode ? Colors.grey[500] : Colors.grey[500],
        ),
        prefixIcon: Icon(
          icon, 
          color: temaServisi.isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: temaServisi.isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: temaServisi.isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: temaServisi.isDarkMode ? Colors.blue.shade400 : Colors.green.shade600, 
            width: 2,
          ),
        ),
        filled: true,
        fillColor: temaServisi.isDarkMode ? Color(0xFF353535) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required TemaServisi temaServisi,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: TextStyle(
        color: temaServisi.isDarkMode ? Colors.white : Colors.black,
      ),
      dropdownColor: temaServisi.isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: temaServisi.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon, 
          color: temaServisi.isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: temaServisi.isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: temaServisi.isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: temaServisi.isDarkMode ? Colors.blue.shade400 : Colors.green.shade600, 
            width: 2,
          ),
        ),
        filled: true,
        fillColor: temaServisi.isDarkMode ? Color(0xFF353535) : Colors.grey.shade50,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: temaServisi.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKaydetButonu(TemaServisi temaServisi) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: temaServisi.isDarkMode 
            ? [Color(0xFF1E3A8A), Color(0xFF3B82F6)]
            : [Colors.green.shade600, Colors.green.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (temaServisi.isDarkMode ? Colors.blue : Colors.green).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _yukleniyor ? null : _ozelBesinKaydet,
        icon: _yukleniyor
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.save, color: Colors.white),
        label: Text(
          _yukleniyor ? 'Kaydediliyor...' : 'Özel Besini Kaydet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _ozelBesinKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      // Aktif kullanıcıyı al
      final aktifKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (aktifKullanici == null) {
        throw Exception('Oturum açmış kullanıcı bulunamadı');
      }

      final ozelBesin = OzelBesinModeli(
        kullaniciId: aktifKullanici.id,
        isim: _besinIsmiController.text.trim(),
        yuzGramKalori: double.parse(_kaloriController.text),
        yuzGramProtein: double.tryParse(_proteinController.text) ?? 0.0,
        yuzGramKarbonhidrat: double.tryParse(_karbonhidratController.text) ?? 0.0,
        yuzGramYag: double.tryParse(_yagController.text) ?? 0.0,
        yuzGramLif: double.tryParse(_lifController.text) ?? 0.0,
        kategori: _secilenKategori,
      );

      final kaydedilenBesin = await VeriTabaniServisi.ozelBesinKaydet(ozelBesin);

      // Özel besin kaydedildikten sonra öğün ekleme seçeneği sun
      final ogunEklemek = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🎉 Besin Eklendi!'),
          content: Text('${kaydedilenBesin.isim} başarıyla eklendi.\n\nBu besini hemen günlük öğününe eklemek ister misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hayır, Sonra'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Evet, Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (ogunEklemek == true) {
        // Öğün ekleme dialog'unu göster
        await _ogunEklemeDialogGoster(kaydedilenBesin);
      }

      Navigator.of(context).pop(true); // Başarılı olduğunu belirt

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  Future<void> _ogunEklemeDialogGoster(OzelBesinModeli besin) async {
    String secilenOgun = 'Kahvaltı';
    final gramController = TextEditingController(text: '100');
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Öğün Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${besin.isim} hangi öğüne eklensin?'),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: secilenOgun,
                decoration: InputDecoration(
                  labelText: 'Öğün Seç',
                  border: OutlineInputBorder(),
                ),
                items: ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Atıştırmalık']
                    .map((ogun) => DropdownMenuItem(
                          value: ogun,
                          child: Text(ogun),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    secilenOgun = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: gramController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Gramaj',
                  suffixText: 'gram',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('100g için:'),
                    Text('${besin.yuzGramKalori.round()} kcal', 
                         style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final gram = double.tryParse(gramController.text) ?? 100;
                Navigator.of(context).pop({
                  'ogun': secilenOgun,
                  'gram': gram,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      // Öğün girişini kaydet
      await _ogunGirisiKaydet(besin, result['ogun'], result['gram']);
    }
  }

  Future<void> _ogunGirisiKaydet(OzelBesinModeli besin, String ogunTipi, double gram) async {
    try {
      final aktifKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (aktifKullanici == null) return;

      // Özel besini YemekOgesiModeli'ne dönüştür
      final yemekOgesi = YemekOgesiModeli(
        id: 'ozel_${besin.id}_${DateTime.now().millisecondsSinceEpoch}',
        fdcId: besin.id ?? 0,
        isim: besin.isim,
        yuzGramKalori: besin.yuzGramKalori,
        yuzGramProtein: besin.yuzGramProtein,
        yuzGramKarbonhidrat: besin.yuzGramKarbonhidrat,
        yuzGramYag: besin.yuzGramYag,
        yuzGramLif: besin.yuzGramLif,
        kategori: besin.kategori,
        favoriMi: false,
        eklenmeTarihi: DateTime.now(),
      );

      await VeriTabaniServisi.ogunGirisiEkle(
        kullaniciId: aktifKullanici.id,
        yemekOgesi: yemekOgesi,
        gramMiktari: gram,
        ogunTipi: ogunTipi,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${besin.isim} ${ogunTipi} öğününe eklendi!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öğün eklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _besinIsmiController.dispose();
    _kaloriController.dispose();
    _proteinController.dispose();
    _karbonhidratController.dispose();
    _yagController.dispose();
    _lifController.dispose();
    super.dispose();
  }
} 