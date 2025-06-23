import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../modeller/kullanici_modeli.dart';
import '../widgets/yukleme_gostergesi.dart';
import '../widgets/tema_degistirici.dart';
import '../servisler/tema_servisi.dart';
import 'firebase_giris_ekrani.dart';

class ProfilYonetimiEkrani extends StatefulWidget {
  @override
  _ProfilYonetimiEkraniState createState() => _ProfilYonetimiEkraniState();
}

class _ProfilYonetimiEkraniState extends State<ProfilYonetimiEkrani>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _sifreFormKey = GlobalKey<FormState>();
  
  // Profil bilgileri
  final _isimController = TextEditingController();
  final _boyController = TextEditingController();
  final _kiloController = TextEditingController();
  final _yasController = TextEditingController();
  
  // Şifre değişikliği
  final _eskiSifreController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();
  
  // Hesap silme
  final _silmeSifreController = TextEditingController();
  final _sifreOnayController = TextEditingController();
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  KullaniciModeli? _kullanici;
  bool _yukleniyor = false;
  bool _erkekMi = true;
  int _aktiviteSeviyesi = 2;
  
  // Şifre görünürlüğü
  bool _eskiSifreGosteriliyor = false;
  bool _yeniSifreGosteriliyor = false;
  bool _yeniSifreTekrarGosteriliyor = false;
  bool _silmeSifreGosteriliyor = false;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _bilgileriYukle();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _isimController.dispose();
    _boyController.dispose();
    _kiloController.dispose();
    _yasController.dispose();
    _eskiSifreController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    _silmeSifreController.dispose();
    _sifreOnayController.dispose();
    super.dispose();
  }

  Future<void> _bilgileriYukle() async {
    print('Profil: Kullanıcı bilgileri yükleniyor...');
    
    // Önce demo kullanıcısını kontrol et
    final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
    if (demoKullanici != null) {
      print('Profil: Demo kullanıcısı bulundu: ${demoKullanici.email}');
      setState(() {
        _kullanici = demoKullanici;
        _isimController.text = demoKullanici.isim;
        _boyController.text = demoKullanici.boy.toString();
        _kiloController.text = demoKullanici.kilo.toString();
        _yasController.text = demoKullanici.yas.toString();
        _erkekMi = demoKullanici.erkekMi;
        _aktiviteSeviyesi = demoKullanici.aktiviteSeviyesi;
      });
      return;
    }
    
    // Sonra yerel veritabanından kontrol et
    final aktifKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
    if (aktifKullanici != null) {
      print('Profil: Yerel kullanıcı bulundu: ${aktifKullanici.email}');
      setState(() {
        _kullanici = aktifKullanici;
        _isimController.text = aktifKullanici.isim;
        _boyController.text = aktifKullanici.boy.toString();
        _kiloController.text = aktifKullanici.kilo.toString();
        _yasController.text = aktifKullanici.yas.toString();
        _erkekMi = aktifKullanici.erkekMi;
        _aktiviteSeviyesi = aktifKullanici.aktiviteSeviyesi;
      });
      return;
    }
    
    print('Profil: Hiçbir kullanıcı bulunamadı');
  }

  Future<void> _profilGuncelle() async {
    if (!_formKey.currentState!.validate() || _kullanici == null) {
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      // Kullanıcı bilgilerini güncelle
      _kullanici!.isim = _isimController.text.trim();
      _kullanici!.boy = double.parse(_boyController.text);
      _kullanici!.kilo = double.parse(_kiloController.text);
      _kullanici!.yas = int.parse(_yasController.text);
      _kullanici!.erkekMi = _erkekMi;
      _kullanici!.aktiviteSeviyesi = _aktiviteSeviyesi;
      
      await _kullanici!.save();
      
      // Firebase'de kullanıcı adını güncelle
      final firebaseKullanici = FirebaseAuthServisi.mevcutKullanici;
      if (firebaseKullanici != null) {
        await firebaseKullanici.updateDisplayName(_isimController.text.trim());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _sifreDegistir() async {
    if (!_sifreFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _yukleniyor = true);

    final basarili = await FirebaseAuthServisi.sifreDegistir(
      context: context,
      mevcutSifre: _eskiSifreController.text,
      yeniSifre: _yeniSifreController.text,
    );

    setState(() => _yukleniyor = false);

    if (basarili && mounted) {
      _eskiSifreController.clear();
      _yeniSifreController.clear();
      _yeniSifreTekrarController.clear();
    }
  }

  Future<void> _hesabiSil() async {
    // Önce onay popup'ı göster
    final onay = await _hesapSilmeOnayiAl();
    if (onay != true) return;

    // Şifre popup'ı göster
    final sifre = await _sifrePopupuGoster();
    if (sifre == null || sifre.isEmpty) return;

    setState(() => _yukleniyor = true);

    try {
      final basarili = await FirebaseAuthServisi.hesabiSil(
        context: context,
        sifre: sifre,
      );

      if (basarili && mounted) {
        // Başarılı silme işleminden sonra giriş ekranına yönlendir
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => FirebaseGirisEkrani()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap silinemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  Future<bool?> _hesapSilmeOnayiAl() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hesabı Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hesabınızı silmek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Bu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecektir.',
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }

  Future<String?> _sifrePopupuGoster() async {
    final sifreController = TextEditingController();
    bool sifreGosteriliyor = false;

    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.orange),
              SizedBox(width: 8),
              Text('Şifre Gerekli'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hesabınızı silmek için mevcut şifrenizi girin:'),
              SizedBox(height: 16),
              TextFormField(
                controller: sifreController,
                obscureText: !sifreGosteriliyor,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(sifreGosteriliyor ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => sifreGosteriliyor = !sifreGosteriliyor),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final sifre = sifreController.text.trim();
                if (sifre.isNotEmpty) {
                  Navigator.pop(context, sifre);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Şifre boş olamaz'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Onayla'),
            ),
          ],
        ),
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
            child: Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    setState(() => _yukleniyor = true);

    await FirebaseAuthServisi.cikisYap();

    setState(() => _yukleniyor = false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => FirebaseGirisEkrani()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseKullanici = FirebaseAuthServisi.mevcutKullanici;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Yönetimi'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Profil'),
            Tab(icon: Icon(Icons.lock), text: 'Şifre'),
            Tab(icon: Icon(Icons.settings), text: 'Hesap'),
          ],
        ),
        actions: [
          if (firebaseKullanici != null && !firebaseKullanici.emailVerified)
            IconButton(
              icon: Icon(Icons.warning, color: Colors.orange),
              onPressed: () {
                _emailDogrulamaUyarisiGoster();
              },
              tooltip: 'Email doğrulanmadı',
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _cikisYap,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: _yukleniyor
          ? Center(
              child: YuklemeHelper.dairesel(
                mesaj: 'İşlem yapılıyor...',
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfilSekmesi(),
                  _buildSifreSekmesi(),
                  _buildHesapSekmesi(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfilSekmesi() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Kullanıcı kartı
            _buildKullaniciKarti(),
            
            SizedBox(height: 24),
            
            // Profil bilgileri formu
            _buildProfilFormu(),
            
            SizedBox(height: 32),
            
            // Güncelleme butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _profilGuncelle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Profil Güncelle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKullaniciKarti() {
    final firebaseKullanici = FirebaseAuthServisi.mevcutKullanici;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green[100],
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.green[600],
              ),
            ),
            
            SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kullanici?.isim ?? 'İsim Yok',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    firebaseKullanici?.email ?? 'Email Yok',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        firebaseKullanici?.emailVerified == true
                            ? Icons.verified
                            : Icons.warning,
                        size: 16,
                        color: firebaseKullanici?.emailVerified == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        firebaseKullanici?.emailVerified == true
                            ? 'Email Doğrulandı'
                            : 'Email Doğrulanmadı',
                        style: TextStyle(
                          fontSize: 12,
                          color: firebaseKullanici?.emailVerified == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilFormu() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kişisel Bilgiler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            
            SizedBox(height: 16),
            
            // İsim
            TextFormField(
              controller: _isimController,
              decoration: InputDecoration(
                labelText: 'İsim Soyisim',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'İsim gerekli';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Cinsiyet
            Text('Cinsiyet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Erkek'),
                    value: true,
                    groupValue: _erkekMi,
                    onChanged: (value) => setState(() => _erkekMi = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Kadın'),
                    value: false,
                    groupValue: _erkekMi,
                    onChanged: (value) => setState(() => _erkekMi = value!),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Boy, Kilo, Yaş
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _boyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Boy (cm)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Boy gerekli';
                      final boy = double.tryParse(value);
                      if (boy == null || boy < 100 || boy > 250) return 'Geçerli boy girin';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _kiloController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kilo (kg)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Kilo gerekli';
                      final kilo = double.tryParse(value);
                      if (kilo == null || kilo < 30 || kilo > 300) return 'Geçerli kilo girin';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _yasController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Yaş',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Yaş gerekli';
                      final yas = int.tryParse(value);
                      if (yas == null || yas < 10 || yas > 120) return 'Geçerli yaş girin';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Aktivite seviyesi
            Text('Aktivite Seviyesi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _aktiviteSeviyesi,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: 1, child: Text('Sedanter (Hareketsiz)')),
                DropdownMenuItem(value: 2, child: Text('Az Aktif (Haftada 1-3 gün)')),
                DropdownMenuItem(value: 3, child: Text('Orta Aktif (Haftada 3-5 gün)')),
                DropdownMenuItem(value: 4, child: Text('Aktif (Haftada 6-7 gün)')),
                DropdownMenuItem(value: 5, child: Text('Çok Aktif (Günde 2 kez)')),
              ],
              onChanged: (value) => setState(() => _aktiviteSeviyesi = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSifreSekmesi() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _sifreFormKey,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şifre Değiştir',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Mevcut şifre
                TextFormField(
                  controller: _eskiSifreController,
                  obscureText: !_eskiSifreGosteriliyor,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_eskiSifreGosteriliyor ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _eskiSifreGosteriliyor = !_eskiSifreGosteriliyor),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Mevcut şifre gerekli';
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // Yeni şifre
                TextFormField(
                  controller: _yeniSifreController,
                  obscureText: !_yeniSifreGosteriliyor,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_yeniSifreGosteriliyor ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _yeniSifreGosteriliyor = !_yeniSifreGosteriliyor),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Yeni şifre gerekli';
                    if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // Yeni şifre tekrar
                TextFormField(
                  controller: _yeniSifreTekrarController,
                  obscureText: !_yeniSifreTekrarGosteriliyor,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre Tekrar',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_yeniSifreTekrarGosteriliyor ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _yeniSifreTekrarGosteriliyor = !_yeniSifreTekrarGosteriliyor),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Şifre tekrarı gerekli';
                    if (value != _yeniSifreController.text) return 'Şifreler eşleşmiyor';
                    return null;
                  },
                ),
                
                SizedBox(height: 32),
                
                // Şifre değiştir butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sifreDegistir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Şifre Değiştir',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHesapSekmesi() {
    final firebaseKullanici = FirebaseAuthServisi.mevcutKullanici;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Email doğrulama kartı
          if (firebaseKullanici != null && !firebaseKullanici.emailVerified)
            Card(
              elevation: 2,
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Email Doğrulama Gerekli',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hesabınızın güvenliği için email adresinizi doğrulayın.',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => FirebaseAuthServisi.emailDogrulamaTekrarGonder(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Doğrulama Email\'i Gönder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          SizedBox(height: 16),
          
          // Görünüm ayarları kartı
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görünüm Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Dark mode toggle
                  TemaDegistirici(showLabel: true),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Hesap işlemleri kartı
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap İşlemleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Çıkış yap butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _cikisYap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text(
                            'Çıkış Yap',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Hesabı sil butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hesabiSil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever),
                          SizedBox(width: 8),
                          Text(
                            'Hesabı Sil',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _emailDogrulamaUyarisiGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Email Doğrulama'),
          ],
        ),
        content: Text(
          'Hesabınızın güvenliği için email adresinizi doğrulamanız önemlidir. '
          'Doğrulama email\'i tekrar gönderilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuthServisi.emailDogrulamaTekrarGonder(context);
            },
            child: Text('Email Gönder'),
          ),
        ],
      ),
    );
  }
} 