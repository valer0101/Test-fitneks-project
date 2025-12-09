import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final double points;
  final int tokens;
  final int rubies;
  final VoidCallback onRubyTap;

  const StatsRow({
    Key? key,
    required this.points,
    required this.tokens,
    required this.rubies,
    required this.onRubyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PTS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            value: points.toStringAsFixed(0),
            label: 'Points',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            icon: Image.asset(
              'assets/icons/fitneks_icon.png',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            value: tokens.toString(),
            label: 'Tokens',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onRubyTap,
            child: _buildStatItem(
              icon: const Icon(
                Icons.diamond,
                color: Colors.red,
                size: 24,
              ),
              value: rubies.toString(),
              label: 'Rubies',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required Widget icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}