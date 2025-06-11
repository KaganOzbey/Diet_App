import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../hizmetler/grafik_servisi.dart';
import '../../modeller/gunluk_beslenme_modeli.dart';

class MakroBesinGrafigi extends StatefulWidget {
  final GunlukBeslenmeModeli? beslenmeVerisi;
  final double? yukseklik;

  const MakroBesinGrafigi({
    Key? key,
    this.beslenmeVerisi,
    this.yukseklik = 250,
  }) : super(key: key);

  @override
  _MakroBesinGrafigiState createState() => _MakroBesinGrafigiState();
}

class _MakroBesinGrafigiState extends State<MakroBesinGrafigi>
    with SingleTickerProviderStateMixin {
  int dokunulanIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Makro Besin Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Ana içerik
            Container(
              height: widget.yukseklik,
              child: widget.beslenmeVerisi == null || widget.beslenmeVerisi!.toplamKalori == 0
                  ? _buildVeriYokMesaji()
                  : AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Row(
                          children: [
                            // Pie Chart
                            Expanded(
                              flex: 2,
                              child: Transform.scale(
                                scale: _animation.value,
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            dokunulanIndex = -1;
                                            return;
                                          }
                                          dokunulanIndex = pieTouchResponse
                                              .touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _buildPieChartSections(),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 16),
                            
                            // Açıklama listesi
                            Expanded(
                              flex: 1,
                              child: _buildAciklamaListesi(),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            
            // Detaylı bilgi
            if (widget.beslenmeVerisi != null && widget.beslenmeVerisi!.toplamKalori > 0)
              _buildDetayliBilgi(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final sections = GrafikServisi.makroBesinDagilimiGetir(widget.beslenmeVerisi);
    
    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      final isTouched = index == dokunulanIndex;
      final radius = isTouched ? 60.0 : 50.0;
      
      return PieChartSectionData(
        color: section.color,
        value: section.value,
        title: isTouched ? section.title : '${(section.value / _toplamDeger() * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  double _toplamDeger() {
    if (widget.beslenmeVerisi == null) return 100;
    return (widget.beslenmeVerisi!.toplamProtein * 4) +
           (widget.beslenmeVerisi!.toplamKarbonhidrat * 4) +
           (widget.beslenmeVerisi!.toplamYag * 9);
  }

  Widget _buildAciklamaListesi() {
    if (widget.beslenmeVerisi == null || widget.beslenmeVerisi!.toplamKalori == 0) {
      return Container();
    }

    final protein = widget.beslenmeVerisi!.toplamProtein;
    final karbonhidrat = widget.beslenmeVerisi!.toplamKarbonhidrat;
    final yag = widget.beslenmeVerisi!.toplamYag;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAciklamaItem(
          renk: Colors.red[400]!,
          baslik: 'Protein',
          miktar: '${protein.toStringAsFixed(1)}g',
          kalori: '${(protein * 4).toInt()} kcal',
        ),
        SizedBox(height: 8),
        _buildAciklamaItem(
          renk: Colors.blue[400]!,
          baslik: 'Karbonhidrat',
          miktar: '${karbonhidrat.toStringAsFixed(1)}g',
          kalori: '${(karbonhidrat * 4).toInt()} kcal',
        ),
        SizedBox(height: 8),
        _buildAciklamaItem(
          renk: Colors.orange[400]!,
          baslik: 'Yağ',
          miktar: '${yag.toStringAsFixed(1)}g',
          kalori: '${(yag * 9).toInt()} kcal',
        ),
      ],
    );
  }

  Widget _buildAciklamaItem({
    required Color renk,
    required String baslik,
    required String miktar,
    required String kalori,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: renk,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baslik,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                miktar,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                kalori,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVeriYokMesaji() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Henüz veri yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Besinler eklediğinizde\nmakro besin dağılımı görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetayliBilgi() {
    final beslenme = widget.beslenmeVerisi!;
    final toplamMakroKalori = (beslenme.toplamProtein * 4) +
                               (beslenme.toplamKarbonhidrat * 4) +
                               (beslenme.toplamYag * 9);

    // İdeal oranlar
    final idealProteinOrani = 25.0; // %20-30
    final idealKarbonhidratOrani = 50.0; // %45-65
    final idealYagOrani = 25.0; // %20-35

    final proteinOrani = (beslenme.toplamProtein * 4) / toplamMakroKalori * 100;
    final karbonhidratOrani = (beslenme.toplamKarbonhidrat * 4) / toplamMakroKalori * 100;
    final yagOrani = (beslenme.toplamYag * 9) / toplamMakroKalori * 100;

    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiz ve Öneriler:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          _buildAnalizSatiri('Protein', proteinOrani, idealProteinOrani),
          _buildAnalizSatiri('Karbonhidrat', karbonhidratOrani, idealKarbonhidratOrani),
          _buildAnalizSatiri('Yağ', yagOrani, idealYagOrani),
        ],
      ),
    );
  }

  Widget _buildAnalizSatiri(String besin, double gercekOran, double idealOran) {
    final fark = gercekOran - idealOran;
    final renkKodu = fark.abs() <= 5 ? Colors.green : (fark.abs() <= 10 ? Colors.orange : Colors.red);
    final durum = fark.abs() <= 5 ? 'İdeal' : (fark > 0 ? 'Yüksek' : 'Düşük');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$besin: ${gercekOran.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: renkKodu,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              durum,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 