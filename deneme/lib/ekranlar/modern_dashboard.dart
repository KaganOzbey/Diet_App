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
import 'istatistikler_ekrani.dart';
import 'profil_yonetimi_ekrani.dart';
import 'detayli_analiz_ekrani.dart';
import 'oneriler_ekrani.dart';

class ModernDashboard extends StatefulWidget {
  final double bmr;

  const ModernDashboard({Key? key, required this.bmr}) : super(key: key);

  @override
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
      final demoKullanici = FirebaseAuthServisi.demomMevcutKullanici;
      if (demoKullanici != null) {
        setState(() {
          currentUser = demoKullanici;
        });
        _loadTodayData();
        return;
      }
      
      final kullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (kullanici != null) {
        setState(() {
          currentUser = kullanici;
        });
        _loadTodayData();
        return;
      }
    } catch (e) {
      print('Kullanıcı veri yükleme hatası: $e');
    }
  }

  void _loadTodayData() {
    if (currentUser == null) return;
    
    final bugun = DateTime.now();
    final ogunGirisleri = VeriTabaniServisi.gunlukOgunGirisleriniGetir(currentUser!.id, bugun);
    final gunlukBeslenme = VeriTabaniServisi.gunlukBeslenmeGetir(currentUser!.id, bugun);
    
    setState(() {
      todayMeals = ogunGirisleri;
      todayNutrition = gunlukBeslenme;
    });
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
        await VeriTabaniServisi.kullaniciGuncelle(currentUser!);
        
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
} 