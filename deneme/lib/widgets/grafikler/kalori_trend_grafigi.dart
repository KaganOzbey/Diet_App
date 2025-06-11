import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../hizmetler/grafik_servisi.dart';

class KaloriTrendGrafigi extends StatefulWidget {
  final String kullaniciId;
  final bool haftalikMi; // true: haftalık, false: aylık
  final double? hedefKalori;

  const KaloriTrendGrafigi({
    Key? key,
    required this.kullaniciId,
    this.haftalikMi = true,
    this.hedefKalori,
  }) : super(key: key);

  @override
  _KaloriTrendGrafigiState createState() => _KaloriTrendGrafigiState();
}

class _KaloriTrendGrafigiState extends State<KaloriTrendGrafigi> {
  List<FlSpot> kaloriVerileri = [];
  bool yukleniyor = true;
  double maxY = 2500;
  double minY = 0;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => yukleniyor = true);
    
    try {
      List<FlSpot> veriler;
      if (widget.haftalikMi) {
        veriler = await GrafikServisi.haftalikKaloriVerisiGetir(widget.kullaniciId);
      } else {
        veriler = await GrafikServisi.aylikKaloriVerisiGetir(widget.kullaniciId);
      }
      
      if (veriler.isNotEmpty) {
        final kaloriDegerleri = veriler.map((spot) => spot.y).toList();
        maxY = kaloriDegerleri.reduce((a, b) => a > b ? a : b) * 1.2;
        minY = kaloriDegerleri.reduce((a, b) => a < b ? a : b) * 0.8;
        
        // Minimum ve maksimum değerleri makul aralıklarda tut
        maxY = maxY < 2000 ? 2000 : maxY;
        minY = minY < 0 ? 0 : minY;
      }
      
      setState(() {
        kaloriVerileri = veriler;
        yukleniyor = false;
      });
    } catch (e) {
      setState(() => yukleniyor = false);
      print('Kalori verisi yükleme hatası: $e');
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.haftalikMi ? 'Haftalık Kalori Trendi' : 'Aylık Kalori Trendi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _verileriYukle,
                  color: Colors.green[600],
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Grafik veya yükleme göstergesi
            Container(
              height: 200,
              child: yukleniyor
                  ? Center(child: CircularProgressIndicator(color: Colors.green))
                  : kaloriVerileri.isEmpty
                      ? _buildVeriYokMesaji()
                      : _buildGrafik(),
            ),
            
            SizedBox(height: 16),
            
            // Açıklama metni
            if (!yukleniyor && kaloriVerileri.isNotEmpty)
              _buildAciklamaMetni(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrafik() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return _buildAltEtiket(value.toInt());
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY - minY) / 5,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        
        minX: 0,
        maxX: widget.haftalikMi ? 6 : kaloriVerileri.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        
        lineBarsData: [
          // Kalori çizgisi
          LineChartBarData(
            spots: kaloriVerileri,
            isCurved: true,
            color: Colors.green[600]!,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green[600]!,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green[600]!.withOpacity(0.2),
            ),
          ),
          
          // Hedef çizgisi (varsa)
          if (widget.hedefKalori != null)
            LineChartBarData(
              spots: _hedefCizgisiOlustur(),
              isCurved: false,
              color: Colors.red[400]!,
              barWidth: 2,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
            ),
        ],
        
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  '${flSpot.y.toInt()} kcal',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAltEtiket(int index) {
    if (widget.haftalikMi) {
      if (index >= 0 && index < GrafikServisi.haftaGunleri.length) {
        return Text(
          GrafikServisi.haftaGunleri[index],
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      }
    } else {
      // Aylık görünümde belirli günlerde etiket göster
      if (index == 0 || (index + 1) % 5 == 0 || index == kaloriVerileri.length - 1) {
        return Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      }
    }
    return Container();
  }

  List<FlSpot> _hedefCizgisiOlustur() {
    final maxX = widget.haftalikMi ? 6.0 : kaloriVerileri.length.toDouble() - 1;
    return [
      FlSpot(0, widget.hedefKalori!),
      FlSpot(maxX, widget.hedefKalori!),
    ];
  }

  Widget _buildVeriYokMesaji() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'Henüz veri yok',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            'Besinler eklediğinizde grafik görünecek',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAciklamaMetni() {
    final ortalama = kaloriVerileri.map((e) => e.y).reduce((a, b) => a + b) / kaloriVerileri.length;
    final enYuksek = kaloriVerileri.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final enDusuk = kaloriVerileri.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return Container(
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
            'Özet:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 4),
          Text('• Ortalama: ${ortalama.toInt()} kcal'),
          Text('• En yüksek: ${enYuksek.toInt()} kcal'),
          Text('• En düşük: ${enDusuk.toInt()} kcal'),
        ],
      ),
    );
  }
} 