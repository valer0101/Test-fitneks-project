import 'package:flutter/material.dart';

class MannequinHeatmap extends StatelessWidget {
  final List<String> selectedGroups;
  final Map<String, int> muscleGroupPoints;

  const MannequinHeatmap({
    super.key,
    required this.selectedGroups,
    required this.muscleGroupPoints,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Front View
          Expanded(
            child: CustomPaint(
              painter: MannequinPainter(
                selectedGroups: selectedGroups,
                muscleGroupPoints: muscleGroupPoints,
                isFront: true,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(width: 10),
          // Back View
          Expanded(
            child: CustomPaint(
              painter: MannequinPainter(
                selectedGroups: selectedGroups,
                muscleGroupPoints: muscleGroupPoints,
                isFront: false,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class MannequinPainter extends CustomPainter {
  final List<String> selectedGroups;
  final Map<String, int> muscleGroupPoints;
  final bool isFront;

  MannequinPainter({
    required this.selectedGroups,
    required this.muscleGroupPoints,
    required this.isFront,
  });

  Color _getGroupColor(String group, double intensity) {
    Color baseColor;
    switch (group.toLowerCase()) {
      case 'arms':
        baseColor = Colors.red;
        break;
      case 'chest':
        baseColor = Colors.blue;
        break;
      case 'back':
        baseColor = Colors.green;
        break;
      case 'abs':
        baseColor = Colors.purple;
        break;
      case 'legs':
        baseColor = const Color(0xFFFF6B00);
        break;
      default:
        baseColor = Colors.grey;
    }
    return baseColor.withOpacity(0.3 + (intensity * 0.7));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Draw outline
    paint.color = Colors.grey[300]!;
    paint.style = PaintingStyle.stroke;
    
    // Simple mannequin shape
    final path = Path();
    
    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.1),
        width: size.width * 0.3,
        height: size.height * 0.12,
      ),
      paint,
    );
    
    // Body outline
    path.moveTo(size.width * 0.35, size.height * 0.18);
    path.lineTo(size.width * 0.35, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.95);
    path.moveTo(size.width * 0.65, size.height * 0.18);
    path.lineTo(size.width * 0.65, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.95);
    
    // Arms
    path.moveTo(size.width * 0.35, size.height * 0.2);
    path.lineTo(size.width * 0.1, size.height * 0.45);
    path.moveTo(size.width * 0.65, size.height * 0.2);
    path.lineTo(size.width * 0.9, size.height * 0.45);
    
    canvas.drawPath(path, paint);
    
    // Fill selected muscle groups with heat map colors
    paint.style = PaintingStyle.fill;
    
    for (String group in selectedGroups) {
      final intensity = (muscleGroupPoints[group] ?? 0) / 100.0;
      paint.color = _getGroupColor(group, intensity.clamp(0.0, 1.0));
      
      // Draw muscle regions based on group
      switch (group.toLowerCase()) {
        case 'arms':
          // Left arm
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width * 0.05, size.height * 0.2, size.width * 0.15, size.height * 0.25),
              const Radius.circular(10),
            ),
            paint,
          );
          // Right arm
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width * 0.8, size.height * 0.2, size.width * 0.15, size.height * 0.25),
              const Radius.circular(10),
            ),
            paint,
          );
          break;
          
        case 'chest':
          if (isFront) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(size.width * 0.3, size.height * 0.2, size.width * 0.4, size.height * 0.15),
                const Radius.circular(10),
              ),
              paint,
            );
          }
          break;
          
        case 'back':
          if (!isFront) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(size.width * 0.3, size.height * 0.2, size.width * 0.4, size.height * 0.2),
                const Radius.circular(10),
              ),
              paint,
            );
          }
          break;
          
        case 'abs':
          if (isFront) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(size.width * 0.35, size.height * 0.35, size.width * 0.3, size.height * 0.15),
                const Radius.circular(10),
              ),
              paint,
            );
          }
          break;
          
        case 'legs':
          // Left leg
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width * 0.25, size.height * 0.5, size.width * 0.15, size.height * 0.45),
              const Radius.circular(10),
            ),
            paint,
          );
          // Right leg
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width * 0.6, size.height * 0.5, size.width * 0.15, size.height * 0.45),
              const Radius.circular(10),
            ),
            paint,
          );
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}