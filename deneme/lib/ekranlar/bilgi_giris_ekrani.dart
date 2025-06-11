import 'package:flutter/material.dart';
import '../hizmetler/veri_tabani_servisi.dart';
import 'modern_dashboard.dart';

class BilgiGirisEkrani extends StatefulWidget {
  final String? email;
  
  const BilgiGirisEkrani({Key? key, this.email}) : super(key: key);

  @override
  _BilgiGirisEkraniState createState() => _BilgiGirisEkraniState();
}

class _BilgiGirisEkraniState extends State<BilgiGirisEkrani> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  bool isMale = true;
  int activityLevel = 2; // Varsayılan: Az aktif
  bool isLoading = false;

  final List<String> activityLevels = [
    'Sedanter (Hareketsiz)',
    'Az Aktif (Haftada 1-3 gün)',
    'Orta Aktif (Haftada 3-5 gün)',
    'Aktif (Haftada 6-7 gün)',
    'Çok Aktif (Günde 2 kez antrenman)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      nameController.text = widget.email!.split('@')[0]; // Email'den isim tahmin et
    }
  }

  Future<void> _createUserAndNavigate() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);

    try {
      final kullanici = await VeriTabaniServisi.kullaniciOlustur(
        email: widget.email ?? 'user@example.com',
        isim: nameController.text.trim(),
        boy: double.parse(heightController.text),
        kilo: double.parse(weightController.text),
        yas: int.parse(ageController.text),
        erkekMi: isMale,
        aktiviteSeviyesi: activityLevel + 1, // Liste 0-based, enum 1-based
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ModernDashboard(bmr: kullanici.gunlukKaloriHedefi),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      _showError('İsim boş olamaz');
      return false;
    }

    final height = double.tryParse(heightController.text);
    if (height == null || height < 100 || height > 250) {
      _showError('Geçerli bir boy girin (100-250 cm)');
      return false;
    }

    final weight = double.tryParse(weightController.text);
    if (weight == null || weight < 30 || weight > 300) {
      _showError('Geçerli bir kilo girin (30-300 kg)');
      return false;
    }

    final age = int.tryParse(ageController.text);
    if (age == null || age < 10 || age > 120) {
      _showError('Geçerli bir yaş girin (10-120)');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bilgilerini Gir"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hoş geldin mesajı
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_add, size: 48, color: Colors.green[600]),
                  SizedBox(height: 8),
                  Text(
                    'Kişiselleştirilmiş beslenme planı için bilgilerinizi girin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),

            // İsim
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "İsim",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person),
                hintText: "Örn: Kağan, Çağla, Şule",
              ),
              textCapitalization: TextCapitalization.words,
              enableSuggestions: true,
              autocorrect: true,
            ),
            
            SizedBox(height: 16),

            // Cinsiyet seçimi
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cinsiyet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text("Erkek"),
                          value: true,
                          groupValue: isMale,
                          onChanged: (value) => setState(() => isMale = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text("Kadın"),
                          value: false,
                          groupValue: isMale,
                          onChanged: (value) => setState(() => isMale = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),

            // Boy, Kilo, Yaş
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: heightController,
                    decoration: InputDecoration(
                      labelText: "Boy (cm)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: weightController,
                    decoration: InputDecoration(
                      labelText: "Kilo (kg)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),

            TextField(
              controller: ageController,
              decoration: InputDecoration(
                labelText: "Yaş",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
            ),
            
            SizedBox(height: 16),

            // Aktivite seviyesi
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivite Seviyesi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButton<int>(
                    value: activityLevel,
                    isExpanded: true,
                    items: List.generate(activityLevels.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(activityLevels[index]),
                      );
                    }),
                    onChanged: (value) => setState(() => activityLevel = value!),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),

            // Başla butonu
            ElevatedButton(
              onPressed: isLoading ? null : _createUserAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Kaydediliyor...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch),
                        SizedBox(width: 8),
                        Text(
                          'Başlayalım!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    super.dispose();
  }
}
