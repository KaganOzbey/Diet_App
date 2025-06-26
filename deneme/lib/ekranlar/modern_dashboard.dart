import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import '../hizmetler/firebase_auth_servisi.dart';
import '../modeller/kullanici_modeli.dart';
import '../modeller/yemek_ogesi_modeli.dart';
import '../modeller/ogun_girisi_modeli.dart';
import '../modeller/gunluk_beslenme_modeli.dart';
import '../veriler/mega_besin_veritabani.dart';
import '../servisler/tema_servisi.dart';
import '../hizmetler/kilo_analiz_servisi.dart';
import '../hizmetler/beslenme_analiz_servisi.dart';
import 'istatistikler_ekrani.dart';
import 'profil_yonetimi_ekrani.dart';
import 'detayli_analiz_ekrani.dart';
import 'oneriler_ekrani.dart';
import 'ozel_besin_ekleme_ekrani.dart';
import 'kilo_giris_ekrani.dart';
import '../widgets/grafikler/kilo_takip_grafigi.dart';

class ModernDashboard extends StatefulWidget {
  final double bmr;

  const ModernDashboard({Key? key, required this.bmr}) : super(key: key);

   _ModernDashboardState createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  KullaniciModeli? currentUser;
  GunlukBeslenmeModeli? todayNutrition;
  List<OgunGirisiModeli> todayMeals = [];
  
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String selectedMealType = "Kahvaltı";
  
  // Su ve adım takibi için yeni değişkenler
  int dailyWaterIntake = 0; // ml cinsinden
  int dailySteps = 0;
  final int dailyWaterGoal = 2500; // 2.5 litre hedef
  final int dailyStepsGoal = 10000; // 10k adım hedef
  
  // Kilo takibi değişkenleri
  double? currentWeight;
  double? weeklyWeightChange;
  double? monthlyWeightChange;
  
  // Analiz sonuçları
  Map<String, dynamic>? _kaloriAnalizi;
  Map<String, dynamic>? _beslenmeSkoru;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
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
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    try {
      print('ModernDashboard: Kullanıcı verileri yükleniyor...');
      
      // Firebase Auth aktifse önce Firebase kullanıcısını kontrol et
      final firebaseUser = FirebaseAuthServisi.mevcutKullanici;
      if (firebaseUser != null) {
        // Firebase kullanıcısı var, email'e göre profil verilerini bul
        final kullanici = await VeriTabaniServisi.kullaniciIdileBul(firebaseUser.email!);
        if (kullanici != null) {
          print('ModernDashboard: Firebase kullanıcı profili bulundu: ${kullanici.email}');
          setState(() {
            currentUser = kullanici;
          });
          _loadTodayData();
          return;
        }
      }
      
      // Demo kullanıcısını kontrol et (demo mode aktifse)
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        print('ModernDashboard: Demo kullanıcı bulundu - Kilo: ${demoKullanici.kilo}');
        setState(() {
          currentUser = demoKullanici;
        });
        _loadTodayData();
        return;
      }
      
