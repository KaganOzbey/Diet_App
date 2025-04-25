import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // .env için import
import 'ekranlar/giris_ekrani.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter'ı başlatmak için
  await dotenv.load(fileName: ".env");        // .env dosyasını yükle
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Besin Analiz Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: GirisEkrani(),
    );
  }
}
