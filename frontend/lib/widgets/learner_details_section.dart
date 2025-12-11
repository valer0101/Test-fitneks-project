import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';

class LearnerDetailsSection extends StatelessWidget {
  final PublicProfileModel profile;
  final bool canViewAdvancedContent;

  const LearnerDetailsSection({
    Key? key,
    required this.profile,
    required this.canViewAdvancedContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.interests != null && profile.interests!.isNotEmpty) ...[
            const Text(
              'Interests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.interests!
                  .map((interest) => Chip(
                        label: Text(interest),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (profile.goals != null && profile.goals!.isNotEmpty) ...[
            const Text(
              'Goals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.goals!
                  .map((goal) => Chip(
                        label: Text(goal),
                        backgroundColor: Colors.green.withOpacity(0.1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (canViewAdvancedContent && profile.advancedMetrics != null) ...[
            const Text(
              'Advanced Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Charts will be implemented here\n(Weekly Points Graph & Heatmap)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ] else if (!canViewAdvancedContent) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.lock, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Follow this user to see advanced metrics',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}