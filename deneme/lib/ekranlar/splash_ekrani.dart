import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../hizmetler/firebase_auth_servisi.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import 'onboarding_ekrani.dart';
import 'modern_dashboard.dart';

class SplashEkrani extends StatefulWidget {
  @override
  _SplashEkraniState createState() => _SplashEkraniState();
}

class _SplashEkraniState extends State<SplashEkrani> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    // Status bar'ı gizle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _setupAnimations();
    _startSplashSequence();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlide = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startSplashSequence() async {
    // Logo animasyonu
    await _logoController.forward();
    
    // Text animasyonu
    await _textController.forward();
    
    // Biraz bekle
    await Future.delayed(Duration(milliseconds: 1000));
    
    // Kullanıcı kontrolü ve yönlendirme
    await _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    try {
      // Demo kullanıcısını kontrol et
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        _navigateToMain(demoKullanici.gunlukKaloriHedefi);
        return;
      }
      
      // Yerel kullanıcıyı kontrol et
      final mevcutKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (mevcutKullanici != null) {
        _navigateToMain(mevcutKullanici.gunlukKaloriHedefi);
        return;
      }
      
      // İlk kez açılıyorsa onboarding'e git
      _navigateToOnboarding();
      
    } catch (e) {
      // Hata durumunda onboarding'e git
      _navigateToOnboarding();
    }
  }

  void _navigateToMain(double bmr) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => ModernDashboard(bmr: bmr),
        transitionDuration: Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => OnboardingEkrani(),
        transitionDuration: Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF81C784),
              Color(0xFF66BB6A),
              Color(0xFF4CAF50),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: 60,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Animated Text
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _textSlide,
                            child: Opacity(
                              opacity: _textOpacity.value,
                              child: Column(
                                children: [
                                  Text(
                                    'Beslenme Takip',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  Text(
                                    'Sağlıklı yaşamın anahtarı',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Loading indicator
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
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

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
        overlays: SystemUiOverlay.values);
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }
} 