import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../hizmetler/grafik_servisi.dart';
import '../../hizmetler/veri_tabani_servisi.dart';

class KiloTakipGrafigi extends StatefulWidget {
  final String kullaniciId;
  final double? hedefKilo;
  final bool kompaktMod; // Dashboard için kompakt görünüm

  const KiloTakipGrafigi({
    Key? key,
    required this.kullaniciId,
    this.hedefKilo,
    this.kompaktMod = false,
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
      print('🔍 KiloTakipGrafigi: Veri yükleme başlıyor - Kullanıcı ID: ${widget.kullaniciId}');
      
      // Grafik servisinden veriyi al (tüm mantık orada)
      final tumVeriler = await GrafikServisi.kiloTakipVerisiGetir(widget.kullaniciId);
      print('📊 KiloTakipGrafigi: Alınan veri sayısı: ${tumVeriler.length}');
      
      if (tumVeriler.isNotEmpty) {
        final kiloDegerleri = tumVeriler.map((spot) => spot.y).toList();
        maxY = kiloDegerleri.reduce((a, b) => a > b ? a : b) + 5;
        minY = kiloDegerleri.reduce((a, b) => a < b ? a : b) - 5;
        print('📏 KiloTakipGrafigi: Min: $minY, Max: $maxY');
      }
      
      setState(() {
        kiloVerileri = tumVeriler;
        yukleniyor = false;
      });
      
      print('✅ KiloTakipGrafigi: Veri yükleme tamamlandı - ${tumVeriler.length} nokta');
    } catch (e) {
      setState(() => yukleniyor = false);
      print('❌ KiloTakipGrafigi: Veri yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kompaktMod) {
      // Dashboard için kompakt görünüm
      print('🖥️ Kompakt mod - Veri sayısı: ${kiloVerileri.length}, Yükleniyor: $yukleniyor');
      return Container(
        height: 100,
        child: yukleniyor
            ? Center(child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ))
            : kiloVerileri.isEmpty
                ? Center(
                    child: Text(
                      'Veri yok',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  )
                : _buildKompaktGrafik(),
      );
    }
    
    // Normal tam görünüm
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
        maxX: kiloVerileri.isNotEmpty 
            ? kiloVerileri.map((spot) => spot.x).reduce((a, b) => a > b ? a : b).clamp(1.0, 30.0)
            : 30.0,
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

  Widget _buildKompaktGrafik() {
    print('📈 Kompakt grafik oluşturuluyor - Veri: ${kiloVerileri.length} nokta');
    
    // Eğer tek veri noktası varsa, onu göster
    if (kiloVerileri.length == 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight, color: Colors.white, size: 24),
            Text(
              '${kiloVerileri.first.y.toStringAsFixed(1)} kg',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Mevcut Kilo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        
        minX: 0,
        maxX: kiloVerileri.isNotEmpty 
            ? kiloVerileri.map((spot) => spot.x).reduce((a, b) => a > b ? a : b).clamp(1.0, 30.0)
            : 30.0,
        minY: minY,
        maxY: maxY,
        
        lineBarsData: [
          LineChartBarData(
            spots: kiloVerileri,
            isCurved: true,
            color: Colors.white,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 1,
                  strokeColor: Colors.white.withOpacity(0.5),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _hedefCizgisiOlustur() {
    if (widget.hedefKilo == null) return [];
    
    final maxX = kiloVerileri.isNotEmpty 
        ? kiloVerileri.map((spot) => spot.x).reduce((a, b) => a > b ? a : b).clamp(1.0, 30.0)
        : 30.0;
    
    return [
      FlSpot(0, widget.hedefKilo!),
      FlSpot(maxX, widget.hedefKilo!),
    ];
  }
} 