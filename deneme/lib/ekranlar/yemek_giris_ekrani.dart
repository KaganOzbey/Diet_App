import 'package:flutter/material.dart';
import '../servisler/besin_servisi.dart';

class YemekGirisEkrani extends StatefulWidget {
  final Function(String, String, double) onAdd;
  YemekGirisEkrani({required this.onAdd});

  @override
  _YemekGirisEkraniState createState() => _YemekGirisEkraniState();
}

class _YemekGirisEkraniState extends State<YemekGirisEkrani> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController gramController = TextEditingController(); // kalori yerine grama çevirdim.
  String selectedCategory = 'Kahvaltı';
  List<Map<String, dynamic>> localFoodList = [];
  bool isLoading = false;

  Future<void> yemekEkle() async {
    final yemekAdi = nameController.text;
    final gram = double.tryParse(gramController.text) ?? 0;

    if (yemekAdi.isEmpty || gram <= 0) return;

    setState(() => isLoading = true);

    try {
      final fdcId = await BesinServisi.yemekAra(yemekAdi);
      if (fdcId == null) throw Exception("Yemek bulunamadı");

      final kalori100g = await BesinServisi.kaloriGetir(fdcId);
      if (kalori100g == null) throw Exception("Kalori verisi bulunamadı");

      final hesaplananKalori = (kalori100g * gram) / 100;

      widget.onAdd(selectedCategory, yemekAdi, hesaplananKalori);
      setState(() {
        localFoodList.add({'category': selectedCategory, 'name': yemekAdi, 'cal': hesaplananKalori});
      });

      nameController.clear();
      gramController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: ['Kahvaltı', 'Ara Öğün', 'Öğle Yemeği', 'Akşam Yemeği']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Yemek Adı"),
              ),
              TextField(
                controller: gramController,
                decoration: InputDecoration(labelText: "Gramaj (örneğin: 150)"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : yemekEkle,
                child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Ekle"),
              ),
              SizedBox(height: 20),
              Divider(),
              Text("Eklenen Öğünler:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...localFoodList.map((item) => Text(
                "${item['category']} - ${item['name']} (${item['cal'].toStringAsFixed(1)} kcal)",
                style: TextStyle(fontSize: 16),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
