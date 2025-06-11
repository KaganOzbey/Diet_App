import 'package:hive/hive.dart';
import '../modeller/kullanici_modeli.dart';

class YerelVeritabaniServisi {
  static const String _kullaniciBoxName = 'kullanici_box';
  
  // Kullanıcıyı kaydet
  static Future<void> kullaniciKaydet(KullaniciModeli kullanici) async {
    try {
      final box = await Hive.openBox<KullaniciModeli>(_kullaniciBoxName);
      await box.put('current_user', kullanici);
      print('Yerel veritabanı: Kullanıcı kaydedildi');
    } catch (e) {
      print('Kullanıcı kaydetme hatası: $e');
    }
  }
  
  // Kullanıcıyı getir
  static Future<KullaniciModeli?> kullaniciGetir() async {
    try {
      final box = await Hive.openBox<KullaniciModeli>(_kullaniciBoxName);
      final kullanici = box.get('current_user');
      print('Yerel veritabanı: Kullanıcı getirildi');
      return kullanici;
    } catch (e) {
      print('Kullanıcı getirme hatası: $e');
      return null;
    }
  }
  
  // Tüm kullanıcıları getir
  static Future<List<KullaniciModeli>> tumKullanicilariGetir() async {
    try {
      final box = await Hive.openBox<KullaniciModeli>(_kullaniciBoxName);
      final kullanicilar = box.values.toList();
      print('Yerel veritabanı: ${kullanicilar.length} kullanıcı getirildi');
      return kullanicilar;
    } catch (e) {
      print('Tüm kullanıcıları getirme hatası: $e');
      return [];
    }
  }
  
  // Email ile kullanıcı bul
  static Future<KullaniciModeli?> kullaniciIdileBul(String email) async {
    try {
      final kullanicilar = await tumKullanicilariGetir();
      return kullanicilar.firstWhere(
        (kullanici) => kullanici.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      print('Yerel veritabanında kullanıcı bulunamadı: $email');
      return null;
    }
  }
  
  // Kullanıcıyı güncelle
  static Future<void> kullaniciGuncelle(KullaniciModeli kullanici) async {
    await kullaniciKaydet(kullanici); // Aynı key'e kaydetmek güncelleme yapar
  }
  
  // Kullanıcıyı sil
  static Future<void> kullaniciSil() async {
    try {
      final box = await Hive.openBox<KullaniciModeli>(_kullaniciBoxName);
      await box.delete('current_user');
      print('Yerel veritabanı: Kullanıcı silindi');
    } catch (e) {
      print('Kullanıcı silme hatası: $e');
    }
  }
} 