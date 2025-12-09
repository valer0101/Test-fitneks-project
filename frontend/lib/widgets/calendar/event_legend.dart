import 'package:flutter/material.dart';

class EventLegend extends StatelessWidget {
  const EventLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                Colors.orange,
                'Upcoming Sessions',
                filled: true,
              ),
              _buildLegendItem(
                Colors.orange,
                'Completed Sessions',
                filled: false,
              ),
              _buildLegendItem(
                Colors.blue,
                'Upcoming Challenges',
                filled: true,
              ),
              _buildLegendItem(
                Colors.blue,
                'Completed Challenges',
                filled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {required bool filled}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}