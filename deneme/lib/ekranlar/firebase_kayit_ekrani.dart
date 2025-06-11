import 'package:flutter/material.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../widgets/yukleme_gostergesi.dart';
import 'firebase_giris_ekrani.dart';

class FirebaseKayitEkrani extends StatefulWidget {
  @override
  _FirebaseKayitEkraniState createState() => _FirebaseKayitEkraniState();
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
  bool _sifreGosteriliyor = false;
  bool _sifreTekrarGosteriliyor = false;
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
    print('_kayitOl çağrıldı');
    
    // İlk sayfa bilgilerini manuel kontrol et (form dispose edildiği için)
    print('İlk sayfa bilgileri kontrol ediliyor...');
    if (_emailController.text.isEmpty || !FirebaseAuthServisi.emailGecerliMi(_emailController.text)) {
      print('Email validation başarısız');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçerli bir email adresi gerekli')),
      );
      return;
    }
    
    if (_sifreController.text.length < 6) {
      print('Şifre validation başarısız');
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
    
    print('İlk sayfa validation başarılı');
    
    // Kişisel form validation
    print('Kişisel form validation yapılıyor...');
    if (!_kisiselFormKey.currentState!.validate()) {
      print('Kişisel form validation başarısız');
      return;
    }
    print('Kişisel form validation başarılı');
    
    print('Tüm validasyonlar geçti! Firebase kayıt başlatılıyor...');
    print('Email: ${_emailController.text}');
    print('İsim: ${_isimController.text}');
    print('Boy: ${_boyController.text}');
    print('Kilo: ${_kiloController.text}');
    print('Yaş: ${_yasController.text}');
    print('Cinsiyet: ${_erkekMi ? "Erkek" : "Kadın"}');
    print('Aktivite: $_aktiviteSeviyesi');
    
    setState(() => _yukleniyor = true);

    final basarili = await FirebaseAuthServisi.emailIleKayitOl(
      context: context,
      email: _emailController.text.trim(),
      sifre: _sifreController.text,
      isim: _isimController.text.trim(),
      boy: double.parse(_boyController.text),
      kilo: double.parse(_kiloController.text),
      yas: int.parse(_yasController.text),
      erkekMi: _erkekMi,
      aktiviteSeviyesi: _aktiviteSeviyesi,
    );

    setState(() => _yukleniyor = false);

    if (basarili && mounted) {
      _basariliKayitDialogGoster();
    }
  }

  void _basariliKayitDialogGoster() {
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
          !FirebaseAuthServisi.emailGecerliMi(_emailController.text)) {
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
                    mesaj: 'Hesap oluşturuluyor...',
                    renk: Colors.white,
                  ),
                )
              : _buildKayitFormu(),
        ),
      ),
    );
  }

  Widget _buildKayitFormu() {
    return Column(
      children: [
        // Başlık
        _buildBaslik(),
        
        // İlerleme göstergesi
        _buildIlerlemeGostergesi(),
        
        // Sayfa içeriği
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _mevcutSayfa = index;
              });
            },
            children: [
              _buildHesapBilgileriSayfasi(),
              _buildKisiselBilgilerSayfasi(),
            ],
          ),
        ),
        
        // Navigasyon butonları
        _buildNavigasyonButonlari(),
      ],
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
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Beslenme takibinize başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
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
              color: _mevcutSayfa >= 1 ? Colors.white : Colors.white30,
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
            color: aktif ? Colors.white : Colors.white30,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: aktif
                ? Icon(Icons.check, color: Colors.green)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: aktif ? Colors.white : Colors.white30,
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
                      color: Colors.green[700],
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
                      if (!FirebaseAuthServisi.emailGecerliMi(value)) {
                        return 'Geçerli bir email adresi girin';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Şifre
                  TextFormField(
                    controller: _sifreController,
                    obscureText: !_sifreGosteriliyor,
                    onChanged: (value) {
                      setState(() {
                        _sifreGucu = FirebaseAuthServisi.sifreGucluluguKontrol(value);
                      });
                    },
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
                    obscureText: !_sifreTekrarGosteriliyor,
                    decoration: InputDecoration(
                      labelText: 'Şifre Tekrar',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_sifreTekrarGosteriliyor ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _sifreTekrarGosteriliyor = !_sifreTekrarGosteriliyor;
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
                  color: Colors.green[700],
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
                foregroundColor: Colors.green[600],
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