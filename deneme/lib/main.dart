import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hizmetler/veri_tabani_servisi.dart';
import 'hizmetler/firebase_auth_servisi.dart';
import 'servisler/tema_servisi.dart';
import 'ekranlar/splash_ekrani.dart';
import 'modeller/kullanici_modeli.dart';
import 'servisler/yerel_veritabani_servisi.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i doğru şekilde başlat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase başarıyla başlatıldı');
  } catch (e) {
    print('❌ Firebase başlatma hatası: $e');
  }
  
  // Hive'ı başlat
  await Hive.initFlutter();
  
  // Status bar ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Gerçek Firebase Auth kullanılıyor (emulator kapatıldı)
  print('✅ Firebase Auth gerçek sunucu ile hazır');
  
  // Türkçe tarih formatlaması için locale verilerini başlat
  await initializeDateFormatting('tr_TR', null);
  
  // Hive veritabanını başlat
  await VeriTabaniServisi.baslat();
  print('Veritabanı başlatıldı');
  
  // Firebase Auth aktif - gerçek authentication
  print('Firebase Auth aktif - network izinleri düzeltildi');
  
  // Mevcut kullanıcı varsa bilgilerini yenile
  try {
    final kullanici = FirebaseAuth.instance.currentUser;
    if (kullanici != null) {
      await kullanici.reload();
      print('✅ Mevcut kullanıcı bilgileri yenilendi - Email doğrulandı: ${kullanici.emailVerified}');
    }
  } catch (e) {
    print('⚠️ Kullanıcı bilgileri yenileme hatası (göz ardı edildi): $e');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => TemaServisi(),
      child: DietApp(),
    ),
  );
}

class DietApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        return MaterialApp(
          title: 'Beslenme Takibi',
          theme: TemaServisi.lightTheme,
          darkTheme: TemaServisi.darkTheme,
          themeMode: temaServisi.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: Locale('tr', 'TR'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
          ],
          home: _buildHome(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  Widget _buildHome() {
    // Her zaman splash screen ile başla
    return SplashEkrani();
  }
}
