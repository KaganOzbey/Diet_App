import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import 'bilgi_giris_ekrani.dart';
import 'firebase_giris_ekrani.dart';

class FirebaseKayitEkrani extends StatefulWidget {
  const FirebaseKayitEkrani({super.key});

  @override
  State<FirebaseKayitEkrani> createState() => _FirebaseKayitEkraniState();
}

class _FirebaseKayitEkraniState extends State<FirebaseKayitEkrani>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _kisiselFormKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  
  // Hesap bilgileri
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  final _sifreTekrarController = TextEditingController();
  
  // Kişisel bilgiler
  final _isimController = TextEditingController();
  final _boyController = TextEditingController();
  final _kiloController = TextEditingController();
  final _yasController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _yukleniyor = false;
  bool _sifreGizli = true;
  bool _sifreTekrarGizli = true;
  bool _erkekMi = true;
  int _aktiviteSeviyesi = 2;
  int _mevcutSayfa = 0;
  
  Map<String, dynamic>? _sifreGucu;

  @override
  void initState() {
    super.initState();
    
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    _sifreTekrarController.dispose();
    _isimController.dispose();
    _boyController.dispose();
    _kiloController.dispose();
    _yasController.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _yukleniyor = true;
    });

    try {
      // Firebase Auth ile kayıt ol
      User? kullanici = await FirebaseAuthServisi.emailIleKayitOl(
        email: _emailController.text.trim(),
        sifre: _sifreController.text,
      );

      if (kullanici != null) {
        // Email doğrulama gönder
        await FirebaseAuthServisi.emailDogrulamaGonder();
        
        if (mounted) {
          // Başarılı mesaj göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Kayıt başarılı! Email doğrulama linki gönderildi.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Bilgi giriş ekranına yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BilgiGirisEkrani(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Kayıt hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  void _basariliKayitDialogGoster() {
    // Kayıt başarılı dialog'u göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Kayıt Başarılı!'),
          ],
        ),
        content: Text(
          'Hesabınız başarıyla oluşturuldu. Email adresinize bir doğrulama '
          'bağlantısı gönderildi. Lütfen email\'inizi kontrol edin.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FirebaseGirisEkrani()),
              );
            },
            child: Text('Giriş Ekranına Dön'),
          ),
        ],
      ),
    );
  }

  void _sonrakiSayfa() {
    print('_sonrakiSayfa çağrıldı - Mevcut sayfa: $_mevcutSayfa');
    
    if (_mevcutSayfa == 0) {
      print('Sayfa 0 - İlk sayfa doğrulaması yapılıyor');
      // İlk sayfa doğrulaması
      if (_emailController.text.isEmpty || 
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
        print('Email validation başarısız: ${_emailController.text}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geçerli bir email adresi girin')),
        );
        return;
      }
      
      if (_sifreController.text.length < 6) {
        print('Şifre validation başarısız: ${_sifreController.text.length} karakter');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifre en az 6 karakter olmalı')),
        );
        return;
      }
      
      if (_sifreController.text != _sifreTekrarController.text) {
        print('Şifre tekrar validation başarısız');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifreler eşleşmiyor')),
        );
        return;
      }
      
      print('Sayfa 0 validation geçti');
    }
    
    if (_mevcutSayfa < 1) {
      print('Sayfa 1\'e geçiliyor...');
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      print('Sayfa 1 - _kayitOl çağrılacak');
      _kayitOl();
    }
  }

  void _oncekiSayfa() {
    if (_mevcutSayfa > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hesap Oluştur',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Başlık
                const Text(
                  '🌟 Hoş Geldiniz!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Sağlıklı yaşam yolculuğunuza başlayın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Email alanı
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Adresi',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email adresi gerekli';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Geçerli bir email adresi girin';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Şifre alanı
                TextFormField(
                  controller: _sifreController,
                  obscureText: _sifreGizli,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_sifreGizli ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _sifreGizli = !_sifreGizli;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
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
                
                const SizedBox(height: 20),
                
                // Şifre tekrar alanı
                TextFormField(
                  controller: _sifreTekrarController,
                  obscureText: _sifreTekrarGizli,
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_sifreTekrarGizli ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _sifreTekrarGizli = !_sifreTekrarGizli;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre tekrarı gerekli';
                    }
                    if (value != _sifreController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Kayıt ol butonu
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _yukleniyor ? null : _kayitOl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _yukleniyor
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Hesap Oluştur',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Giriş yap linki
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Zaten hesabınız var mı? ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FirebaseGirisEkrani(),
                          ),
                        );
                      },
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBaslik() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Hesap Oluştur',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Beslenme takibinize başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIlerlemeGostergesi() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _buildIlerlemeBubble(0, 'Hesap'),
          Expanded(
            child: Container(
              height: 2,
              color: _mevcutSayfa >= 1 ? Colors.blue : Colors.grey,
            ),
          ),
          _buildIlerlemeBubble(1, 'Bilgiler'),
        ],
      ),
    );
  }

  Widget _buildIlerlemeBubble(int index, String label) {
    bool aktif = _mevcutSayfa >= index;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: aktif ? Colors.blue : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: aktif
                ? Icon(Icons.check, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: aktif ? Colors.black87 : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHesapBilgileriSayfasi() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap Bilgileri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Adresi',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                                      validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email adresi gerekli';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Geçerli bir email adresi girin';
                    }
                    return null;
                  },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Şifre
                  TextFormField(
                    controller: _sifreController,
                    obscureText: _sifreGizli,
                    onChanged: (value) {
                      setState(() {
                        // Şifre gücü kontrolü basitleştirildi
                        _sifreGucu = {
                          'seviye': value.length >= 8 ? 'Güçlü' : value.length >= 6 ? 'Orta' : 'Zayıf'
                        };
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_sifreGizli ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _sifreGizli = !_sifreGizli;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                  
                  // Şifre gücü göstergesi
                  if (_sifreGucu != null) _buildSifreGucuGostergesi(),
                  
                  SizedBox(height: 16),
                  
                  // Şifre tekrar
                  TextFormField(
                    controller: _sifreTekrarController,
                    obscureText: _sifreTekrarGizli,
                    decoration: InputDecoration(
                      labelText: 'Şifre Tekrar',
                      prefixIcon: Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_sifreTekrarGizli ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _sifreTekrarGizli = !_sifreTekrarGizli;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre tekrarı gerekli';
                      }
                      if (value != _sifreController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSifreGucuGostergesi() {
    final gucu = _sifreGucu!;
    Color renk;
    
    switch (gucu['seviye']) {
      case 'Zayıf':
        renk = Colors.red;
        break;
      case 'Orta':
        renk = Colors.orange;
        break;
      case 'Güçlü':
        renk = Colors.green;
        break;
      default:
        renk = Colors.grey;
    }
    
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Şifre Gücü: '),
              Text(
                gucu['seviye'],
                style: TextStyle(
                  color: renk,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: gucu['puan'] / 5.0,
            backgroundColor: Colors.grey[300],
            color: renk,
          ),
        ],
      ),
    );
  }

  Widget _buildKisiselBilgilerSayfasi() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _kisiselFormKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kişisel Bilgiler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              SizedBox(height: 24),
              
              // İsim
              TextFormField(
                controller: _isimController,
                decoration: InputDecoration(
                  labelText: 'İsim Soyisim',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              Text(
                'Cinsiyet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Erkek'),
                      value: true,
                      groupValue: _erkekMi,
                      onChanged: (value) {
                        setState(() {
                          _erkekMi = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Kadın'),
                      value: false,
                      groupValue: _erkekMi,
                      onChanged: (value) {
                        setState(() {
                          _erkekMi = value!;
                        });
                      },
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Boy gerekli';
                        }
                        final boy = double.tryParse(value);
                        if (boy == null || boy < 100 || boy > 250) {
                          return 'Geçerli boy girin';
                        }
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kilo gerekli';
                        }
                        final kilo = double.tryParse(value);
                        if (kilo == null || kilo < 30 || kilo > 300) {
                          return 'Geçerli kilo girin';
                        }
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Yaş gerekli';
                        }
                        final yas = int.tryParse(value);
                        if (yas == null || yas < 10 || yas > 120) {
                          return 'Geçerli yaş girin';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Aktivite seviyesi
              Text(
                'Aktivite Seviyesi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _aktiviteSeviyesi,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Sedanter (Hareketsiz)')),
                  DropdownMenuItem(value: 2, child: Text('Az Aktif (Haftada 1-3 gün)')),
                  DropdownMenuItem(value: 3, child: Text('Orta Aktif (Haftada 3-5 gün)')),
                  DropdownMenuItem(value: 4, child: Text('Aktif (Haftada 6-7 gün)')),
                  DropdownMenuItem(value: 5, child: Text('Çok Aktif (Günde 2 kez)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _aktiviteSeviyesi = value!;
                  });
                },
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigasyonButonlari() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _oncekiSayfa,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_mevcutSayfa == 0 ? 'Geri' : 'Önceki'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                print('Hesap Oluştur/İleri butonuna tıklandı - Sayfa: $_mevcutSayfa');
                _sonrakiSayfa();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
              ),
              child: Text(
                _mevcutSayfa == 1 ? 'Hesap Oluştur' : 'İleri',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 