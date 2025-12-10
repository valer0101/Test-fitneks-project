import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';

class TrainerDetailsSection extends StatelessWidget {
  final PublicProfileModel profile;

  const TrainerDetailsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.specialties != null && profile.specialties!.isNotEmpty) ...[
            const Text(
              'Specialties',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.specialties!
                  .map((specialty) => Chip(
                        label: Text(specialty),
                        backgroundColor: const Color(0xFFFF6B00).withOpacity(0.1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (profile.calendarEvents != null && profile.calendarEvents!.isNotEmpty) ...[
            const Text(
              'Upcoming Sessions & Challenges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...profile.calendarEvents!.map((event) => ListTile(
                  leading: Icon(
                    event.type == 'SESSION' ? Icons.fitness_center : Icons.emoji_events,
                    color: const Color(0xFFFF6B00),
                  ),
                  title: Text(event.type),
                  subtitle: Text(event.date),
                )),
          ],
        ],
      ),
    );
  }
}