import '../veriler/mega_besin_veritabani.dart';

class BesinServisi {
  // Yemek arama işlemi - Türkçe isimlere göre arama yapar
  static Future<String?> yemekAra(String yemekAdi) async {
    try {
      // Mega besin veritabanından ara
      for (var entry in MegaBesinVeritabani.tumBesinler.entries) {
        if (entry.key.toLowerCase().contains(yemekAdi.toLowerCase())) {
          return entry.key; // Besin adını ID olarak döndür
        }
      }
      
      // Eğer bulunamazsa null döndür
      return null;
    } catch (e) {
      print('Yemek arama hatası: $e');
      return null;
    }
  }

  // Kalori bilgisini getir (100g başına)
  static Future<double?> kaloriGetir(String besinAdi) async {
    try {
      // Besin adına göre besini bul
      final besinVerisi = MegaBesinVeritabani.tumBesinler[besinAdi];
      
      if (besinVerisi != null) {
        return besinVerisi['k']?.toDouble();
      }
      
      return null;
    } catch (e) {
      print('Kalori getirme hatası: $e');
      return null;
    }
  }

  // Besin detaylarını getir
  static Future<Map<String, dynamic>?> besinDetayGetir(String besinAdi) async {
    try {
      final besinVerisi = MegaBesinVeritabani.tumBesinler[besinAdi];
      
      if (besinVerisi != null) {
        return {
          'isim': besinAdi,
          'besinDegerleri': {
            'kalori': besinVerisi['k'],
            'protein': besinVerisi['p'],
            'karbonhidrat': besinVerisi['c'],
            'yag': besinVerisi['y'],
            'lif': besinVerisi['l'],
            'olcu': besinVerisi['o'],
            'gramKarsiligi': besinVerisi['g']
          },
        };
      }
      
      return null;
    } catch (e) {
      print('Besin detay getirme hatası: $e');
      return null;
    }
  }

  // Popüler besinleri getir
  static List<Map<String, dynamic>> populerBesinleriGetir() {
    final populerBesinler = MegaBesinVeritabani.populerBesinler;
    return populerBesinler.map((besinAdi) {
      final besinVerisi = MegaBesinVeritabani.tumBesinler[besinAdi];
      return {
        'isim': besinAdi,
        'besinDegerleri': {
          'kalori': besinVerisi?['k'],
          'protein': besinVerisi?['p'],
          'karbonhidrat': besinVerisi?['c'],
          'yag': besinVerisi?['y'],
          'lif': besinVerisi?['l'],
          'olcu': besinVerisi?['o'],
          'gramKarsiligi': besinVerisi?['g']
        },
      };
    }).toList();
  }

  // Kategoriye göre besinleri getir
  static List<Map<String, dynamic>> kategoriyeGoreBesinleriGetir(String kategori) {
    final tumBesinler = MegaBesinVeritabani.tumBesinler;
    List<Map<String, dynamic>> kategoriBesinleri = [];
    
    tumBesinler.forEach((besinAdi, besinVerisi) {
      kategoriBesinleri.add({
        'isim': besinAdi,
        'besinDegerleri': {
          'kalori': besinVerisi['k'],
          'protein': besinVerisi['p'],
          'karbonhidrat': besinVerisi['c'],
          'yag': besinVerisi['y'],
          'lif': besinVerisi['l'],
          'olcu': besinVerisi['o'],
          'gramKarsiligi': besinVerisi['g']
        },
      });
    });
    
    return kategoriBesinleri;
  }
  
  // Yeni eklenen yardımcı fonksiyonlar
  static List<String> besinAra(String arama) {
    return MegaBesinVeritabani.besinAra(arama);
  }
  
  static Map<String, dynamic>? besinBilgisiGetir(String besinAdi) {
    return MegaBesinVeritabani.tumBesinler[besinAdi];
  }
  
  static int get toplamBesinSayisi => MegaBesinVeritabani.toplamBesinSayisi;
  
  static Map<String, int> get kategoriSayilari => MegaBesinVeritabani.kategoriSayilari;
}
