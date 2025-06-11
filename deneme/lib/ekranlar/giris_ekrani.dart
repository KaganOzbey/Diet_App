import 'package:flutter/material.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../modeller/kullanici_modeli.dart';
import 'bilgi_giris_ekrani.dart';
import 'modern_dashboard.dart';

class GirisEkrani extends StatefulWidget {
  @override
  _GirisEkraniState createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _sifreTekrarController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoginMode = true; // true: Giriş, false: Kayıt
  bool _sifreGosteriliyor = false;
  bool _sifreTekrarGosteriliyor = false;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    // Demo kullanıcısını kontrol et
    final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
    if (demoKullanici != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ModernDashboard(bmr: demoKullanici.gunlukKaloriHedefi),
        ),
      );
      return;
    }
    
    // Yerel kullanıcıyı kontrol et
    final mevcutKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
    if (mevcutKullanici != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ModernDashboard(bmr: mevcutKullanici.gunlukKaloriHedefi),
        ),
      );
    }
  }

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final sifre = _sifreController.text;
      
      final basarili = await FirebaseAuthServisi.demoGiris(
        email: email,
        sifre: sifre,
      );
      
      if (basarili && mounted) {
        final kullanici = FirebaseAuthServisi.demomMevcutKullanici;
        if (kullanici != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ModernDashboard(bmr: kullanici.gunlukKaloriHedefi),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Giriş yapılamadı: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final sifre = _sifreController.text;
      final isim = _isimController.text.trim();
      
      final basarili = await FirebaseAuthServisi.demoKayit(
        email: email,
        sifre: sifre,
        isim: isim,
      );
      
      if (basarili && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BilgiGirisEkrani(email: email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Kayıt olunamadı: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _modeToggle() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _emailController.clear();
      _sifreController.clear();
      _isimController.clear();
      _sifreTekrarController.clear();
    });
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi gerekli';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Geçerli bir email adresi girin';
    }
    return null;
  }

  String? _sifreValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    return null;
  }

  String? _sifreTekrarValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }
    if (value != _sifreController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  String? _isimValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'İsim gerekli';
    }
    if (value.length < 2) {
      return 'İsim en az 2 karakter olmalı';
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[300]!,
              Colors.green[500]!,
              Colors.green[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Logo ve başlık
                SizedBox(height: 60),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Colors.green[600],
                  ),
                ),
                
                SizedBox(height: 24),
                
                Text(
                  'Beslenme Takip',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                
                SizedBox(height: 8),
                
                Text(
                  'Sağlıklı yaşamın anahtarı',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Form alanı
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
        child: Column(
          children: [
                        Text(
                          _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // İsim alanı (sadece kayıt modunda)
                        if (!_isLoginMode)
                          Column(
                            children: [
                              TextFormField(
                                controller: _isimController,
                                validator: _isimValidator,
                                decoration: InputDecoration(
                                  labelText: 'İsim Soyisim',
                                  prefixIcon: Icon(Icons.person, color: Colors.green[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green[600]!),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        
                        // Email alanı
                        TextFormField(
                          controller: _emailController,
                          validator: _emailValidator,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Adresi',
                            prefixIcon: Icon(Icons.email, color: Colors.green[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green[600]!),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Şifre alanı
                        TextFormField(
                          controller: _sifreController,
                          validator: _sifreValidator,
                          obscureText: !_sifreGosteriliyor,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: Icon(Icons.lock, color: Colors.green[600]),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _sifreGosteriliyor ? Icons.visibility_off : Icons.visibility,
                                color: Colors.green[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _sifreGosteriliyor = !_sifreGosteriliyor;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green[600]!),
                            ),
                          ),
                        ),
                        
                        // Şifre tekrarı alanı (sadece kayıt modunda)
                        if (!_isLoginMode)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _sifreTekrarController,
                                validator: _sifreTekrarValidator,
                                obscureText: !_sifreTekrarGosteriliyor,
                                decoration: InputDecoration(
                                  labelText: 'Şifre Tekrarı',
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.green[600]),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _sifreTekrarGosteriliyor ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.green[600],
                                    ),
              onPressed: () {
                                      setState(() {
                                        _sifreTekrarGosteriliyor = !_sifreTekrarGosteriliyor;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green[600]!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        
                        SizedBox(height: 32),
                        
                        // Giriş/Kayıt butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : (_isLoginMode ? _girisYap : _kayitOl),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Mode değiştirme butonu
                        TextButton(
                          onPressed: _modeToggle,
                          child: Text(
                            _isLoginMode 
                                ? 'Hesabınız yok mu? Kayıt olun'
                                : 'Zaten hesabınız var mı? Giriş yapın',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
            ),
          ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Bilgi metni
                Text(
                  'Giriş yaparak kişiselleştirilmiş beslenme planınıza ulaşın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _sifreController.dispose();
    _isimController.dispose();
    _sifreTekrarController.dispose();
    super.dispose();
  }
} 