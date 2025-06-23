import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modeller/kilo_girisi_modeli.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/kilo_analiz_servisi.dart';

class KiloGirisEkrani extends StatefulWidget {
  const KiloGirisEkrani({super.key});

  @override
  State<KiloGirisEkrani> createState() => _KiloGirisEkraniState();
}

class _KiloGirisEkraniState extends State<KiloGirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _kiloController = TextEditingController();
  final _notlarController = TextEditingController();
  
  DateTime _seciliTarih = DateTime.now();
  bool _yukleniyor = false;
  String? _kullaniciId;

  @override
  void initState() {
    super.initState();
    _kullaniciBilgileriniYukle();
  }

  Future<void> _kullaniciBilgileriniYukle() async {
    final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
    print('KiloGirisEkrani: Kullanıcı yüklendi: ${kullanici?.isim}, ID: ${kullanici?.id}, Kilo: ${kullanici?.kilo}');
    if (kullanici != null) {
      setState(() {
        _kullaniciId = kullanici.id;
        // Mevcut kiloyu form alanına otomatik doldur
        _kiloController.text = kullanici.kilo.toStringAsFixed(1);
      });
      print('KiloGirisEkrani: Form alanına dolduruldu: ${_kiloController.text}');
    } else {
      print('KiloGirisEkrani: HATA - Kullanıcı bulunamadı!');
    }
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _seciliTarih,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (secilen != null) {
      setState(() {
        _seciliTarih = secilen;
      });
    }
  }

  Future<void> _kiloKaydet() async {
    print('KiloGirisEkrani: _kiloKaydet çağrıldı');
    print('KiloGirisEkrani: Form valid: ${_formKey.currentState?.validate()}');
    print('KiloGirisEkrani: Kullanıcı ID: $_kullaniciId');
    
    if (!_formKey.currentState!.validate() || _kullaniciId == null) {
      print('KiloGirisEkrani: Validation başarısız veya kullanıcı ID null');
      return;
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      final kilo = double.parse(_kiloController.text);
      final notlar = _notlarController.text.trim();

      final kiloGirisi = KiloGirisiModeli(
        id: '',
        kullaniciId: _kullaniciId!,
        kilo: kilo,
        olcumTarihi: _seciliTarih,
        kayitTarihi: DateTime.now(),
        notlar: notlar.isEmpty ? null : notlar,
      );

      print('Kilo girişi kaydediliyor: ${kiloGirisi.kilo} kg');
      await VeriTabaniServisi.kiloGirisiKaydet(kiloGirisi);
      print('Kilo girişi başarıyla kaydedildi');

      // BMR ve kalori hedefini güncelle
      print('BMR güncellenmesi başlıyor...');
      await KiloAnalizServisi.kiloDegistitindeBMRGuncelle(_kullaniciId!, kilo);
      print('BMR güncellendi');

      // Kalori analizi yap
      final kaloriAnalizi = await KiloAnalizServisi.kaloriDengesiAnaliziYap(_kullaniciId!, DateTime.now());

      if (mounted) {
        // Önce başarı durumunu geri döndür
        Navigator.of(context).pop(true);
        
        // Sonra analiz sonuçlarını göster
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            _analizSonuclariniGoster(kaloriAnalizi, kilo);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Kilo kaydedilirken hata oluştu!'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  void _analizSonuclariniGoster(Map<String, dynamic> kaloriAnalizi, double yeniKilo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Kilo & Beslenme Analizi',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kilo kaydedildi mesajı
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '${yeniKilo.toStringAsFixed(1)} kg başarıyla kaydedildi!',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // BMR güncelleme bilgisi
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'BMR & Kalori Hedefi Güncellendi',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Yeni kilonuza göre metabolizma hızınız ve günlük kalori hedeflerin otomatik güncellendi.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Kalori dengesi analizi
              Text(
                '🔥 Kalori Dengesi Analizi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getKaloriRengi(kaloriAnalizi['durum']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getKaloriRengi(kaloriAnalizi['durum']).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getKaloriIcon(kaloriAnalizi['durum']), 
                             color: _getKaloriRengi(kaloriAnalizi['durum']), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Durum: ${kaloriAnalizi['durum']}',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('Hedef: ${kaloriAnalizi['kaloriHedefi'].toStringAsFixed(0)} kcal'),
                    Text('Alınan: ${kaloriAnalizi['alinanKalori'].toStringAsFixed(0)} kcal'),
                    Text('Denge: ${kaloriAnalizi['kaloriDengesi'].toStringAsFixed(0)} kcal'),
                    SizedBox(height: 4),
                    Text(
                      kaloriAnalizi['aciklama'],
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }



  Color _getKaloriRengi(String durum) {
    switch (durum) {
      case 'Dengede':
        return Colors.green;
      case 'Açık':
        return Colors.orange;
      case 'Fazla':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getKaloriIcon(String durum) {
    switch (durum) {
      case 'Dengede':
        return Icons.balance;
      case 'Açık':
        return Icons.trending_down;
      case 'Fazla':
        return Icons.trending_up;
      default:
        return Icons.help;
    }
  }

  @override
  void dispose() {
    _kiloController.dispose();
    _notlarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Kilo Girişi'),
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
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kilo giriş kartı
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.scale, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kilo Bilgileriniz',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Güncel kilonuzu girin',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Kilo input
                    TextFormField(
                      controller: _kiloController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Kilo (kg)',
                        prefixIcon: Icon(Icons.scale),
                        suffixText: 'kg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen kilonuzu girin';
                        }
                        final kilo = double.tryParse(value);
                        if (kilo == null) {
                          return 'Geçerli bir kilo değeri girin';
                        }
                        if (kilo < 20 || kilo > 300) {
                          return 'Kilo 20-300 kg arasında olmalıdır';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    
                    // Tarih seçici
                    InkWell(
                      onTap: _tarihSec,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blue),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ölçüm Tarihi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_seciliTarih),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              // Kaydet butonu
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : () {
          print('KiloGirisEkrani: Kaydet butonuna basıldı');
          _kiloKaydet();
        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _yukleniyor
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Kaydediliyor...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Kiloyu Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),
              
              // Bilgi notu
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Düzenli kilo takibi sağlıklı bir yaşam için önemlidir. Haftada bir kez ölçüm yapmanız önerilir.',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 