// Mega Besin Veritabanı - 500+ Besin
import 'kategoriler/icecekler.dart';
import 'kategoriler/et_ve_balik.dart';
import 'kategoriler/sebzeler.dart';
import 'kategoriler/meyveler.dart';
import 'kategoriler/tahillar.dart';
import 'kategoriler/sut_urunleri.dart';
import 'kategoriler/kuruyemisler.dart';
import 'kategoriler/fast_food.dart';
import 'kategoriler/turk_yemekleri.dart';

class MegaBesinVeritabani {
  static Map<String, Map<String, dynamic>> get tumBesinler {
    final Map<String, Map<String, dynamic>> birlesikVeri = {};
    
    // Tüm kategorileri birleştir
    birlesikVeri.addAll(IceceklerVeritabani.icecekler);
    birlesikVeri.addAll(EtVeBalikVeritabani.etVeBalik);
    birlesikVeri.addAll(SebzelerVeritabani.sebzeler);
    birlesikVeri.addAll(MeyvelerVeritabani.meyveler);
    birlesikVeri.addAll(TahillarVeritabani.tahillar);
    birlesikVeri.addAll(SutUrunleriVeritabani.sutUrunleri);
    birlesikVeri.addAll(KuruyemislerVeritabani.kuruyemisler);
    birlesikVeri.addAll(FastFoodVeritabani.fastFood);
    birlesikVeri.addAll(TurkYemekleriVeritabani.turkYemekleri);
    
    return birlesikVeri;
  }

  // Kategoriye göre besinleri getir
  static Map<String, Map<String, dynamic>> kategoriGetir(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'içecekler':
        return IceceklerVeritabani.icecekler;
      case 'et ve balık':
        return EtVeBalikVeritabani.etVeBalik;
      case 'sebzeler':
        return SebzelerVeritabani.sebzeler;
      case 'meyveler':
        return MeyvelerVeritabani.meyveler;
      case 'tahıllar':
        return TahillarVeritabani.tahillar;
      case 'süt ürünleri':
        return SutUrunleriVeritabani.sutUrunleri;
      case 'kuruyemişler':
        return KuruyemislerVeritabani.kuruyemisler;
      case 'fast food':
        return FastFoodVeritabani.fastFood;
      case 'türk yemekleri':
        return TurkYemekleriVeritabani.turkYemekleri;
      default:
        return tumBesinler;
    }
  }

  // Besin sayısı bilgisi
  static int get toplamBesinSayisi => tumBesinler.length;
  
  static Map<String, int> get kategoriSayilari => {
    'İçecekler': IceceklerVeritabani.icecekler.length,
    'Et ve Balık': EtVeBalikVeritabani.etVeBalik.length,
    'Sebzeler': SebzelerVeritabani.sebzeler.length,
    'Meyveler': MeyvelerVeritabani.meyveler.length,
    'Tahıllar': TahillarVeritabani.tahillar.length,
    'Süt Ürünleri': SutUrunleriVeritabani.sutUrunleri.length,
    'Kuruyemişler': KuruyemislerVeritabani.kuruyemisler.length,
    'Fast Food': FastFoodVeritabani.fastFood.length,
    'Türk Yemekleri': TurkYemekleriVeritabani.turkYemekleri.length,
  };

  // Popüler besinler
  static List<String> get populerBesinler => [
    'çay', 'kahve', 'su', 'ayran', 'cola',
    'tavuk göğsü', 'yumurta', 'salmon', 'ton balığı',
    'pirinç', 'bulgur', 'makarna', 'ekmek', 'patates',
    'domates', 'salatalık', 'soğan', 'havuç', 'marul',
    'elma', 'muz', 'portakal', 'üzüm', 'çilek',
    'süt', 'yoğurt', 'peynir', 'tereyağı',
    'ceviz', 'badem', 'fındık', 'fıstık',
    'pilav', 'köfte', 'mantı', 'börek', 'döner',
    'pizza', 'hamburger', 'patates kızartması',
  ];

  // Arama fonksiyonu
  static List<String> besinAra(String arama) {
    if (arama.isEmpty) return populerBesinler;
    
    final aranan = arama.toLowerCase().trim();
    final sonuclar = <String>[];
    
    for (final besin in tumBesinler.keys) {
      if (besin.toLowerCase().contains(aranan)) {
        sonuclar.add(besin);
      }
    }
    
    // Tam eşleşmeleri öne çıkar
    sonuclar.sort((a, b) {
      final aBaslangic = a.toLowerCase().startsWith(aranan);
      final bBaslangic = b.toLowerCase().startsWith(aranan);
      
      if (aBaslangic && !bBaslangic) return -1;
      if (!aBaslangic && bBaslangic) return 1;
      return a.compareTo(b);
    });
    
    return sonuclar.take(20).toList();
  }
} 