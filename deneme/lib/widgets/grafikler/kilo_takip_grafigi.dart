import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../hizmetler/grafik_servisi.dart';

class KiloTakipGrafigi extends StatefulWidget {
  final String kullaniciId;
  final double? hedefKilo;

  const KiloTakipGrafigi({
    Key? key,
    required this.kullaniciId,
    this.hedefKilo,
  }) : super(key: key);

  @override
  _KiloTakipGrafigiState createState() => _KiloTakipGrafigiState();
}

class _KiloTakipGrafigiState extends State<KiloTakipGrafigi> {
  List<FlSpot> kiloVerileri = [];
  bool yukleniyor = true;
  double maxY = 100;
  double minY = 50;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => yukleniyor = true);
    
    try {
      final veriler = await GrafikServisi.kiloTakipVerisiGetir(widget.kullaniciId);
      
      if (veriler.isNotEmpty) {
        final kiloDegerleri = veriler.map((spot) => spot.y).toList();
        maxY = kiloDegerleri.reduce((a, b) => a > b ? a : b) + 5;
        minY = kiloDegerleri.reduce((a, b) => a < b ? a : b) - 5;
      }
      
      setState(() {
        kiloVerileri = veriler;
        yukleniyor = false;
      });
    } catch (e) {
      setState(() => yukleniyor = false);
      print('Kilo verisi yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kilo Takibi (Son 30 Gün)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green[600]),
                  onPressed: _verileriYukle,
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Container(
              height: 220,
              child: yukleniyor
                  ? Center(child: CircularProgressIndicator(color: Colors.green))
                  : kiloVerileri.isEmpty
                      ? _buildVeriYokMesaji()
                      : _buildGrafik(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVeriYokMesaji() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight, size: 48, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            'Henüz kilo verisi yok',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          Text(
            'Kilo kaydı ekleyerek takip başlatın',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
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
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(30 - value.toInt())} gün',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
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
                  '${value.toStringAsFixed(1)} kg',
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
        maxX: kiloVerileri.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        
        lineBarsData: [
          // Kilo çizgisi
          LineChartBarData(
            spots: kiloVerileri,
            isCurved: true,
            color: Colors.purple[600]!,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.purple[600]!,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple[600]!.withOpacity(0.2),
            ),
          ),
          
          // Hedef kilo çizgisi (varsa)
          if (widget.hedefKilo != null)
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
                  '${flSpot.y.toStringAsFixed(1)} kg',
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

  List<FlSpot> _hedefCizgisiOlustur() {
    if (widget.hedefKilo == null || kiloVerileri.isEmpty) return [];
    
    return [
      FlSpot(0, widget.hedefKilo!),
      FlSpot(kiloVerileri.length.toDouble() - 1, widget.hedefKilo!),
    ];
  }
} 