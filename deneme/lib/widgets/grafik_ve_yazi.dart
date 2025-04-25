import 'package:flutter/material.dart';
import 'dairesel_grafik.dart';

class GrafikVeYazi extends StatelessWidget {
  final String label;
  final double percentage;
  final String valueText;
  final Color color;

  GrafikVeYazi({
    required this.label,
    required this.percentage,
    required this.valueText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomPaint(
          painter: DaireselGrafik(percentage, color, 12),
          child: Container(width: 80, height: 80),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(valueText),
          ],
        )
      ],
    );
  }
}
