import 'package:flutter/material.dart';
import 'ana_ekran.dart';

class BilgiGirisEkrani extends StatefulWidget {
  @override
  _BilgiGirisEkraniState createState() => _BilgiGirisEkraniState();
}

class _BilgiGirisEkraniState extends State<BilgiGirisEkrani> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  bool isMale = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bilgilerini Gir")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Erkek"),
                Radio(value: true, groupValue: isMale, onChanged: (value) => setState(() => isMale = value!)),
                Text("Kadın"),
                Radio(value: false, groupValue: isMale, onChanged: (value) => setState(() => isMale = value!)),
              ],
            ),
            TextField(controller: heightController, decoration: InputDecoration(labelText: "Boy (cm)"), keyboardType: TextInputType.number),
            TextField(controller: weightController, decoration: InputDecoration(labelText: "Kilo (kg)"), keyboardType: TextInputType.number),
            TextField(controller: ageController, decoration: InputDecoration(labelText: "Yaş"), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final height = double.tryParse(heightController.text) ?? 0;
                final weight = double.tryParse(weightController.text) ?? 0;
                final age = int.tryParse(ageController.text) ?? 0;
                double bmr = isMale
                    ? 10 * weight + 6.25 * height - 5 * age + 5
                    : 10 * weight + 6.25 * height - 5 * age - 161;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => AnaEkran(bmr: bmr)),
                );
              },
              child: Text("Başla"),
            ),
          ],
        ),
      ),
    );
  }
}
