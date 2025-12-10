// lib/widgets/profile_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import 'gradient_elevated_button.dart';

class ProfileHeader extends ConsumerWidget {
  final bool isLearner;
  
  const ProfileHeader({
    super.key,
    this.isLearner = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return profileAsync.when(
      data: (profile) {
        // --- MERGE LOGIC: Calculate progress based on the profile's XP ---
        final xpInCurrentLevel = profile.xp % 100;
        final xpToNextLevel = 100 - xpInCurrentLevel;
        final xpProgress = xpInCurrentLevel / 100.0;
        
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFA500),
                Color(0xFFFF6B00),
              ],
            ),
          ),
          child: Column(
            children: [
              // Profile Picture and Info Section
              Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 40), // For spacing
                        Expanded(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: isDesktop ? 150 : 120,
                                    height: isDesktop ? 150 : 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      image: DecorationImage(
                                        image: profile.profilePictureUrl != null && profile.profilePictureUrl!.isNotEmpty
                                          ? NetworkImage(profile.profilePictureUrl!)
                                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                profile.displayName ?? 'N/A',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '@${profile.username ?? 'n/a'}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isDesktop ? 16 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Navigate to edit profile
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          context,
                          label: 'XP',
                          value: profile.xp.toString(),
                          isDesktop: isDesktop,
                        ),
                        _buildStatItem(
                          context,
                          label: 'LVL',
                          value: profile.level.toString(),
                          isDesktop: isDesktop,
                        ),
                        _buildStatItem(
                          context,
                          label: 'Rubies',
                          value: profile.rubies.toString(),
                          isDesktop: isDesktop,
                          onTap: () => _showBuyRubiesDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // XP Progress Bar
                    Column(
                      children: [
                        Text(
                          'Earn $xpToNextLevel xp to reach Level ${profile.level + 1}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isDesktop ? 14 : 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: xpProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Go Live Button
                    GradientElevatedButton(
                      onPressed: () => _showGoLiveDialog(context),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.symmetric(
                            horizontal: isDesktop ? 48 : 32,
                            vertical: isDesktop ? 16 : 12,
                          ),
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        textStyle: MaterialStateProperty.all<TextStyle>(
                          TextStyle(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      child: Text(
                        'GO LIVE',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 400,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFA500),
              Color(0xFFFF6B00),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
      error: (error, stack) => Container(
        height: 400,
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFA500),
              Color(0xFFFF6B00),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load profile details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).refreshProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF6B00),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDesktop,
    VoidCallback? onTap,
  }) {
    final widget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
  }

  void _showBuyRubiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buy Rubies'),
        content: const Text('Ruby purchase functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGoLiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Live'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Create Class'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create class
              },
            ),
            ListTile(
              title: const Text('Create Challenge'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create challenge
              },
            ),
          ],
        ),
      ),
    );
  }
}