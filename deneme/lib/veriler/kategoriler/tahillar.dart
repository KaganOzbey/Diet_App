// Tahıllar ve Karbonhidratlar Veritabanı - 40+ çeşit
class TahillarVeritabani {
  static const Map<String, Map<String, dynamic>> tahillar = {
    // PİRİNÇ ÇEŞİTLERİ
    'beyaz pirinç': {'k': 130, 'p': 2.7, 'c': 28, 'y': 0.3, 'l': 0.4, 'o': 'kase', 'g': 100},
    'esmer pirinç': {'k': 111, 'p': 2.6, 'c': 23, 'y': 0.9, 'l': 1.8, 'o': 'kase', 'g': 100},
    'basmati pirinç': {'k': 121, 'p': 3, 'c': 25, 'y': 0.4, 'l': 0.6, 'o': 'kase', 'g': 100},
    'jasmine pirinç': {'k': 129, 'p': 2.9, 'c': 28, 'y': 0.2, 'l': 0.5, 'o': 'kase', 'g': 100},
    'yaban pirinci': {'k': 101, 'p': 4, 'c': 21, 'y': 0.3, 'l': 1.7, 'o': 'kase', 'g': 100},
    'glutensiz pirinç': {'k': 130, 'p': 2.7, 'c': 28, 'y': 0.3, 'l': 0.4, 'o': 'kase', 'g': 100},
    
    // BULGUR ÇEŞİTLERİ
    'ince bulgur': {'k': 83, 'p': 3, 'c': 17, 'y': 0.2, 'l': 4.5, 'o': 'kase', 'g': 100},
    'orta bulgur': {'k': 83, 'p': 3, 'c': 17, 'y': 0.2, 'l': 4.5, 'o': 'kase', 'g': 100},
    'köftelik bulgur': {'k': 83, 'p': 3, 'c': 17, 'y': 0.2, 'l': 4.5, 'o': 'kase', 'g': 100},
    'pilavlık bulgur': {'k': 83, 'p': 3, 'c': 17, 'y': 0.2, 'l': 4.5, 'o': 'kase', 'g': 100},
    
    // MAKARNA ÇEŞİTLERİ
    'spagetti': {'k': 131, 'p': 5, 'c': 25, 'y': 1.1, 'l': 1.8, 'o': 'porsiyon', 'g': 100},
    'penne': {'k': 131, 'p': 5, 'c': 25, 'y': 1.1, 'l': 1.8, 'o': 'porsiyon', 'g': 100},
    'fusilli': {'k': 131, 'p': 5, 'c': 25, 'y': 1.1, 'l': 1.8, 'o': 'porsiyon', 'g': 100},
    'linguine': {'k': 131, 'p': 5, 'c': 25, 'y': 1.1, 'l': 1.8, 'o': 'porsiyon', 'g': 100},
    'tagliatelle': {'k': 131, 'p': 5, 'c': 25, 'y': 1.1, 'l': 1.8, 'o': 'porsiyon', 'g': 100},
    'lasagna': {'k': 131, 'p': 5, 'c': 25, 'y': 1.1, 'l': 1.8, 'o': 'porsiyon', 'g': 100},
    'tortellini': {'k': 250, 'p': 11, 'c': 38, 'y': 6, 'l': 2, 'o': 'porsiyon', 'g': 100},
    'ravioli': {'k': 245, 'p': 12, 'c': 35, 'y': 7, 'l': 2.5, 'o': 'porsiyon', 'g': 100},
    'tam buğday makarna': {'k': 124, 'p': 5.5, 'c': 25, 'y': 1.1, 'l': 3.9, 'o': 'porsiyon', 'g': 100},
    'glutensiz makarna': {'k': 338, 'p': 6.8, 'c': 78, 'y': 1.4, 'l': 2.3, 'o': 'porsiyon', 'g': 100},
    
    // EKMEK ÇEŞİTLERİ
    'beyaz ekmek': {'k': 265, 'p': 9, 'c': 49, 'y': 3.2, 'l': 2.7, 'o': 'dilim', 'g': 30},
    'esmer ekmek': {'k': 247, 'p': 13, 'c': 41, 'y': 4.2, 'l': 7, 'o': 'dilim', 'g': 30},
    'çavdar ekmeği': {'k': 259, 'p': 9, 'c': 48, 'y': 3.3, 'l': 5.8, 'o': 'dilim', 'g': 30},
    'tam buğday ekmeği': {'k': 247, 'p': 13, 'c': 41, 'y': 4.2, 'l': 7, 'o': 'dilim', 'g': 30},
    'glutensiz ekmek': {'k': 212, 'p': 3.8, 'c': 35, 'y': 7.7, 'l': 2.6, 'o': 'dilim', 'g': 30},
    'bagel': {'k': 245, 'p': 10, 'c': 48, 'y': 1.4, 'l': 2, 'o': 'adet', 'g': 90},
    'pita ekmeği': {'k': 275, 'p': 9, 'c': 55, 'y': 1.2, 'l': 2.2, 'o': 'adet', 'g': 60},
    'naan': {'k': 262, 'p': 8.7, 'c': 45, 'y': 5.1, 'l': 2.4, 'o': 'adet', 'g': 90},
    'focaccia': {'k': 271, 'p': 7.6, 'c': 45, 'y': 6.8, 'l': 2.7, 'o': 'dilim', 'g': 50},
    'simit': {'k': 400, 'p': 12, 'c': 72, 'y': 8, 'l': 3, 'o': 'adet', 'g': 120},
    'somun': {'k': 250, 'p': 8, 'c': 50, 'y': 2, 'l': 3, 'o': 'dilim', 'g': 40},
    'hamburger ekmeği': {'k': 264, 'p': 7.6, 'c': 48, 'y': 4.6, 'l': 2.4, 'o': 'adet', 'g': 43},
    
    // MISIR ÜRÜNLERİ
    'mısır': {'k': 86, 'p': 3.3, 'c': 19, 'y': 1.4, 'l': 2.4, 'o': 'koçan', 'g': 150},
    'popcorn': {'k': 387, 'p': 12, 'c': 78, 'y': 5, 'l': 15, 'o': 'kase', 'g': 50},
    'mısır gevreği': {'k': 357, 'p': 6.9, 'c': 84, 'y': 0.4, 'l': 2.8, 'o': 'kase', 'g': 30},
    'tortilla': {'k': 218, 'p': 5.7, 'c': 45, 'y': 3.5, 'l': 3.9, 'o': 'adet', 'g': 50},
    'nachos': {'k': 346, 'p': 8, 'c': 56, 'y': 12, 'l': 4, 'o': 'avuç', 'g': 50},
    
    // YAF ÇEŞİTLERİ
    'yulaf': {'k': 68, 'p': 2.4, 'c': 12, 'y': 1.4, 'l': 1.7, 'o': 'kase', 'g': 100},
    'müsli': {'k': 367, 'p': 10, 'c': 66, 'y': 6, 'l': 8, 'o': 'kase', 'g': 50},
    'granola': {'k': 471, 'p': 14, 'c': 61, 'y': 20, 'l': 7, 'o': 'kase', 'g': 50},
    'overnight oats': {'k': 68, 'p': 2.4, 'c': 12, 'y': 1.4, 'l': 1.7, 'o': 'kase', 'g': 100},
    
    // ARPA VE DİĞER TAHILLAR
    'arpa': {'k': 123, 'p': 2.3, 'c': 28, 'y': 0.4, 'l': 3.8, 'o': 'kase', 'g': 100},
    'kinoa': {'k': 120, 'p': 4.4, 'c': 22, 'y': 1.9, 'l': 2.8, 'o': 'kase', 'g': 100},
    'amarant': {'k': 102, 'p': 4, 'c': 19, 'y': 1.6, 'l': 2.1, 'o': 'kase', 'g': 100},
    'buckwheat': {'k': 92, 'p': 3.4, 'c': 20, 'y': 0.6, 'l': 2.7, 'o': 'kase', 'g': 100},
    'chia': {'k': 486, 'p': 17, 'c': 42, 'y': 31, 'l': 34, 'o': 'y.kaşığı', 'g': 15},
    'couscous': {'k': 112, 'p': 3.8, 'c': 23, 'y': 0.2, 'l': 1.4, 'o': 'kase', 'g': 100},
    'freekeh': {'k': 141, 'p': 5.4, 'c': 26, 'y': 1.2, 'l': 4.2, 'o': 'kase', 'g': 100},
    'spelt': {'k': 127, 'p': 5.5, 'c': 26, 'y': 0.9, 'l': 3.9, 'o': 'kase', 'g': 100},
    'teff': {'k': 101, 'p': 3.9, 'c': 20, 'y': 0.7, 'l': 2.8, 'o': 'kase', 'g': 100},
    'millet': {'k': 119, 'p': 3.5, 'c': 23, 'y': 1, 'l': 1.3, 'o': 'kase', 'g': 100},
    'sorghum': {'k': 123, 'p': 3.7, 'c': 25, 'y': 1.1, 'l': 2, 'o': 'kase', 'g': 100},
    
    // NOODLE VE ASYA MAKARНАЛARI
    'ramen': {'k': 436, 'p': 10, 'c': 63, 'y': 16, 'l': 2.4, 'o': 'paket', 'g': 85},
    'udon': {'k': 99, 'p': 2.6, 'c': 21, 'y': 0.5, 'l': 1.2, 'o': 'porsiyon', 'g': 100},
    'soba': {'k': 99, 'p': 5, 'c': 20, 'y': 0.1, 'l': 0, 'o': 'porsiyon', 'g': 100},
    'rice noodle': {'k': 109, 'p': 0.9, 'c': 25, 'y': 0.2, 'l': 0.4, 'o': 'porsiyon', 'g': 100},
    'shirataki': {'k': 9, 'p': 0, 'c': 3, 'y': 0, 'l': 3, 'o': 'porsiyon', 'g': 100},
    'glass noodle': {'k': 351, 'p': 0.2, 'c': 86, 'y': 0.1, 'l': 0.5, 'o': 'porsiyon', 'g': 100},
  };
} 