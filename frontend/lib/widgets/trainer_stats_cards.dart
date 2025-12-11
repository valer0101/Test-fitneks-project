import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';
import '../app_theme.dart';

class TrainerStatsCards extends StatelessWidget {
  final PublicProfileModel profile;

  const TrainerStatsCards({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Trainer Level',
              '${profile.stats.trainerLevel ?? 0}',
              AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Lifetime Sessions',
              '${profile.stats.lifetimeSessions}',
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Lifetime Challenges',
              '${profile.stats.lifetimeChallenges}',
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildStatCard(String label, String value, Color color) {
  return Container(
    height: 120, // ADD THIS - fixed height
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 5,
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, // ADD THIS
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2, // ADD THIS - allow wrapping
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
}