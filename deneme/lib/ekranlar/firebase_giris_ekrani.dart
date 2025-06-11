import 'package:flutter/material.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../widgets/yukleme_gostergesi.dart';
import 'firebase_kayit_ekrani.dart';
import 'sifre_sifirlama_ekrani.dart';
import 'ana_ekran.dart';
import 'bilgi_giris_ekrani.dart';

class FirebaseGirisEkrani extends StatefulWidget {
  @override
  _FirebaseGirisEkraniState createState() => _FirebaseGirisEkraniState();
}

class _FirebaseGirisEkraniState extends State<FirebaseGirisEkrani>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _yukleniyor = false;
  bool _sifreGosteriliyor = false;
  bool _beniHatirla = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      final basarili = await FirebaseAuthServisi.epostaIleGirisYap(
        _emailController.text.trim(),
        _sifreController.text,
      );

      if (basarili) {
        // Email doğrulanmış mı kontrol et (demo mode'da skip edilir)
        final kullanici = FirebaseAuthServisi.mevcutKullanici;
        if (kullanici != null && !kullanici.emailVerified && !FirebaseAuthServisi.demoMode) {
          _emailDogrulamaUyarisiGoster();
          return;
        }

        // Ana ekrana git
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AnaEkran(bmr: 2000)), // BMR veritabanından gelecek
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş yapılamadı: $e'),
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
          'Hesabınıza erişebilmek için email adresinizi doğrulamanız gerekiyor. '
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
          child: _yukleniyor
              ? Center(
                  child: YuklemeHelper.kartYukleme(
                    mesaj: 'Giriş yapılıyor...',
                    renk: Colors.white,
                  ),
                )
              : _buildGirisFormu(),
        ),
      ),
    );
  }

  Widget _buildGirisFormu() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              SizedBox(height: 60),
              
              // Logo ve başlık
              _buildBaslik(),
              
              SizedBox(height: 50),
              
              // Giriş formu
              _buildFormKarti(),
              
              SizedBox(height: 24),
              
              // Şifre sıfırlama
              _buildSifreSifirlamaButonu(),
              
              SizedBox(height: 32),
              
              // Kayıt ol linki
              _buildKayitOlLinki(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBaslik() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
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
            size: 50,
            color: Colors.green[600],
          ),
        ),
        
        SizedBox(height: 24),
        
        Text(
          'Hoş Geldiniz',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 8),
        
        Text(
          'Beslenme takibinize devam edin',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFormKarti() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email Adresi',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email adresi gerekli';
                  }
                  if (!FirebaseAuthServisi.emailGecerliMi(value)) {
                    return 'Geçerli bir email adresi girin';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Şifre field
              TextFormField(
                controller: _sifreController,
                obscureText: !_sifreGosteriliyor,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _girisYap(),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_sifreGosteriliyor ? Icons.visibility_off : Icons.visibility),
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
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre gerekli';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Beni hatırla
              Row(
                children: [
                  Checkbox(
                    value: _beniHatirla,
                    onChanged: (value) {
                      setState(() {
                        _beniHatirla = value ?? false;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  Text('Beni Hatırla'),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Giriş butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _girisYap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSifreSifirlamaButonu() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SifreSifirlamaEkrani(),
          ),
        );
      },
      child: Text(
        'Şifremi Unuttum',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildKayitOlLinki() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabınız yok mu? ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FirebaseKayitEkrani(),
              ),
            );
          },
          child: Text(
            'Kayıt Ol',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
} 