import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BesinServisi {
  static final String _apiKey = dotenv.env['API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// Yemek adıyla arama yapar, ilk eşleşen yemeğin fdcId'sini döner
  static Future<int?> yemekAra(String yemekAdi) async {
    try {
      final url = Uri.parse('$_baseUrl/foods/search?query=$yemekAdi&api_key=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Arama sonuçları: ${data['foods']}");

        if (data['foods'] != null && data['foods'].isNotEmpty) {
          return data['foods'][0]['fdcId'];
        } else {
          print("Arama sonucu boş döndü.");
        }
      } else {
        print("Arama isteği başarısız: ${response.statusCode}");
      }
    } catch (e) {
      print('Yemek ararken hata oluştu: $e');
    }
    return null;
  }

  /// fdcId ile kalori (kcal) bilgisini döner
  static Future<double?> kaloriGetir(int fdcId) async {
    try {
      final url = Uri.parse('$_baseUrl/food/$fdcId?api_key=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Gelen besin verisi:\n$data");

        final nutrients = data['foodNutrients'];
        for (var nutrient in nutrients) {
          final nutrientInfo = nutrient['nutrient'];
          final name = nutrientInfo['name'].toString().toLowerCase();
          final unit = nutrientInfo['unitName'].toString().toLowerCase();

          print("nutrient: $name, unit: $unit, amount: ${nutrient['amount']}");

          if (name.contains('energy') && unit == 'kcal') {
            final value = nutrient['amount'];
            if (value != null) {
              return (value as num).toDouble();
            }
          }
        }

        print("Kalori verisi bulunamadı.");
      } else {
        print("Kalori isteği başarısız: ${response.statusCode}");
      }
    } catch (e) {
      print('⚠Kalori getirirken hata oluştu: $e');
    }
    return null;
  }
}
