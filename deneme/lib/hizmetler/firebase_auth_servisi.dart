import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../modeller/kullanici_modeli.dart';
import 'veri_tabani_servisi.dart';
import 'hata_yonetimi_servisi.dart';
import '../servisler/yerel_veritabani_servisi.dart';
import 'package:hive/hive.dart';

class FirebaseAuthServisi {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool demoMode = true; // Geçici demo mode (public olarak değiştirildi)

  // Demo mode için geçici kullanıcı bilgileri
  static final Map<String, String> _demoUsers = {};
  static KullaniciModeli? _currentDemoUser;
  
  // Mevcut kullanıcıyı getir
  static User? get mevcutKullanici => demoMode ? null : _auth.currentUser;
  
  // Demo kullanıcısını al
  static KullaniciModeli? get demomMevcutKullanici => demoMode ? _currentDemoUser : null;
  
  // Demo kullanıcı oturumunu başlat/yükle
  static Future<void> demoOturumuYukle() async {
    if (!demoMode) return;
    
    try {
      // Aktif kullanıcıyı VeriTabaniServisi'nden yükle
      final aktifKullanici = await VeriTabaniServisi.aktifKullaniciGetir();
      if (aktifKullanici != null) {
        _currentDemoUser = aktifKullanici;
        print('Demo oturum yüklendi: ${_currentDemoUser!.email}');
        
        // Demo users listesine ekle (şifre kontrolü için)
        _demoUsers[_currentDemoUser!.email] = 'demo_password';
      } else {
        print('Hiçbir aktif demo kullanıcı bulunamadı');
      }
    } catch (e) {
      print('Demo oturum yükleme hatası: $e');
    }
  }
  
  // Kullanıcı durumu stream'i
  static Stream<User?> get kullaniciDurumuStream => _auth.authStateChanges();
  
