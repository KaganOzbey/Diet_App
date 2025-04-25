import 'package:flutter/material.dart';
import 'yemek_giris_ekrani.dart';
import 'anasayfa_ekrani.dart';
import 'oneriler_ekrani.dart';

class AnaEkran extends StatefulWidget {
  final double bmr;
  AnaEkran({required this.bmr});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _currentIndex = 1;
  List<Map<String, dynamic>> addedFoods = [];

  void addFood(String category, String name, double cal) {
    setState(() {
      addedFoods.add({'category': category, 'name': name, 'cal': cal});
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      YemekGirisEkrani(onAdd: addFood),
      AnasayfaEkrani(bmr: widget.bmr, addedFoods: addedFoods),
      OnerilerEkrani(
        remaining: widget.bmr - addedFoods.fold(0.0, (sum, item) => sum + item['cal']),
        addedFoods: addedFoods,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Yemek"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: "Öneriler"),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
