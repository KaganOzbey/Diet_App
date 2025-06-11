import 'package:flutter/material.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../widgets/yukleme_gostergesi.dart';

class SifreSifirlamaEkrani extends StatefulWidget {
  @override
  _SifreSifirlamaEkraniState createState() => _SifreSifirlamaEkraniState();
}

class _SifreSifirlamaEkraniState extends State<SifreSifirlamaEkrani>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _yukleniyor = false;
  bool _emailGonderildi = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
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
    super.dispose();
  }

  Future<void> _sifreSifirlamaGonder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      await FirebaseAuthServisi.sifreSifirlamaEmailiGonder(
        context: context,
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _emailGonderildi = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
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
                    mesaj: 'Email gönderiliyor...',
                    renk: Colors.white,
                  ),
                )
              : _emailGonderildi
                  ? _buildBasariliEkrani()
                  : _buildSifirlamaFormu(),
        ),
      ),
    );
  }

  Widget _buildSifirlamaFormu() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              SizedBox(height: 40),
              
              // İkon ve başlık
              _buildBaslik(),
              
              SizedBox(height: 50),
              
              // Form kartı
              _buildFormKarti(),
              
              SizedBox(height: 32),
              
              // Geri dön linki
              _buildGeriDonLinki(),
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
            Icons.lock_reset,
            size: 50,
            color: Colors.green[600],
          ),
        ),
        
        SizedBox(height: 24),
        
        Text(
          'Şifre Sıfırlama',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 8),
        
        Text(
          'Email adresinize şifre sıfırlama\nbağlantısı gönderelim',
          textAlign: TextAlign.center,
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
        padding: EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _sifreSifirlamaGonder(),
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
                  helperText: 'Hesabınızla ilişkili email adresini girin',
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
              
              SizedBox(height: 32),
              
              // Gönder butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sifreSifirlamaGonder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Sıfırlama Bağlantısı Gönder',
                    style: TextStyle(
                      fontSize: 16,
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

  Widget _buildGeriDonLinki() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        'Giriş ekranına geri dön',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildBasariliEkrani() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başarı ikonu
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read,
                      size: 40,
                      color: Colors.green[600],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Başlık
                  Text(
                    'Email Gönderildi!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Açıklama
                  Text(
                    'Şifre sıfırlama bağlantısı email adresinize gönderildi. '
                    'Lütfen email\'inizi kontrol edin ve bağlantıya tıklayarak '
                    'yeni şifrenizi oluşturun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Butonlar
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Giriş Ekranına Dön',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _emailGonderildi = false;
                          });
                        },
                        child: Text(
                          'Tekrar Gönder',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 16,
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
      ),
    );
  }
} 