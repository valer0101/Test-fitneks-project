import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PointsBarChart extends StatelessWidget {
  final String timeframe;
  final List<String> selectedGroups;
  final Map<String, List<double>> data;

  const PointsBarChart({
    super.key,
    required this.timeframe,
    required this.selectedGroups,
    required this.data,
  });

  Color _getGroupColor(String group) {
    switch (group.toLowerCase()) {
      case 'arms':
        return Colors.red;
      case 'chest':
        return Colors.blue;
      case 'back':
        return Colors.green;
      case 'abs':
        return Colors.purple;
      case 'legs':
        return const Color(0xFFFF6B00);
      default:
        return Colors.grey;
    }
  }

  List<String> _getXLabels() {
    if (timeframe == 'week') {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else {
      return ['W1', 'W2', 'W3', 'W4'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _getXLabels();
    const maxY = 25.0;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: List.generate(labels.length, (index) {
            final rodData = <BarChartRodStackItem>[];
            double currentY = 0;
            
            // Create stacked bars for selected muscle groups
            for (final group in selectedGroups) {
              final groupData = data[group];
              if (groupData != null && index < groupData.length) {
                final value = groupData[index];
                rodData.add(
                  BarChartRodStackItem(
                    currentY,
                    currentY + value,
                    _getGroupColor(group),
                  ),
                );
                currentY += value;
              }
            }
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: currentY,
                  color: Colors.transparent,
                  width: 20,
                  rodStackItems: rodData,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}