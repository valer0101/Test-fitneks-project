import 'package:flutter/material.dart';

class GoalProgress extends StatelessWidget {
  final int currentPoints;
  final int goalPoints;

  const GoalProgress({
    Key? key,
    required this.currentPoints,
    required this.goalPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pointsRemaining = goalPoints - currentPoints;
    final progress = (currentPoints / goalPoints).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pointsRemaining > 0 
              ? 'You Are ${pointsRemaining}pts Away From Your Goal'
              : 'Congratulations! You\'ve reached your goal!',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : const Color(0xFFFF6B00),
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentPoints pts',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '$goalPoints pts',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}