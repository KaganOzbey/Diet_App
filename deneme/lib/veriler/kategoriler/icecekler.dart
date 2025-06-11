// İçecekler Veritabanı - 50+ çeşit içecek
class IceceklerVeritabani {
  static const Map<String, Map<String, dynamic>> icecekler = {
    // SICAK İÇECEKLER
    'çay': {'k': 2, 'p': 0, 'c': 0.7, 'y': 0, 'l': 0, 'o': 'fincan', 'g': 240},
    'türk kahvesi': {'k': 7, 'p': 0.1, 'c': 1.6, 'y': 0, 'l': 0, 'o': 'fincan', 'g': 60},
    'nescafe': {'k': 25, 'p': 1.5, 'c': 4, 'y': 0.5, 'l': 0, 'o': 'fincan', 'g': 200},
    'cappuccino': {'k': 80, 'p': 4, 'c': 8, 'y': 4, 'l': 0, 'o': 'fincan', 'g': 180},
    'latte': {'k': 120, 'p': 6, 'c': 12, 'y': 6, 'l': 0, 'o': 'fincan', 'g': 240},
    'espresso': {'k': 5, 'p': 0.3, 'c': 1, 'y': 0, 'l': 0, 'o': 'fincan', 'g': 30},
    'americano': {'k': 15, 'p': 2, 'c': 3, 'y': 0.2, 'l': 0, 'o': 'fincan', 'g': 200},
    'macchiato': {'k': 13, 'p': 0.8, 'c': 1.6, 'y': 0.5, 'l': 0, 'o': 'fincan', 'g': 60},
    'mocha': {'k': 394, 'p': 13, 'c': 35, 'y': 23, 'l': 4, 'o': 'fincan', 'g': 240},
    'chai latte': {'k': 120, 'p': 4, 'c': 23, 'y': 2, 'l': 0, 'o': 'fincan', 'g': 240},
    'yeşil çay': {'k': 2, 'p': 0.5, 'c': 0, 'y': 0, 'l': 0, 'o': 'fincan', 'g': 240},
    'bitki çayı': {'k': 2, 'p': 0.1, 'c': 0.4, 'y': 0, 'l': 0, 'o': 'fincan', 'g': 240},
    'oolong çayı': {'k': 2, 'p': 0, 'c': 0.7, 'y': 0, 'l': 0, 'o': 'fincan', 'g': 240},
    'earl grey': {'k': 3, 'p': 0, 'c': 0.7, 'y': 0, 'l': 0, 'o': 'fincan', 'g': 240},
    'sıcak çikolata': {'k': 192, 'p': 9, 'c': 27, 'y': 7, 'l': 3, 'o': 'fincan', 'g': 240},
    'salep': {'k': 140, 'p': 4, 'c': 28, 'y': 2, 'l': 1, 'o': 'fincan', 'g': 200},
    
    // SOĞUK İÇECEKLER
    'su': {'k': 0, 'p': 0, 'c': 0, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'maden suyu': {'k': 0, 'p': 0, 'c': 0, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'buzlu çay': {'k': 70, 'p': 0, 'c': 18, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'buzlu kahve': {'k': 165, 'p': 6, 'c': 26, 'y': 5, 'l': 0, 'o': 'bardak', 'g': 240},
    'frappuccino': {'k': 240, 'p': 4, 'c': 50, 'y': 3.5, 'l': 0, 'o': 'bardak', 'g': 355},
    
    // MEYVE SULARI
    'portakal suyu': {'k': 45, 'p': 0.7, 'c': 10.4, 'y': 0.2, 'l': 0.2, 'o': 'bardak', 'g': 240},
    'elma suyu': {'k': 46, 'p': 0.1, 'c': 11.3, 'y': 0.1, 'l': 0.2, 'o': 'bardak', 'g': 240},
    'üzüm suyu': {'k': 60, 'p': 0.6, 'c': 14.7, 'y': 0.2, 'l': 0.1, 'o': 'bardak', 'g': 240},
    'vişne suyu': {'k': 46, 'p': 0.5, 'c': 11.6, 'y': 0.1, 'l': 0.5, 'o': 'bardak', 'g': 240},
    'nar suyu': {'k': 53, 'p': 0.4, 'c': 13.7, 'y': 0.3, 'l': 0.1, 'o': 'bardak', 'g': 240},
    'ananas suyu': {'k': 53, 'p': 0.4, 'c': 12.9, 'y': 0.1, 'l': 0.5, 'o': 'bardak', 'g': 240},
    'greyfurt suyu': {'k': 39, 'p': 0.5, 'c': 9.2, 'y': 0.1, 'l': 0.1, 'o': 'bardak', 'g': 240},
    'limon suyu': {'k': 22, 'p': 0.4, 'c': 6.9, 'y': 0.2, 'l': 0.4, 'o': 'bardak', 'g': 240},
    'karışık meyve suyu': {'k': 56, 'p': 0.5, 'c': 13.8, 'y': 0.1, 'l': 0.5, 'o': 'bardak', 'g': 240},
    'domates suyu': {'k': 17, 'p': 0.8, 'c': 4.2, 'y': 0.1, 'l': 0.4, 'o': 'bardak', 'g': 240},
    'havuç suyu': {'k': 38, 'p': 0.9, 'c': 8.8, 'y': 0.1, 'l': 0.8, 'o': 'bardak', 'g': 240},
    
    // GAZLI İÇECEKLER
    'cola': {'k': 39, 'p': 0, 'c': 10.6, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'fanta': {'k': 44, 'p': 0, 'c': 11.6, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'sprite': {'k': 38, 'p': 0, 'c': 10, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'gazoz': {'k': 34, 'p': 0, 'c': 9, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'tonik': {'k': 33, 'p': 0, 'c': 8.8, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'soda': {'k': 0, 'p': 0, 'c': 0, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'enerji içeceği': {'k': 45, 'p': 0, 'c': 11, 'y': 0, 'l': 0, 'o': 'kutu', 'g': 250},
    'red bull': {'k': 45, 'p': 1, 'c': 11, 'y': 0, 'l': 0, 'o': 'kutu', 'g': 250},
    
    // SÜT BAZLI İÇECEKLER
    'ayran': {'k': 36, 'p': 1.4, 'c': 2.9, 'y': 1.8, 'l': 0, 'o': 'bardak', 'g': 200},
    'kefir': {'k': 54, 'p': 3.1, 'c': 4.8, 'y': 2.5, 'l': 0, 'o': 'bardak', 'g': 200},
    'lassi': {'k': 60, 'p': 2.4, 'c': 9, 'y': 1.5, 'l': 0, 'o': 'bardak', 'g': 200},
    'milkshake vanilyalı': {'k': 254, 'p': 8, 'c': 40, 'y': 8, 'l': 0, 'o': 'bardak', 'g': 300},
    'milkshake çikolatalı': {'k': 356, 'p': 10, 'c': 63, 'y': 8, 'l': 2, 'o': 'bardak', 'g': 300},
    'milkshake çilekli': {'k': 283, 'p': 8, 'c': 51, 'y': 6, 'l': 1, 'o': 'bardak', 'g': 300},
    
    // SMOOTHIE VE DETOKS
    'yeşil smoothie': {'k': 145, 'p': 2, 'c': 36, 'y': 0.5, 'l': 4, 'o': 'bardak', 'g': 240},
    'meyve smoothie': {'k': 145, 'p': 2, 'c': 36, 'y': 0.5, 'l': 4, 'o': 'bardak', 'g': 240},
    'protein smoothie': {'k': 103, 'p': 20, 'c': 3, 'y': 1, 'l': 1, 'o': 'bardak', 'g': 240},
    'detoks suyu': {'k': 30, 'p': 0.5, 'c': 7, 'y': 0.1, 'l': 1, 'o': 'bardak', 'g': 240},
    
    // GELENEKSEL TÜRK İÇECEKLERİ
    'şalgam': {'k': 15, 'p': 0.5, 'c': 3, 'y': 0.1, 'l': 0.8, 'o': 'bardak', 'g': 200},
    'boza': {'k': 90, 'p': 1.5, 'c': 18, 'y': 1, 'l': 0.5, 'o': 'bardak', 'g': 200},
    'tahin şerbeti': {'k': 120, 'p': 3, 'c': 15, 'y': 6, 'l': 2, 'o': 'bardak', 'g': 200},
    'limonata': {'k': 50, 'p': 0.1, 'c': 13, 'y': 0, 'l': 0.1, 'o': 'bardak', 'g': 240},
    'şerbet': {'k': 160, 'p': 0, 'c': 40, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 200},
    
    // ALKOLLÜ İÇECEKLER (ölçülü tüketim için)
    'bira': {'k': 43, 'p': 0.5, 'c': 3.6, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'şarap kırmızı': {'k': 85, 'p': 0.1, 'c': 2.6, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 150},
    'şarap beyaz': {'k': 82, 'p': 0.1, 'c': 2.6, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 150},
    'rakı': {'k': 231, 'p': 0, 'c': 0, 'y': 0, 'l': 0, 'o': 'kadeh', 'g': 30},
    
    // SPORTİF İÇECEKLER
    'isotonic içecek': {'k': 25, 'p': 0, 'c': 6, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'protein shake': {'k': 103, 'p': 20, 'c': 3, 'y': 1, 'l': 1, 'o': 'bardak', 'g': 240},
    'bcaa içeceği': {'k': 15, 'p': 2.5, 'c': 0, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
    'kreatin içeceği': {'k': 5, 'p': 0, 'c': 1, 'y': 0, 'l': 0, 'o': 'bardak', 'g': 240},
  };
} 