      // Son çare olarak aktif kullanıcıyı veritabanından yükle
      final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (kullanici != null) {
        print('ModernDashboard: Veritabanından kullanıcı bulundu - Kilo: ${kullanici.kilo}');
        setState(() {
          currentUser = kullanici;
        });
        _loadTodayData();
        return;
      } else {
        print('ModernDashboard: HATA - Hiç kullanıcı bulunamadı');
      }
    } catch (e) {
      print('Kullanıcı veri yükleme hatası: $e');
    }
  }

  Future<void> _loadTodayData() async {
    if (currentUser == null) {
      print('ModernDashboard: _loadTodayData - currentUser null, çıkılıyor');
      return;
    }
    
    print('ModernDashboard: Günlük veriler yükleniyor... Kullanıcı kilo: ${currentUser!.kilo}');
    
    final bugun = DateTime.now();
    final ogunGirisleri = VeriTabaniServisi.gunlukOgunGirisleriniGetir(currentUser!.id, bugun);
    final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(currentUser!.id, bugun);
    
    // Kilo verilerini yükle
    final kiloIstatistikleri = VeriTabaniServisi.kiloIstatistikleriniGetir(currentUser!.id);
    print('ModernDashboard: Kilo istatistikleri: $kiloIstatistikleri');
    
    // Kilo analizi yap
    final kaloriAnalizi = await KiloAnalizServisi.kaloriDengesiAnaliziYap(currentUser!.id, bugun);
    
    // Gerçek beslenme skoru hesapla
    final beslenmeSkoru = await BeslenmeAnalizServisi.gunlukBeslenmeSkoruHesapla(currentUser!.id, bugun);
    
    setState(() {
      todayMeals = ogunGirisleri;
      todayNutrition = gunlukBeslenme;
      currentWeight = kiloIstatistikleri['mevcutKilo'];
      weeklyWeightChange = kiloIstatistikleri['haftalikDegisim'];
      monthlyWeightChange = kiloIstatistikleri['aylikDegisim'];
      
      // Analiz sonuçlarını kaydet
      _kaloriAnalizi = kaloriAnalizi;
      _beslenmeSkoru = beslenmeSkoru;
    });
    
    print('ModernDashboard: setState tamamlandı - currentWeight: $currentWeight');
  }

  // Su ve adım takibi fonksiyonları
  void _addWater(int amount) {
    setState(() {
      dailyWaterIntake += amount;
      if (dailyWaterIntake > dailyWaterGoal * 2) {
        dailyWaterIntake = dailyWaterGoal * 2;
      }
    });
  }

  void _removeWater(int amount) {
    setState(() {
      dailyWaterIntake -= amount;
      if (dailyWaterIntake < 0) {
        dailyWaterIntake = 0;
      }
    });
  }

  void _addSteps(int amount) {
    setState(() {
      dailySteps += amount;
      if (dailySteps > dailyStepsGoal * 3) {
        dailySteps = dailyStepsGoal * 3;
      }
    });
  }

  void _removeSteps(int amount) {
    setState(() {
      dailySteps -= amount;
      if (dailySteps < 0) {
        dailySteps = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        return Scaffold(
          backgroundColor: temaServisi.isDarkMode ? Color(0xFF1A1A1A) : null,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: temaServisi.backgroundGradient,
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDashboardTab(temaServisi),
                            _buildFoodSearchTab(temaServisi),
                            _buildStatsTab(temaServisi),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildModernBottomNav(temaServisi),
        );
      },
    );
  }

  Widget _buildDashboardTab(TemaServisi temaServisi) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildModernHeader(temaServisi),
          SizedBox(height: 20),
          _buildDailyStatsCards(temaServisi),
          SizedBox(height: 20),
          _buildWeightTrackingCard(temaServisi),
          SizedBox(height: 20),
          _buildWaterAndStepsCards(temaServisi),
          SizedBox(height: 20),
          _buildMealTimesCard(temaServisi),
          SizedBox(height: 20),
          _buildTodayMealsCard(temaServisi),
          SizedBox(height: 20),
          _buildQuickActionsCard(temaServisi),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickAddFoodCard(TemaServisi temaServisi) {
    return GestureDetector(
      onTap: () async {
        final sonuc = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OzelBesinEklemeEkrani()),
        );
        if (sonuc == true) {
          // Dashboard verilerini yeniden yükle
          await _loadUserData();
          setState(() {}); // UI'ı güncelle
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Özel besin başarıyla eklendi!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF5722),
            Color(0xFFFF7043),
            Color(0xFFFF8A65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF5722).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_circle,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özel Besin Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kendi yemeklerinizi uygulamaya ekleyin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildModernHeader(TemaServisi temaServisi) {
    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 10),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: temaServisi.isDarkMode 
            ? [
                Color(0xFF2E7D32),
                Color(0xFF388E3C),
                Color(0xFF43A047),
              ]
            : [
                Color(0xFF4CAF50),
                Color(0xFF66BB6A),
                Color(0xFF81C784),
              ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    currentUser?.isim ?? 'Kullanıcı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Dark mode toggle butonu
                  Container(
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        temaServisi.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        temaServisi.toggleTheme();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  temaServisi.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  temaServisi.isDarkMode 
                                    ? '🌙 Koyu tema aktifleştirildi' 
                                    : '☀️ Açık tema aktifleştirildi',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            backgroundColor: temaServisi.isDarkMode ? Colors.grey[800] : Colors.green[600],
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      tooltip: temaServisi.isDarkMode ? 'Açık Tema' : 'Koyu Tema',
                    ),
                  ),
                  // Profil avatarı
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilYonetimiEkrani()),
                        );
                      },
                      tooltip: 'Profil Yönetimi',
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatsCards(TemaServisi temaServisi) {
    final kaloriYuzdesi = todayNutrition != null && widget.bmr > 0 
        ? (todayNutrition!.toplamKalori / widget.bmr).clamp(0.0, 1.0) 
        : 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: temaServisi.isDarkMode 
                  ? [
                      Color(0xFF1976D2),
                      Color(0xFF1E88E5),
                      Color(0xFF2196F3),
                    ]
                  : [
                      Color(0xFF2196F3),
                      Color(0xFF42A5F5),
                      Color(0xFF64B5F6),
                    ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Günlük Kalori',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                CircularPercentIndicator(
                  radius: 80,
                  lineWidth: 12,
                  percent: kaloriYuzdesi,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${todayNutrition?.toplamKalori.round() ?? 0}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/ ${widget.bmr.round()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1200,
                ),
                
                SizedBox(height: 20),
                
                Text(
                  '%${(kaloriYuzdesi * 100).round()} Kullanıldı',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  'Protein',
                  '${todayNutrition?.toplamProtein.round() ?? 0}g',
                  Icons.fitness_center,
                  [Color(0xFFFF9800), Color(0xFFFFB74D)],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  'Karbonhidrat',
                  '${todayNutrition?.toplamKarbonhidrat.round() ?? 0}g',
                  Icons.rice_bowl,
                  [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  'Yağ',
                  '${todayNutrition?.toplamYag.round() ?? 0}g',
                  Icons.opacity,
                  [Color(0xFFFFC107), Color(0xFFFFD54F)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String title, String value, IconData icon, List<Color> gradient) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterAndStepsCards(TemaServisi temaServisi) {
    final waterPercent = (dailyWaterIntake / dailyWaterGoal).clamp(0.0, 1.0);
    final stepsPercent = (dailySteps / dailyStepsGoal).clamp(0.0, 1.0);
    
    return Row(
      children: [
        // Su Takibi Kartı
        Expanded(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00BCD4),
                  Color(0xFF26C6DA),
                  Color(0xFF4DD0E1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Su Miktarı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.local_drink,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 8,
                  percent: waterPercent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(dailyWaterIntake / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(waterPercent * 100).round()}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                
                SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _addWater(250),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      '${dailyWaterIntake}ml',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeWater(250),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.remove, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(width: 16),
        
        // Adım Sayacı Kartı
        Expanded(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE91E63),
                  Color(0xFFF06292),
                  Color(0xFFf8BBD9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adımlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.directions_walk,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 8,
                  percent: stepsPercent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(dailySteps / 1000).toStringAsFixed(1)}k',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(stepsPercent * 100).round()}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                
                SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _addSteps(1000),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      '$dailySteps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeSteps(1000),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.remove, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTimesCard(TemaServisi temaServisi) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: temaServisi.isDarkMode ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: temaServisi.isDarkMode 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Öğünler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: temaServisi.isDarkMode ? Color(0xFFF0F0F0) : Color(0xFF2D3748),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Her öğünü alt alta göster
          _buildMealTimeSection('Kahvaltı', Icons.free_breakfast, Color(0xFF4CAF50)),
          SizedBox(height: 12),
          _buildMealTimeSection('Öğle Yemeği', Icons.lunch_dining, Color(0xFFFF9800)),
          SizedBox(height: 12),
          _buildMealTimeSection('Akşam Yemeği', Icons.dinner_dining, Color(0xFF9C27B0)),
          SizedBox(height: 12),
          _buildMealTimeSection('Atıştırmalık', Icons.fastfood, Color(0xFFFFC107)),
          
          SizedBox(height: 16),
          
          // Özel Besin Ekleme Kartı
          _buildQuickAddFoodCard(temaServisi),
        ],
      ),
    );
  }

  Widget _buildMealTimeSection(String mealType, IconData icon, Color color) {
    final mealItems = todayMeals.where((meal) => meal.ogunTipi == mealType).toList();
    
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: temaServisi.isDarkMode ? Color(0xFF2D2D30) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Öğün başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${mealItems.length} besin eklendi',
                      style: TextStyle(
                        color: temaServisi.isDarkMode ? Color(0xFFBDBDBD) : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (mealItems.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${mealItems.fold<double>(0, (sum, meal) => sum + meal.kalori).round()} kcal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          // Besinleri göster
          if (mealItems.isNotEmpty) ...[
            SizedBox(height: 12),
            ...mealItems.map((meal) => _buildMealFoodItem(meal, color)).toList(),
          ] else ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: temaServisi.isDarkMode ? Color(0xFF8E8E93) : Colors.grey[400],
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Besin eklemek için ara butonunu kullan',
                    style: TextStyle(
                      color: temaServisi.isDarkMode ? Color(0xFF8E8E93) : Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildMealFoodItem(OgunGirisiModeli meal, Color color) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: temaServisi.isDarkMode ? Color(0xFF3D3D40) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 18,
            ),
          ),
          
          SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                  Text(
                  meal.yemekIsmi,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: temaServisi.isDarkMode ? Color(0xFFF0F0F0) : Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${meal.tuketilenGram.round()}g',
                  style: TextStyle(
                    fontSize: 12,
                    color: temaServisi.isDarkMode ? Color(0xFFBDBDBD) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${meal.kalori.round()} kcal',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTodayMealsCard(TemaServisi temaServisi) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: temaServisi.isDarkMode ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: temaServisi.isDarkMode 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bugünkü Yemekler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: temaServisi.isDarkMode ? Color(0xFFF0F0F0) : Color(0xFF2D3748),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${todayMeals.length} öğün',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          if (todayMeals.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 48,
                    color: temaServisi.isDarkMode ? Color(0xFF8E8E93) : Colors.grey[400],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Henüz yemek eklenmemiş',
                    style: TextStyle(
                      color: temaServisi.isDarkMode ? Color(0xFFBDBDBD) : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: todayMeals.take(3).map((meal) => _buildMealItem(meal)).toList(),
            ),
          
          if (todayMeals.length > 3)
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text(
                  '${todayMeals.length - 3} yemek daha göster',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealItem(OgunGirisiModeli meal) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) => Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: temaServisi.isDarkMode ? Color(0xFF3A3A3C) : Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: temaServisi.isDarkMode ? Color(0xFF404040) : Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMealIcon(meal.ogunTipi),
                color: Colors.white,
                size: 24,
              ),
            ),
            
            SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.yemekIsmi,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: temaServisi.isDarkMode ? Color(0xFFF0F0F0) : Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${meal.tuketilenGram.round()}g • ${meal.ogunTipi}',
                    style: TextStyle(
                      fontSize: 14,
                      color: temaServisi.isDarkMode ? Color(0xFFBDBDBD) : Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.kalori.round()} kcal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(meal.kayitTarihi),
                  style: TextStyle(
                    fontSize: 12,
                    color: temaServisi.isDarkMode ? Color(0xFFBDBDBD) : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Kahvaltı':
        return Icons.free_breakfast;
      case 'Öğle Yemeği':
        return Icons.lunch_dining;
      case 'Akşam Yemeği':
        return Icons.dinner_dining;
      default:
        return Icons.fastfood;
    }
  }

  Widget _buildQuickActionsCard(TemaServisi temaServisi) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: temaServisi.isDarkMode ? Color(0xFF2D2D30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: temaServisi.isDarkMode 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı İşlemler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: temaServisi.isDarkMode ? Color(0xFFF0F0F0) : Color(0xFF2D3748),
            ),
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Besin Ara',
                  Icons.search,
                  Color(0xFF4CAF50),
                  () => _tabController.animateTo(1),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'İstatistikler',
                  Icons.analytics,
                  Color(0xFF2196F3),
                  () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Detaylı Analiz',
                  Icons.assessment,
                  Color(0xFF9C27B0),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetayliAnalizEkrani(),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Öneriler',
                  Icons.lightbulb,
                  Color(0xFFFF9800),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnerilerEkrani(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          

          
          SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            child: _buildQuickActionButton(
              'Hedef Güncelle',
              Icons.track_changes,
              Color(0xFFFFC107),
              () => _showGoalUpdateDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodSearchTab(TemaServisi temaServisi) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: temaServisi.isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(temaServisi.isDarkMode ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchFood,
              style: TextStyle(
                color: temaServisi.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Yemek ara...',
                hintStyle: TextStyle(
                  color: temaServisi.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xFF4CAF50)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: temaServisi.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Yemek aramak için yukarıdaki\narama kutusunu kullanın',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: temaServisi.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final food = searchResults[index] as YemekOgesiModeli;
                      return _buildFoodSearchItem(food, temaServisi);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSearchItem(YemekOgesiModeli food, TemaServisi temaServisi) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: temaServisi.isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(temaServisi.isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.isim,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: temaServisi.isDarkMode ? Colors.white : Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${food.yuzGramKalori.round()} kcal / 100g',
                  style: TextStyle(
                    fontSize: 14,
                    color: temaServisi.isDarkMode ? Colors.grey[400] : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          
          GestureDetector(
            onTap: () => _addMealEntry(food),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(TemaServisi temaServisi) {
    return IstatistiklerEkrani();
  }

  Widget _buildModernBottomNav(TemaServisi temaServisi) {
    return Container(
      decoration: BoxDecoration(
        color: temaServisi.isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(temaServisi.isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Icon(Icons.dashboard),
            text: 'Ana Sayfa',
          ),
          Tab(
            icon: Icon(Icons.search),
            text: 'Ara',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'İstatistik',
          ),
        ],
        labelColor: Color(0xFF4CAF50),
        unselectedLabelColor: temaServisi.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        indicatorColor: Color(0xFF4CAF50),
        indicatorWeight: 3,
      ),
    );
  }

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final kapsamliBesinler = MegaBesinVeritabani.besinAra(query);
      
      for (final besinAdi in kapsamliBesinler) {
        final besinDegerleri = MegaBesinVeritabani.tumBesinler[besinAdi];
        
        final mevcutBesin = VeriTabaniServisi.fdcIdIleYemekOgesiBul(besinAdi.hashCode);
        if (mevcutBesin == null && besinDegerleri != null) {
          try {
            await VeriTabaniServisi.yemekOgesiKaydet(
              isim: besinAdi.substring(0, 1).toUpperCase() + besinAdi.substring(1),
              fdcId: besinAdi.hashCode,
              yuzGramKalori: besinDegerleri['k']!.toDouble(),
              yuzGramProtein: besinDegerleri['p']!.toDouble(),
              yuzGramKarbonhidrat: besinDegerleri['c']!.toDouble(),
              yuzGramYag: besinDegerleri['y']!.toDouble(),
              yuzGramLif: besinDegerleri['l']?.toDouble() ?? 0.0,
              kategori: 'Türk Mutfağı',
            );
          } catch (e) {
            // Hata varsa devam et
          }
        }
      }
      
      final guncelSonuclar = VeriTabaniServisi.isimIleYemekAra(query);
      setState(() {
        searchResults = guncelSonuclar;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama hatası: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Hedef güncelleme dialog'u
  Future<void> _showGoalUpdateDialog() async {
    if (currentUser == null) return;

    final kaloriHedefiController = TextEditingController(
                      text: currentUser!.gunlukKaloriHedefi.round().toString()
    );
    final proteinHedefiController = TextEditingController(
                      text: (currentUser!.gunlukKaloriHedefi * 0.3 / 4).round().toString() // Varsayılan %30 protein
    );
    final karbonhidratHedefiController = TextEditingController(
                      text: (currentUser!.gunlukKaloriHedefi * 0.45 / 4).round().toString() // Varsayılan %45 karbonhidrat
    );
    final yagHedefiController = TextEditingController(
                      text: (currentUser!.gunlukKaloriHedefi * 0.25 / 9).round().toString() // Varsayılan %25 yağ
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.track_changes, color: Color(0xFF4CAF50)),
            SizedBox(width: 12),
            Text(
              'Hedefleri Güncelle',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Color(0xFF4CAF50)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Günlük beslenme hedeflerinizi güncelleyebilirsiniz',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),

              // Kalori Hedefi
              TextField(
                controller: kaloriHedefiController,
                decoration: InputDecoration(
                  labelText: 'Günlük Kalori Hedefi (kcal)',
                  prefixIcon: Icon(Icons.local_fire_department, color: Color(0xFF4CAF50)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              
              SizedBox(height: 16),

              // Protein Hedefi
              TextField(
                controller: proteinHedefiController,
                decoration: InputDecoration(
                  labelText: 'Günlük Protein Hedefi (g)',
                  prefixIcon: Icon(Icons.fitness_center, color: Color(0xFFFF9800)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFF9800)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              
              SizedBox(height: 16),

              // Karbonhidrat Hedefi
              TextField(
                controller: karbonhidratHedefiController,
                decoration: InputDecoration(
                  labelText: 'Günlük Karbonhidrat Hedefi (g)',
                  prefixIcon: Icon(Icons.rice_bowl, color: Color(0xFF9C27B0)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF9C27B0)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              
              SizedBox(height: 16),

              // Yağ Hedefi
              TextField(
                controller: yagHedefiController,
                decoration: InputDecoration(
                  labelText: 'Günlük Yağ Hedefi (g)',
                  prefixIcon: Icon(Icons.opacity, color: Color(0xFFFFC107)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFFC107)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Güncelle',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final yeniKaloriHedefi = double.tryParse(kaloriHedefiController.text) ?? currentUser!.gunlukKaloriHedefi;
        
        // Kullanıcının kalori hedefini güncelle
        currentUser!.gunlukKaloriHedefi = yeniKaloriHedefi;
        
        // Veritabanını güncelle
        await currentUser!.save();
        
        // UI'yi güncelle
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Hedefler başarıyla güncellendi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Güncelleme hatası: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _addMealEntry(dynamic foodData) async {
    if (currentUser == null) return;

    final yemekOgesi = foodData as YemekOgesiModeli;
    
    final besinVerisi = MegaBesinVeritabani.tumBesinler[yemekOgesi.isim.toLowerCase()];
    String varsayilanOlcu = besinVerisi?['o'] ?? 'gram';
    int gramKarsiligi = besinVerisi?['g'] ?? 100;
    
    final miktarController = TextEditingController(text: '1');
    String secilenOlcu = varsayilanOlcu;
    
    // Dropdown için benzersiz değerler oluştur
    List<String> olcuSecenekleri = [];
    if (varsayilanOlcu != 'gram' && varsayilanOlcu.isNotEmpty) {
      olcuSecenekleri.add(varsayilanOlcu);
    }
    if (!olcuSecenekleri.contains('gram')) {
      olcuSecenekleri.add('gram');
    }
    
    // Eğer seçilen ölçü mevcut seçeneklerde yoksa, ilk seçeneği kullan
    if (!olcuSecenekleri.contains(secilenOlcu)) {
      secilenOlcu = olcuSecenekleri.first;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Miktar Belirle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                yemekOgesi.isim,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: miktarController,
                      decoration: InputDecoration(
                        labelText: 'Miktar',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: secilenOlcu,
                      decoration: InputDecoration(
                        labelText: 'Ölçü',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: olcuSecenekleri.map((olcu) => 
                        DropdownMenuItem(value: olcu, child: Text(olcu))
                      ).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          secilenOlcu = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: selectedMealType,
                decoration: InputDecoration(
                  labelText: 'Öğün',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Atıştırmalık']
                    .map((meal) => DropdownMenuItem(value: meal, child: Text(meal)))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedMealType = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final miktar = double.tryParse(miktarController.text) ?? 1.0;
        double gramMiktar = miktar;
        
        if (secilenOlcu != 'gram') {
          gramMiktar = miktar * gramKarsiligi;
        }
        
        await VeriTabaniServisi.ogunGirisiEkle(
          kullaniciId: currentUser!.id,
          yemekOgesi: yemekOgesi,
          gramMiktari: gramMiktar,
          ogunTipi: selectedMealType,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${yemekOgesi.isim} başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadTodayData();
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWeightTrackingCard(TemaServisi temaServisi) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: temaServisi.isDarkMode 
            ? [
                Color(0xFF673AB7),
                Color(0xFF7E57C2),
                Color(0xFF9575CD),
              ]
            : [
                Color(0xFF3F51B5),
                Color(0xFF5C6BC0),
                Color(0xFF7986CB),
              ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3F51B5).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.scale, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kilo Takibi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Güncel kilonuz ve değişim',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _tabController.animateTo(2), // İstatistikler sekmesine git
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.analytics, color: Colors.white, size: 20),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      print('ModernDashboard: Kilo giriş ekranına gidiliyor...');
                      final sonuc = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => KiloGirisEkrani()),
                      );
                      print('ModernDashboard: Kilo giriş ekranından dönüldü, sonuç: $sonuc');
                      if (sonuc == true) {
                        print('ModernDashboard: Veriler yeniden yükleniyor...');
                        await _loadUserData(); // Verileri yeniden yükle
                        await _loadTodayData(); // Günlük verileri de yeniden yükle
                        print('ModernDashboard: Tüm veriler yenilendi');
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mevcut Kilo',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currentWeight != null && currentWeight! > 0
                            ? '${currentWeight!.toStringAsFixed(1)} kg'
                            : '${currentUser?.kilo.toStringAsFixed(1) ?? '0.0'} kg',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haftalık Değişim',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            weeklyWeightChange != null
                                ? (weeklyWeightChange! > 0 
                                    ? Icons.trending_up 
                                    : weeklyWeightChange! < 0 
                                        ? Icons.trending_down 
                                        : Icons.trending_flat)
                                : Icons.trending_flat,
                            color: weeklyWeightChange != null
                                ? (weeklyWeightChange! > 0 
                                    ? Colors.orange 
                                    : weeklyWeightChange! < 0 
                                        ? Colors.green 
                                        : Colors.white)
                                : Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            weeklyWeightChange != null
                                ? '${weeklyWeightChange!.toStringAsFixed(1)} kg'
                                : '0.0 kg',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Kilo takibi mini grafiği
          Container(
            height: 120,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: currentUser != null 
              ? _buildKiloMiniGrafigi()
              : Center(
                  child: Text(
                    'Grafik için kilo verisi bekleniyor...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
          ),
          
          SizedBox(height: 12),
          
          // Kalori dengesi analizi
          if (_kaloriAnalizi != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getKaloriIcon(_kaloriAnalizi!['durum']),
                        color: _getKaloriRengi(_kaloriAnalizi!['durum']),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kalori Dengesi: ${_kaloriAnalizi!['durum']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_kaloriAnalizi!['kaloriDengesi'].toStringAsFixed(0)} kcal denge',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  if (_kaloriAnalizi!['tahminKiloEtkisi'] != 0.0) ...[
                    Text(
                      'Tahmin: ${_kaloriAnalizi!['tahminKiloEtkisi'].toStringAsFixed(3)} kg etki',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
          ],

          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white.withOpacity(0.8), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    monthlyWeightChange != null
                        ? 'Son ay: ${monthlyWeightChange!.toStringAsFixed(1)} kg değişim'
                        : 'Düzenli kilo takibi için kilo girişi yapın',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kilo mini grafiği
  Widget _buildKiloMiniGrafigi() {
    if (currentUser == null) return Container();
    
    // Kullanıcının mevcut kilosu
    final mevcutKilo = currentUser!.kilo;
    
    // Basit bir trend simülasyonu (gerçek veriler yoksa)
    final List<double> kiloTrendi = _generateKiloTrendi(mevcutKilo);
    
    return Column(
      children: [
        // Grafik başlığı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son 7 Gün Trendi',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${mevcutKilo.toStringAsFixed(1)} kg',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        // Mini grafik
        Expanded(
          child: kiloTrendi.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_weight, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Veri Kaydı Başlayın',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomPaint(
                  painter: KiloMiniGrafikPainter(kiloTrendi),
                  child: Container(),
                ),
        ),
        
        SizedBox(height: 8),
        
        // Alt bilgi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '7 gün önce',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
            Text(
              'Bugün',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Kilo trendi verisi oluştur
  List<double> _generateKiloTrendi(double mevcutKilo) {
    // Gerçek kilo girişlerini kontrol et
    if (currentUser != null) {
      final kiloGirisleri = VeriTabaniServisi.haftalikKiloVerileriniGetir(currentUser!.id);
      if (kiloGirisleri.isNotEmpty) {
        // Gerçek veriler varsa onları kullan
        return kiloGirisleri.map((giris) => giris.kilo).toList();
      }
    }
    
    // Gerçek veri yoksa sadece mevcut kiloyu göster
    return [mevcutKilo]; // Tek nokta - rastgele veri üretmeyin
  }

  // Kilo analizi için yardımcı metodlar
  Color _getKaloriRengi(String durum) {
    switch (durum) {
      case 'Dengede':
        return Colors.green;
      case 'Açık':
        return Colors.orange;
      case 'Fazla':
        return Colors.red;
      default:
        return Colors.white;
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
}

// Custom Painter sınıfı - mini kilo grafiği için
class KiloMiniGrafikPainter extends CustomPainter {
  final List<double> kiloVerileri;
  
  KiloMiniGrafikPainter(this.kiloVerileri);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (kiloVerileri.isEmpty) return;
    
    // Çizgi için paint
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Gölge için paint
    final shadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Nokta için paint
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Min ve max değerleri bul
    final minKilo = kiloVerileri.reduce((a, b) => a < b ? a : b);
    final maxKilo = kiloVerileri.reduce((a, b) => a > b ? a : b);
    final kiloAraligi = maxKilo - minKilo;
    
    // Eğer aralık çok küçükse, biraz genişlet
    final normalizeEdilmisAralik = kiloAraligi < 1.0 ? 1.0 : kiloAraligi;
    
    // Koordinatları hesapla
    final List<Offset> points = [];
    final List<Offset> shadowPoints = [];
    
    for (int i = 0; i < kiloVerileri.length; i++) {
      // Tek veri noktası varsa ortaya koy, çoklu veri varsa normale dağıt
      final x = kiloVerileri.length == 1 
          ? size.width / 2 
          : (i / (kiloVerileri.length - 1)) * size.width;
      
      // Tek veri noktası varsa Y'yi de ortala, çoklu veri varsa normal hesapla
      final y = kiloVerileri.length == 1
          ? size.height / 2
          : size.height - ((kiloVerileri[i] - minKilo) / normalizeEdilmisAralik * size.height * 0.8) - (size.height * 0.1);
      
      points.add(Offset(x, y));
      shadowPoints.add(Offset(x, y));
    }
    
    // Gölge alanı çiz
    if (shadowPoints.isNotEmpty) {
      final shadowPath = Path();
      shadowPath.moveTo(shadowPoints.first.dx, size.height);
      
      for (final point in shadowPoints) {
        shadowPath.lineTo(point.dx, point.dy);
      }
      
      shadowPath.lineTo(shadowPoints.last.dx, size.height);
      shadowPath.close();
      
      canvas.drawPath(shadowPath, shadowPaint);
    }
    
    // Çizgiyi çiz
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      canvas.drawPath(path, linePaint);
    }
    
    // Tek nokta özel durumu - yatay çizgi olarak göster
    if (points.length == 1) {
      final point = points.first;
      final lineY = point.dy;
      
      // Yatay çizgi çiz (soldan sağa)
      canvas.drawLine(
        Offset(0, lineY),
        Offset(size.width, lineY),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
      );
      
      // Çizgi üzerinde vurgu noktaları
      for (double x = size.width * 0.2; x <= size.width * 0.8; x += size.width * 0.2) {
        canvas.drawCircle(Offset(x, lineY), 4.0, Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(x, lineY), 4.0, Paint()
          ..color = Colors.purple[300]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke);
      }
    } else {
      // Çoklu nokta durumu - normal boyutlarda
      for (final point in points) {
        canvas.drawCircle(point, 3.0, dotPaint);
      }
      
      // Son noktayı vurgula
      if (points.isNotEmpty) {
        final lastPoint = points.last;
        canvas.drawCircle(lastPoint, 5.0, Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
        canvas.drawCircle(lastPoint, 5.0, Paint()
          ..color = Colors.purple[300]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 