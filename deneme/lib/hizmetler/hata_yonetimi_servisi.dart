import 'package:flutter/material.dart';

enum HataTipi {
  ag,
  veritabani,
  kullanici,
  sistem,
  dogrulama,
}

class AppHatasi {
  final String mesaj;
  final HataTipi tip;
  final dynamic hataDetayi;
  final StackTrace? stackTrace;

  AppHatasi({
    required this.mesaj,
    required this.tip,
    this.hataDetayi,
    this.stackTrace,
  });
}

class HataYonetimiServisi {
  static final List<AppHatasi> _hatalarGecmisi = [];
  
  // Hata kaydet ve kullanıcıya göster
  static void hataYonet(
    BuildContext context,
    AppHatasi hata, {
    bool kullaniciGoster = true,
    bool konsolaYaz = true,
  }) {
    // Hatayı kaydet
    _hatalarGecmisi.add(hata);
    
    // Konsola yazdır
    if (konsolaYaz) {
      print('🔴 HATA [${hata.tip}]: ${hata.mesaj}');
      if (hata.hataDetayi != null) {
        print('   Detay: ${hata.hataDetayi}');
      }
      if (hata.stackTrace != null) {
        print('   Stack: ${hata.stackTrace}');
      }
    }
    
    // Kullanıcıya göster
    if (kullaniciGoster) {
      _kullaniciyaHataGoster(context, hata);
    }
  }
  
  static void _kullaniciyaHataGoster(BuildContext context, AppHatasi hata) {
    String kullaniciMesaji = _kullanicidostMesajOlustur(hata);
    Color renk = _hataTipineGoreRenk(hata.tip);
    IconData ikon = _hataTipineGoreIkon(hata.tip);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(ikon, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                kullaniciMesaji,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: renk,
        duration: Duration(seconds: 4),
        action: hata.tip == HataTipi.ag
            ? SnackBarAction(
                label: 'TEKRAR DENE',
                textColor: Colors.white,
                onPressed: () {
                  // Yeniden deneme mantığı burada olacak
                },
              )
            : null,
      ),
    );
  }
  
  static String _kullanicidostMesajOlustur(AppHatasi hata) {
    switch (hata.tip) {
      case HataTipi.ag:
        return 'İnternet bağlantısı problemi. Lütfen bağlantınızı kontrol edin.';
      case HataTipi.veritabani:
        return 'Veri kaydetme sorunu oluştu. Tekrar deneyin.';
      case HataTipi.kullanici:
        return hata.mesaj; // Kullanıcı hataları doğrudan gösterilir
      case HataTipi.sistem:
        return 'Beklenmeyen bir hata oluştu. Uygulama geliştiricisi bilgilendirildi.';
      case HataTipi.dogrulama:
        return hata.mesaj; // Doğrulama hataları doğrudan gösterilir
    }
  }
  
  static Color _hataTipineGoreRenk(HataTipi tip) {
    switch (tip) {
      case HataTipi.ag:
        return Colors.orange;
      case HataTipi.veritabani:
        return Colors.purple;
      case HataTipi.kullanici:
        return Colors.blue;
      case HataTipi.sistem:
        return Colors.red;
      case HataTipi.dogrulama:
        return Colors.amber;
    }
  }
  
  static IconData _hataTipineGoreIkon(HataTipi tip) {
    switch (tip) {
      case HataTipi.ag:
        return Icons.wifi_off;
      case HataTipi.veritabani:
        return Icons.storage;
      case HataTipi.kullanici:
        return Icons.person;
      case HataTipi.sistem:
        return Icons.error;
      case HataTipi.dogrulama:
        return Icons.warning;
    }
  }
  
  // Başarı mesajı göster
  static void basariMesaji(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(mesaj, style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // Bilgi mesajı göster
  static void bilgiMesaji(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text(mesaj, style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  // Hata geçmişini getir (debug için)
  static List<AppHatasi> get hatalarGecmisi => List.unmodifiable(_hatalarGecmisi);
  
  // Hata geçmişini temizle
  static void hatalarGecmisiniTemizle() {
    _hatalarGecmisi.clear();
  }
} 