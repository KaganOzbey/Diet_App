import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'hizmetler/veri_tabani_servisi.dart';
import 'hizmetler/firebase_auth_servisi.dart';
import 'servisler/tema_servisi.dart';
import 'ekranlar/splash_ekrani.dart';
import 'modeller/kullanici_modeli.dart';
import 'servisler/yerel_veritabani_servisi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Türkçe tarih formatlaması için locale verilerini başlat
    await initializeDateFormatting('tr_TR', null);
    
    // Hive veritabanını başlat
    await VeriTabaniServisi.baslat();
    print('Veritabanı başlatıldı');
    
    // Demo kullanıcı oturumunu yükle
    await FirebaseAuthServisi.demoOturumuYukle();
    print('Demo oturum yükleme tamamlandı');
    
    runApp(
      ChangeNotifierProvider(
        create: (context) => TemaServisi(),
        child: DietApp(),
      ),
    );
  } catch (e) {
    print('Uygulama başlatma hatası: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Uygulama başlatılamadı: $e'),
        ),
      ),
    ));
  }
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
