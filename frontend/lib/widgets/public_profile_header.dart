import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';
import '../widgets/follow_action_button.dart';
import '../app_theme.dart';

class PublicProfileHeader extends StatelessWidget {
  final PublicProfileModel profile;

  const PublicProfileHeader({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.fitneksGradient,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: profile.profilePictureUrl != null
                    ? NetworkImage(profile.profilePictureUrl!)
                    : null,
                child: profile.profilePictureUrl == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    if (profile.liveStatus == 'LIVE')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile.aboutMe != null)
            Text(
              profile.aboutMe!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 16),
          FollowActionButton(profile: profile),
        ],
      ),
    );
  }
}