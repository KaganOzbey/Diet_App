import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../hizmetler/grafik_servisi.dart';
import '../../modeller/ogun_girisi_modeli.dart';

class OgunDagilimiGrafigi extends StatelessWidget {
  final List<OgunGirisiModeli> gunlukOgunler;
  final double? yukseklik;

  const OgunDagilimiGrafigi({
    Key? key,
    required this.gunlukOgunler,
    this.yukseklik = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Günlük Öğün Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            
            SizedBox(height: 16),
            
            Container(
              height: yukseklik,
              child: gunlukOgunler.isEmpty
                  ? _buildVeriYokMesaji()
                  : _buildBarChart(),
            ),
            
            SizedBox(height: 16),
            
            _buildLegend(),
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
          Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            'Henüz öğün verisi yok',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          Text(
            'Yemek ekleyerek başlayın',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final barGroups = GrafikServisi.ogunDagilimiGetir(gunlukOgunler);
    
    if (barGroups.isEmpty) {
      return _buildVeriYokMesaji();
    }
    
    final maxKalori = barGroups
        .map((group) => group.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxKalori * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final ogunIsimleri = ['Kahvaltı', 'Ara Öğün', 'Öğle', 'Akşam'];
              final ogunIsmi = groupIndex < ogunIsimleri.length 
                  ? ogunIsimleri[groupIndex] 
                  : 'Öğün';
              return BarTooltipItem(
                '$ogunIsmi\n${rod.toY.toInt()} kcal',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final ogunIsimleri = ['Kahvaltı', 'Ara\nÖğün', 'Öğle\nYemeği', 'Akşam\nYemeği'];
                final index = value.toInt();
                if (index >= 0 && index < ogunIsimleri.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      ogunIsimleri[index],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxKalori > 0 ? (maxKalori * 1.2) / 5 : 100,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
        ),
        
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxKalori > 0 ? (maxKalori * 1.2) / 5 : 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final renkler = [
      Colors.orange[400]!,  // Kahvaltı
      Colors.green[400]!,   // Ara Öğün
      Colors.blue[400]!,    // Öğle Yemeği
      Colors.purple[400]!,  // Akşam Yemeği
    ];
    
    final ogunIsimleri = ['Kahvaltı', 'Ara Öğün', 'Öğle Yemeği', 'Akşam Yemeği'];
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(4, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: renkler[index],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: 8),
            Text(
              ogunIsimleri[index],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }
} 