  // Email ile kayıt ol
  static Future<bool> emailIleKayitOl({
    required BuildContext context,
    required String email,
    required String sifre,
    required String isim,
    required double boy,
    required double kilo,
    required int yas,
    required bool erkekMi,
    required int aktiviteSeviyesi,
  }) async {
    try {
      if (demoMode) {
        print('DEMO MODE: Kayıt işlemi simüle ediliyor...');
        
        // Demo mode için basit kayıt
        if (_demoUsers.containsKey(email)) {
          _hataGoster(context, 'Bu email adresi zaten kullanılıyor');
          return false;
        }
        
        _demoUsers[email] = sifre;
        
        // VeriTabaniServisi kullanarak kullanıcı oluştur
        _currentDemoUser = await VeriTabaniServisi.kullaniciOlustur(
          email: email,
          isim: isim,
          boy: boy,
          kilo: kilo,
          yas: yas,
          erkekMi: erkekMi,
          aktiviteSeviyesi: aktiviteSeviyesi,
        );
        
        // Yerel veritabanına da kaydet (geri uyumluluk için)
        await YerelVeritabaniServisi.kullaniciKaydet(_currentDemoUser!);
        
        print('DEMO: Kullanıcı başarıyla kaydedildi - Her iki veritabanında da');
        return true;
      }

      // Gerçek Firebase Auth (API key geçerli olduğunda)
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: sifre,
      );

      // Email doğrulama gönder
      await userCredential.user!.sendEmailVerification();
      
      // Kullanıcı modelini oluştur ve kaydet
      final kullanici = await VeriTabaniServisi.kullaniciOlustur(
        email: email.trim(),
        isim: isim.trim(),
        boy: boy,
        kilo: kilo,
        yas: yas,
        erkekMi: erkekMi,
        aktiviteSeviyesi: aktiviteSeviyesi,
      );

      await YerelVeritabaniServisi.kullaniciKaydet(kullanici);
      
      print('Firebase Auth: Kullanıcı başarıyla kaydedildi');
      return true;
      
    } catch (e) {
      print('Kayıt hatası: $e');
      String hataMesaji = _hataMesajiCevir(e.toString());
      _hataGoster(context, hataMesaji);
      return false;
    }
  }
  
  // E-posta ile giriş yap
  static Future<bool> epostaIleGirisYap(String email, String sifre) async {
    try {
      print('Giriş denemesi - Email: $email');
      
      if (demoMode) {
        // Demo kullanıcı oturumu yükle
        await demoOturumuYukle();
        
        // Eğer mevcut demo kullanıcı varsa ve email eşleşiyorsa, direkt giriş yap
        if (_currentDemoUser != null && _currentDemoUser!.email == email) {
          print('Mevcut demo oturum bulundu: $email');
          return true;
        }
        
        // İlk olarak demo kullanıcılar listesini kontrol et
        // Eğer kullanıcı bu listede yoksa (silinmişse) giriş yapmasına izin verme
        if (!_demoUsers.containsKey(email)) {
          // Yerel veritabanından kontrol et (eski kullanıcılar için)
          final yerelKullanici = await YerelVeritabaniServisi.kullaniciIdileBul(email);
          if (yerelKullanici != null) {
            print('Yerel kullanıcı bulundu, VeriTabaniServisi\'ne taşınıyor: $email');
            
            // Kullanıcıyı VeriTabaniServisi'ne kaydet
            await VeriTabaniServisi.mevcutKullaniciKaydet(yerelKullanici);
            _currentDemoUser = yerelKullanici;
            
            // Demo users listesine ekle
            _demoUsers[email] = sifre;
            
            return true;
          }
          
          // Ne demo listesinde ne de yerel veritabanında bulunamadı
          throw Exception('Kullanıcı bulunamadı veya silinmiş');
        }
        
        // Demo kullanıcı listesinde var, VeriTabaniServisi'nden yükle
        print('Demo kullanıcı girişi yapılıyor: $email');
        
        final kullanici = await VeriTabaniServisi.kullaniciIdileBul(email);
        if (kullanici != null) {
          _currentDemoUser = kullanici;
          
          // Aktif kullanıcı olarak ayarla
          await VeriTabaniServisi.aktifKullaniciAyarla(kullanici);
          
          print('Demo kullanıcı başarıyla giriş yaptı: ${kullanici.email}');
          return true;
        } else {
          // Demo listesinde var ama VeriTabaniServisi'nde yok - veri tutarsızlığı
          print('Veri tutarsızlığı: Demo listesinde var ama veritabanında yok: $email');
          _demoUsers.remove(email); // Listeden de sil
          throw Exception('Kullanıcı verisi bulunamadı');
        }
      }
      
      // Firebase giriş (gerçek kullanıcılar için)
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: sifre,
      );
      
      print('Firebase giriş başarılı: ${userCredential.user?.email}');
      return true;
    } catch (e) {
      print('Giriş hatası: $e');
      throw Exception('Giriş yapılamadı: $e');
    }
  }
  
  // Şifre sıfırlama emaili gönder
  static Future<void> sifreSifirlamaEmailiGonder({
    required BuildContext context,
    required String email,
  }) async {
    try {
      if (demoMode) {
        print('DEMO MODE: Şifre sıfırlama emaili simüle ediliyor...');
        _basariliGoster(context, 'Demo modunda şifre sıfırlama emaili gönderildi');
        return;
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      _basariliGoster(context, 'Şifre sıfırlama emaili gönderildi');
    } catch (e) {
      String hataMesaji = _hataMesajiCevir(e.toString());
      _hataGoster(context, hataMesaji);
    }
  }
  
  // Email doğrulama tekrar gönder
  static Future<bool> emailDogrulamaTekrarGonder(BuildContext context) async {
    try {
      final kullanici = _auth.currentUser;
      if (kullanici != null && !kullanici.emailVerified) {
        await kullanici.sendEmailVerification();
        if (context.mounted) {
          HataYonetimiServisi.basariMesaji(
            context,
            'Doğrulama emaili tekrar gönderildi.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        HataYonetimiServisi.hataYonet(
          context,
          AppHatasi(
            mesaj: 'Email gönderilemedi: $e',
            tip: HataTipi.ag,
            hataDetayi: e,
          ),
        );
      }
    }
    return false;
  }
  
  // Şifre değiştir
  static Future<bool> sifreDegistir({
    required BuildContext context,
    required String mevcutSifre,
    required String yeniSifre,
  }) async {
    try {
      final kullanici = _auth.currentUser;
      if (kullanici == null || kullanici.email == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      // Önce kullanıcıyı mevcut şifresi ile doğrula
      final credential = EmailAuthProvider.credential(
        email: kullanici.email!,
        password: mevcutSifre,
      );
      
      await kullanici.reauthenticateWithCredential(credential);
      
      // Şifreyi değiştir
      await kullanici.updatePassword(yeniSifre);
      
      if (context.mounted) {
        HataYonetimiServisi.basariMesaji(
          context,
          'Şifre başarıyla değiştirildi.',
        );
      }
      
      return true;
      
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _firebaseHatasiniYonet(context, e);
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        HataYonetimiServisi.hataYonet(
          context,
          AppHatasi(
            mesaj: 'Şifre değiştirilemedi: $e',
            tip: HataTipi.sistem,
            hataDetayi: e,
          ),
        );
      }
      return false;
    }
  }
  
  // Çıkış yap
  static Future<void> cikisYap() async {
    if (demoMode) {
      _currentDemoUser = null;
      // Aktif kullanıcı ayarını da temizle
      final ayarlarKutusu = await Hive.openBox('ayarlar');
      await ayarlarKutusu.delete('aktifKullanici');
      print('DEMO: Çıkış yapıldı');
      return;
    }

    await _auth.signOut();
    print('Firebase Auth: Çıkış yapıldı');
  }

  // Hesabı sil
  static Future<bool> hesabiSil({
    required BuildContext context,
    required String sifre,
  }) async {
    try {
      if (demoMode) {
        // Demo mode'da hesap silme işlemi
        print('DEMO MODE: Hesap silme işlemi simüle ediliyor...');
        
        if (_currentDemoUser != null) {
          final kullaniciId = _currentDemoUser!.id;
          final kullaniciEmail = _currentDemoUser!.email;
          
          // Yerel veritabanından kullanıcıyı sil
          await VeriTabaniServisi.kullaniciSil(kullaniciId);
          
          // Demo users listesinden de sil
          _demoUsers.remove(kullaniciEmail);
          
          // Demo oturumunu temizle
          _currentDemoUser = null;
          
          // Aktif kullanıcı ayarını temizle
          final ayarlarKutusu = await Hive.openBox('ayarlar');
          await ayarlarKutusu.delete('aktifKullanici');
          
          // Yerel veritabanından da sil (eski veriler için)
          try {
            await YerelVeritabaniServisi.kullaniciSil();
          } catch (e) {
            // Yerel veritabanında bulunamadı, devam et
            print('Yerel veritabanından silme hatası: $e');
          }
          
          if (context.mounted) {
            HataYonetimiServisi.basariMesaji(
              context,
              'Hesap başarıyla silindi.',
            );
          }
          
          print('DEMO: Hesap başarıyla silindi - Email: $kullaniciEmail');
          return true;
        } else {
          throw Exception('Demo kullanıcı bulunamadı');
        }
      }
      
      // Firebase mode (gerçek kullanıcılar için)
      final kullanici = _auth.currentUser;
      if (kullanici == null || kullanici.email == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      // Önce kullanıcıyı yeniden doğrula
      final credential = EmailAuthProvider.credential(
        email: kullanici.email!,
        password: sifre,
      );
      
      await kullanici.reauthenticateWithCredential(credential);
      
      // Yerel veritabanından sil
      final tumKullanicilar = VeriTabaniServisi.tumKullanicilariGetir();
      try {
        final yerelKullanici = tumKullanicilar.firstWhere(
          (k) => k.email.toLowerCase() == kullanici.email!.toLowerCase(),
        );
        await VeriTabaniServisi.kullaniciSil(yerelKullanici.id);
      } catch (e) {
        // Yerel kullanıcı bulunamadı, devam et
      }
      
      // Firebase'den hesabı sil
      await kullanici.delete();
      
      if (context.mounted) {
        HataYonetimiServisi.basariMesaji(
          context,
          'Hesap başarıyla silindi.',
        );
      }
      
      return true;
      
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _firebaseHatasiniYonet(context, e);
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        HataYonetimiServisi.hataYonet(
          context,
          AppHatasi(
            mesaj: 'Hesap silinemedi: $e',
            tip: HataTipi.sistem,
            hataDetayi: e,
          ),
        );
      }
      return false;
    }
  }
  
  // Email doğrulandı mı kontrol et
  static bool get emailDogrulandi => _auth.currentUser?.emailVerified ?? false;
  
  // Kullanıcının email'ini yenile (doğrulama durumunu kontrol etmek için)
  static Future<void> kullaniciYenile() async {
    await _auth.currentUser?.reload();
  }
  
  // Yerel kullanıcıyı Firebase ile senkronize et
  static Future<void> _yerelKullaniciSenkronizeEt(User firebaseKullanici) async {
    final tumKullanicilar = VeriTabaniServisi.tumKullanicilariGetir();
    KullaniciModeli? yerelKullanici;
    
    try {
      yerelKullanici = tumKullanicilar.firstWhere(
        (k) => k.email.toLowerCase() == firebaseKullanici.email!.toLowerCase(),
      );
    } catch (e) {
      yerelKullanici = null;
    }
    
    if (yerelKullanici != null) {
      // Mevcut kullanıcıyı aktif olarak ayarla
      await VeriTabaniServisi.aktifKullaniciAyarla(yerelKullanici);
    } else {
      // Yeni kullanıcı için varsayılan verilerle oluştur
      // Bu durumda kullanıcıdan ek bilgi istenecek
      print('Yerel kullanıcı bulunamadı, ek bilgi gerekebilir');
    }
  }
  
  // Firebase hatalarını yönet
  static void _firebaseHatasiniYonet(BuildContext context, FirebaseAuthException e) {
    String mesaj;
    HataTipi tip;

    switch (e.code) {
      case 'weak-password':
        mesaj = 'Şifre çok zayıf. En az 6 karakter olmalı.';
        tip = HataTipi.kullanici;
        break;
      case 'email-already-in-use':
        mesaj = 'Bu email adresi zaten kullanımda.';
        tip = HataTipi.kullanici;
        break;
      case 'invalid-email':
        mesaj = 'Geçersiz email adresi.';
        tip = HataTipi.kullanici;
        break;
      case 'user-not-found':
        mesaj = 'Bu email ile kayıtlı kullanıcı bulunamadı.';
        tip = HataTipi.dogrulama;
        break;
      case 'wrong-password':
        mesaj = 'Şifre hatalı.';
        tip = HataTipi.dogrulama;
        break;
      case 'too-many-requests':
        mesaj = 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
        tip = HataTipi.sistem;
        break;
      case 'network-request-failed':
        mesaj = 'İnternet bağlantınızı kontrol edin.';
        tip = HataTipi.ag;
        break;
      default:
        mesaj = 'Bir hata oluştu: ${e.message}';
        tip = HataTipi.sistem;
    }

    HataYonetimiServisi.hataYonet(
      context,
      AppHatasi(
        mesaj: mesaj,
        tip: tip,
        hataDetayi: e,
      ),
    );
  }
  
  // Email format kontrolü
  static bool emailGecerliMi(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Şifre güçlülük kontrolü
  static Map<String, dynamic> sifreGucluluguKontrol(String sifre) {
    bool enAz8Karakter = sifre.length >= 8;
    bool buyukHarf = sifre.contains(RegExp(r'[A-Z]'));
    bool kucukHarf = sifre.contains(RegExp(r'[a-z]'));
    bool rakam = sifre.contains(RegExp(r'[0-9]'));
    bool ozelKarakter = sifre.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int puan = 0;
    if (enAz8Karakter) puan++;
    if (buyukHarf) puan++;
    if (kucukHarf) puan++;
    if (rakam) puan++;
    if (ozelKarakter) puan++;
    
    String seviye;
    if (puan <= 2) {
      seviye = 'Zayıf';
    } else if (puan <= 3) {
      seviye = 'Orta';
    } else {
      seviye = 'Güçlü';
    }
    
    return {
      'puan': puan,
      'seviye': seviye,
      'enAz8Karakter': enAz8Karakter,
      'buyukHarf': buyukHarf,
      'kucukHarf': kucukHarf,
      'rakam': rakam,
      'ozelKarakter': ozelKarakter,
    };
  }

  // Hata mesajını Türkçe'ye çevir
  static String _hataMesajiCevir(String hataKodu) {
    if (hataKodu.contains('weak-password')) {
      return 'Şifre çok zayıf. En az 6 karakter olmalı.';
    } else if (hataKodu.contains('email-already-in-use')) {
      return 'Bu email adresi zaten kullanımda.';
    } else if (hataKodu.contains('invalid-email')) {
      return 'Geçersiz email adresi.';
    } else if (hataKodu.contains('user-not-found')) {
      return 'Bu email ile kayıtlı kullanıcı bulunamadı.';
    } else if (hataKodu.contains('wrong-password')) {
      return 'Şifre hatalı.';
    } else if (hataKodu.contains('too-many-requests')) {
      return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
    } else if (hataKodu.contains('network')) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else {
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  // Hata mesajı göster
  static void _hataGoster(BuildContext context, String mesaj) {
    if (context.mounted) {
      HataYonetimiServisi.hataYonet(
        context,
        AppHatasi(
          mesaj: mesaj,
          tip: HataTipi.dogrulama,
        ),
      );
    }
  }

  // Başarı mesajı göster
  static void _basariliGoster(BuildContext context, String mesaj) {
    if (context.mounted) {
      HataYonetimiServisi.basariMesaji(context, mesaj);
    }
  }

  // Demo giriş metodu (şifre ile)
  static Future<bool> demoGiris({
    required String email,
    required String sifre,
  }) async {
    try {
      if (!demoMode) {
        throw Exception('Demo mode aktif değil');
      }
      
      print('DEMO: Giriş denemesi - Email: $email');
      
      // Kullanıcıyı veritabanında ara
      final tumKullanicilar = VeriTabaniServisi.tumKullanicilariGetir();
      KullaniciModeli? kullanici;
      
      try {
        kullanici = tumKullanicilar.firstWhere(
          (k) => k.email.toLowerCase() == email.toLowerCase(),
        );
      } catch (e) {
        throw Exception('Bu email adresi ile kayıtlı kullanıcı bulunamadı');
      }
      
      // Şifre kontrolü (demo'da şifreyi email'in ilk kısmı olarak kabul edelim)
      final beklenenSifre = email.split('@')[0]; // Örnek: test@gmail.com -> "test"
      if (sifre != beklenenSifre && sifre.length >= 6) {
        // Gerçek şifre de kabul edilsin
        print('DEMO: Şifre kabul edildi');
      } else if (sifre != beklenenSifre) {
        throw Exception('Şifre hatalı');
      }
      
      // Demo kullanıcısını aktif et
      _currentDemoUser = kullanici;
      
      // Aktif kullanıcı olarak ayarla
      await _aktifKullaniciAyarla(kullanici);
      
      print('DEMO: Giriş başarılı - ${kullanici.email}');
      return true;
      
    } catch (e) {
      print('DEMO: Giriş hatası - $e');
      throw e;
    }
  }

  // Demo kayıt metodu (şifre ile)
  static Future<bool> demoKayit({
    required String email,
    required String sifre,
    required String isim,
  }) async {
    try {
      if (!demoMode) {
        throw Exception('Demo mode aktif değil');
      }
      
      print('DEMO: Kayıt işlemi başlıyor - Email: $email, İsim: $isim');
      
      // Email formatını kontrol et
      if (!emailGecerliMi(email)) {
        throw Exception('Geçersiz email formatı');
      }
      
      // Şifre uzunluğunu kontrol et
      if (sifre.length < 6) {
        throw Exception('Şifre en az 6 karakter olmalı');
      }
      
      // Mevcut kullanıcıları kontrol et
      final tumKullanicilar = VeriTabaniServisi.tumKullanicilariGetir();
      final mevcutKullanici = tumKullanicilar.any(
        (k) => k.email.toLowerCase() == email.toLowerCase(),
      );
      
      if (mevcutKullanici) {
        throw Exception('Bu email adresi zaten kullanılıyor');
      }
      
      // Kullanıcıyı veritabanına kaydet
      await VeriTabaniServisi.kullaniciOlustur(
        email: email,
        isim: isim,
        boy: 170.0, // Varsayılan değer
        kilo: 70.0, // Varsayılan değer
        yas: 25, // Varsayılan değer
        erkekMi: true, // Varsayılan değer
        aktiviteSeviyesi: 2, // Varsayılan değer
      );
      
      // Demo kullanıcısını aktif et (yeni oluşturulan kullanıcıyı bul)
      final kullanicilar = VeriTabaniServisi.tumKullanicilariGetir();
      _currentDemoUser = kullanicilar.firstWhere(
        (k) => k.email.toLowerCase() == email.toLowerCase(),
      );
      
      print('DEMO: Kayıt başarılı - ${_currentDemoUser!.email}');
      return true;
      
    } catch (e) {
      print('DEMO: Kayıt hatası - $e');
      throw e;
    }
  }

  // Aktif kullanıcı ayarlama helper metodu
  static Future<void> _aktifKullaniciAyarla(KullaniciModeli kullanici) async {
    final ayarlarKutusu = await Hive.openBox('ayarlar');
    await ayarlarKutusu.put('aktifKullanici', kullanici.id);
    print('DEMO: Aktif kullanıcı ayarlandı: ${kullanici.email}');
  }
} 