import 'package:flutter/material.dart';

class OnerilerEkrani extends StatelessWidget {
  final double remaining;
  final List<Map<String, dynamic>> addedFoods;

  const OnerilerEkrani({Key? key, required this.remaining, required this.addedFoods}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalCal = addedFoods.fold(0.0, (sum, item) => sum + (item['cal'] ?? 0.0));
    double protein = totalCal * 0.3;
    double carbs = totalCal * 0.5;
    double fat = totalCal * 0.2;

    List<String> feedback = [];

    if (protein < 400) {
      feedback.add("Bugün yeterince protein almadınız. Yumurta, tavuk, yoğurt tüketebilirsiniz.");
    } else {
      feedback.add("Protein alımınız yeterli düzeyde, bu şekilde devam edin.");
    }

    if (carbs > 1000) {
      feedback.add("Karbonhidrat alımınız yüksek olabilir. Tam tahıllı gıdaları tercih edin ve şekerli yiyecekleri azaltın.");
    }

    if (fat > 700) {
      feedback.add("Yağ alımınız yüksek olabilir. Kızartma ve işlenmiş yağları azaltmayı düşünebilirsiniz.");
    }

    if (remaining < 100) {
      feedback.add("Günlük kalori hedefinize yaklaştınız, hafif yiyecekler tercih edin.");
    }

    final List<Map<String, dynamic>> suggestions = [
      {'name': 'Lor Peyniri (50g)', 'cal': 60},
      {'name': 'Haşlanmış Yumurta', 'cal': 78},
      {'name': 'Zeytinyağlı Salata', 'cal': 120},
      {'name': 'Yoğurt (1 kase)', 'cal': 100},
      {'name': 'Elma', 'cal': 95},
      {'name': 'Ceviz (3 adet)', 'cal': 80},
    ];

    final filtered = suggestions.where((item) => item['cal'] <= remaining).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Beslenme Önerileri"), backgroundColor: Colors.green[300]),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kişisel Beslenme Geri Bildirimi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...feedback.map((msg) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text(msg, style: TextStyle(fontSize: 15))),
                ],
              ),
            )),
            Divider(height: 40),
            Text("Kalan Kalori: ${remaining.toStringAsFixed(0)} kcal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text("Tüketebileceğiniz Öğün Önerileri", style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text("Kalan kaloriye uygun öneri bulunamadı."))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.food_bank, color: Colors.green),
                      title: Text(item['name']),
                      trailing: Text("${item['cal']} kcal"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
