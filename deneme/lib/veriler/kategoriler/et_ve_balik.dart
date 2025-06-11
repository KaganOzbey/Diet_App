// Et ve Balık Veritabanı - 60+ çeşit protein kaynağı
class EtVeBalikVeritabani {
  static const Map<String, Map<String, dynamic>> etVeBalik = {
    // TAVUK ETİ
    'tavuk göğsü': {'k': 165, 'p': 31, 'c': 0, 'y': 3.6, 'l': 0, 'o': 'gram', 'g': 100},
    'tavuk but': {'k': 209, 'p': 26, 'c': 0, 'y': 11, 'l': 0, 'o': 'gram', 'g': 100},
    'tavuk kanat': {'k': 203, 'p': 30, 'c': 0, 'y': 8.1, 'l': 0, 'o': 'adet', 'g': 50},
    'tavuk derisi': {'k': 349, 'p': 23, 'c': 0, 'y': 28, 'l': 0, 'o': 'gram', 'g': 100},
    'tavuk ciğeri': {'k': 119, 'p': 16.9, 'c': 0.7, 'y': 4.8, 'l': 0, 'o': 'gram', 'g': 100},
    'hindi göğsü': {'k': 135, 'p': 30, 'c': 0, 'y': 1, 'l': 0, 'o': 'gram', 'g': 100},
    'hindi but': {'k': 144, 'p': 28, 'c': 0, 'y': 3.2, 'l': 0, 'o': 'gram', 'g': 100},
    
    // DANA ETİ
    'dana bonfile': {'k': 271, 'p': 26, 'c': 0, 'y': 18, 'l': 0, 'o': 'gram', 'g': 100},
    'dana pirzola': {'k': 291, 'p': 24, 'c': 0, 'y': 21, 'l': 0, 'o': 'gram', 'g': 100},
    'dana kıyma': {'k': 332, 'p': 14, 'c': 0, 'y': 30, 'l': 0, 'o': 'gram', 'g': 100},
    'dana rostosu': {'k': 259, 'p': 26, 'c': 0, 'y': 17, 'l': 0, 'o': 'gram', 'g': 100},
    'dana kuşbaşı': {'k': 250, 'p': 26, 'c': 0, 'y': 15, 'l': 0, 'o': 'gram', 'g': 100},
    'dana but': {'k': 143, 'p': 27, 'c': 0, 'y': 3, 'l': 0, 'o': 'gram', 'g': 100},
    'dana ciğeri': {'k': 135, 'p': 20.5, 'c': 3.9, 'y': 3.6, 'l': 0, 'o': 'gram', 'g': 100},
    'dana böbreği': {'k': 99, 'p': 17.4, 'c': 0, 'y': 2.5, 'l': 0, 'o': 'gram', 'g': 100},
    'dana kalbi': {'k': 112, 'p': 17.7, 'c': 0.1, 'y': 3.9, 'l': 0, 'o': 'gram', 'g': 100},
    
    // KUZU ETİ
    'kuzu pirzola': {'k': 294, 'p': 25, 'c': 0, 'y': 21, 'l': 0, 'o': 'gram', 'g': 100},
    'kuzu but': {'k': 268, 'p': 25, 'c': 0, 'y': 18, 'l': 0, 'o': 'gram', 'g': 100},
    'kuzu kol': {'k': 288, 'p': 22, 'c': 0, 'y': 22, 'l': 0, 'o': 'gram', 'g': 100},
    'kuzu ciğeri': {'k': 137, 'p': 18.9, 'c': 2.2, 'y': 4.6, 'l': 0, 'o': 'gram', 'g': 100},
    'kuzu böbreği': {'k': 88, 'p': 15.8, 'c': 0, 'y': 2.3, 'l': 0, 'o': 'gram', 'g': 100},
    
    // DOMUZ ETİ (halal olmayan ama referans için)
    'domuz pirzola': {'k': 242, 'p': 27, 'c': 0, 'y': 14, 'l': 0, 'o': 'gram', 'g': 100},
    'jambon': {'k': 145, 'p': 20.9, 'c': 1.5, 'y': 5.5, 'l': 0, 'o': 'dilim', 'g': 30},
    'salam': {'k': 336, 'p': 15, 'c': 1, 'y': 30, 'l': 0, 'o': 'dilim', 'g': 25},
    'sucuk': {'k': 473, 'p': 18.2, 'c': 0.8, 'y': 44.1, 'l': 0, 'o': 'dilim', 'g': 20},
    'sosis': {'k': 315, 'p': 12, 'c': 4, 'y': 28, 'l': 0, 'o': 'adet', 'g': 50},
    'pastırma': {'k': 330, 'p': 36, 'c': 0, 'y': 20, 'l': 0, 'o': 'dilim', 'g': 15},
    'kavurma': {'k': 500, 'p': 32, 'c': 0, 'y': 40, 'l': 0, 'o': 'gram', 'g': 100},
    
    // DENİZ ÜRÜNLERI
    'levrek': {'k': 124, 'p': 23, 'c': 0, 'y': 3, 'l': 0, 'o': 'gram', 'g': 100},
    'çupra': {'k': 128, 'p': 21, 'c': 0, 'y': 4.5, 'l': 0, 'o': 'gram', 'g': 100},
    'salmon': {'k': 208, 'p': 25, 'c': 0, 'y': 12, 'l': 0, 'o': 'gram', 'g': 100},
    'ton balığı': {'k': 144, 'p': 23, 'c': 0, 'y': 4.9, 'l': 0, 'o': 'gram', 'g': 100},
    'sardalya': {'k': 208, 'p': 25, 'c': 0, 'y': 11, 'l': 0, 'o': 'adet', 'g': 80},
    'hamsi': {'k': 131, 'p': 20, 'c': 0, 'y': 4.8, 'l': 0, 'o': 'adet', 'g': 15},
    'istavrit': {'k': 190, 'p': 19, 'c': 0, 'y': 12, 'l': 0, 'o': 'gram', 'g': 100},
    'palamut': {'k': 158, 'p': 26, 'c': 0, 'y': 5, 'l': 0, 'o': 'gram', 'g': 100},
    'lüfer': {'k': 124, 'p': 23, 'c': 0, 'y': 3, 'l': 0, 'o': 'gram', 'g': 100},
    'barbunya': {'k': 127, 'p': 20, 'c': 0, 'y': 4.5, 'l': 0, 'o': 'gram', 'g': 100},
    'kalkan': {'k': 95, 'p': 16, 'c': 1.2, 'y': 2.9, 'l': 0, 'o': 'gram', 'g': 100},
    'dil balığı': {'k': 86, 'p': 17, 'c': 1.2, 'y': 1.2, 'l': 0, 'o': 'gram', 'g': 100},
    'mezgit': {'k': 82, 'p': 17, 'c': 0, 'y': 1.4, 'l': 0, 'o': 'gram', 'g': 100},
    'uskumru': {'k': 305, 'p': 19, 'c': 0, 'y': 25, 'l': 0, 'o': 'gram', 'g': 100},
    'alabalık': {'k': 119, 'p': 20, 'c': 0, 'y': 3.5, 'l': 0, 'o': 'gram', 'g': 100},
    'sazan': {'k': 127, 'p': 17.8, 'c': 0, 'y': 5.6, 'l': 0, 'o': 'gram', 'g': 100},
    
    // KONSERVE BALIK
    'ton balığı konserve': {'k': 116, 'p': 26, 'c': 0, 'y': 1, 'l': 0, 'o': 'kutu', 'g': 160},
    'sardalya konserve': {'k': 208, 'p': 25, 'c': 0, 'y': 11, 'l': 0, 'o': 'kutu', 'g': 120},
    'hamsi konserve': {'k': 210, 'p': 29, 'c': 0, 'y': 10, 'l': 0, 'o': 'kutu', 'g': 100},
    'somon konserve': {'k': 142, 'p': 20, 'c': 0, 'y': 6, 'l': 0, 'o': 'kutu', 'g': 100},
    
    // DENİZ ÜRÜNLERİ
    'karides': {'k': 99, 'p': 18, 'c': 0.9, 'y': 1.7, 'l': 0, 'o': 'gram', 'g': 100},
    'midye': {'k': 86, 'p': 12, 'c': 7, 'y': 2.2, 'l': 0, 'o': 'adet', 'g': 15},
    'ahtapot': {'k': 82, 'p': 15, 'c': 2.2, 'y': 1, 'l': 0, 'o': 'gram', 'g': 100},
    'kalamar': {'k': 92, 'p': 15.6, 'c': 3.1, 'y': 1.4, 'l': 0, 'o': 'gram', 'g': 100},
    'yengeç': {'k': 87, 'p': 18, 'c': 0, 'y': 1.1, 'l': 0, 'o': 'gram', 'g': 100},
    'ıstakoz': {'k': 89, 'p': 19, 'c': 0, 'y': 0.9, 'l': 0, 'o': 'gram', 'g': 100},
    'istiridye': {'k': 69, 'p': 7, 'c': 4.7, 'y': 2.5, 'l': 0, 'o': 'adet', 'g': 50},
    
    // YUMURTA
    'tavuk yumurtası': {'k': 155, 'p': 13, 'c': 1.1, 'y': 11, 'l': 0, 'o': 'adet', 'g': 50},
    'yumurta akı': {'k': 17, 'p': 3.6, 'c': 0.2, 'y': 0.1, 'l': 0, 'o': 'adet', 'g': 33},
    'yumurta sarısı': {'k': 55, 'p': 2.7, 'c': 0.6, 'y': 4.5, 'l': 0, 'o': 'adet', 'g': 17},
    'bıldırcın yumurtası': {'k': 158, 'p': 13, 'c': 0.4, 'y': 11, 'l': 0, 'o': 'adet', 'g': 9},
    'ördek yumurtası': {'k': 185, 'p': 13, 'c': 1.5, 'y': 14, 'l': 0, 'o': 'adet', 'g': 70},
    
    // İŞLENMİŞ ET ÜRÜNLERİ
    'köfte': {'k': 295, 'p': 17, 'c': 7, 'y': 22, 'l': 0.5, 'o': 'adet', 'g': 60},
    'adana kebap': {'k': 250, 'p': 18, 'c': 2, 'y': 18, 'l': 0, 'o': 'porsiyon', 'g': 120},
    'döner': {'k': 350, 'p': 25, 'c': 15, 'y': 20, 'l': 2, 'o': 'porsiyon', 'g': 150},
    'şiş kebap': {'k': 280, 'p': 22, 'c': 3, 'y': 19, 'l': 0, 'o': 'porsiyon', 'g': 120},
    'urfa kebap': {'k': 270, 'p': 20, 'c': 2, 'y': 19, 'l': 0, 'o': 'porsiyon', 'g': 120},
    'piliç şiş': {'k': 200, 'p': 30, 'c': 2, 'y': 7, 'l': 0, 'o': 'porsiyon', 'g': 120},
    'tavuk döner': {'k': 280, 'p': 28, 'c': 12, 'y': 14, 'l': 1, 'o': 'porsiyon', 'g': 150},
    'hamburger köftesi': {'k': 540, 'p': 25, 'c': 40, 'y': 31, 'l': 2, 'o': 'adet', 'g': 200},
    'chicken nugget': {'k': 296, 'p': 15, 'c': 18, 'y': 19, 'l': 1, 'o': 'adet', 'g': 20},
    'balık kroket': {'k': 190, 'p': 11, 'c': 17, 'y': 9, 'l': 1, 'o': 'adet', 'g': 60},
  };
} 