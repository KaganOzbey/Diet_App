import 'package:flutter/material.dart';
import '../widgets/grafik_ve_yazi.dart';

class AnasayfaEkrani extends StatelessWidget {
  final double bmr;
  final List<Map<String, dynamic>> addedFoods;

  AnasayfaEkrani({required this.bmr, required this.addedFoods});

  @override
  Widget build(BuildContext context) {
    double totalCal = addedFoods.fold(0.0, (sum, item) => sum + item['cal']);
    double remaining = bmr - totalCal;
    double percent = (totalCal / bmr).clamp(0.0, 1.0);

    double proteinCal = totalCal * 0.3;
    double carbCal = totalCal * 0.5;
    double fatCal = totalCal * 0.2;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text("Günlük Kalori İhtiyacınız", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                    SizedBox(height: 8),
                    Text("${bmr.toStringAsFixed(0)} kcal", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            GrafikVeYazi(label: "Genel Kalori", percentage: percent, valueText: "${(percent * 100).toStringAsFixed(1)}% (${totalCal.toStringAsFixed(0)} kcal)", color: Colors.green),
            SizedBox(height: 20),
            GrafikVeYazi(label: "Protein", percentage: (proteinCal / bmr).clamp(0.0, 1.0), valueText: "${proteinCal.toStringAsFixed(0)} kcal", color: Colors.blue),
            SizedBox(height: 20),
            GrafikVeYazi(label: "Karbonhidrat", percentage: (carbCal / bmr).clamp(0.0, 1.0), valueText: "${carbCal.toStringAsFixed(0)} kcal", color: Colors.orange),
            SizedBox(height: 20),
            GrafikVeYazi(label: "Yağ", percentage: (fatCal / bmr).clamp(0.0, 1.0), valueText: "${fatCal.toStringAsFixed(0)} kcal", color: Colors.purple),
          ],
        ),
      ),
    );
  }
}
