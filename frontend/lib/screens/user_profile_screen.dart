import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/public_profile_model.dart';
import '../providers/public_profile_provider.dart';
import 'package:go_router/go_router.dart';
import '../strategies/profile_strategy_factory.dart';
import '../widgets/public_profile_header.dart';

class UserProfileScreen extends ConsumerWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(username));

    return Scaffold(
      appBar: AppBar(
  leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/trainer-dashboard'),
),
  title: Text('@$username'),
  backgroundColor: const Color(0xFF4A4A4A),
  foregroundColor: Colors.white,
),
      body: profileAsync.when(
        data: (profile) => _buildProfile(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider(username)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, PublicProfileModel profile) {
    final strategy = ProfileStrategyFactory.getStrategy(profile.userType);
    final canViewAdvancedContent = 
        profile.isPublic || profile.viewerContext.viewerIsFollowing;

    return SingleChildScrollView(
      child: Column(
        children: [
          PublicProfileHeader(profile: profile),
          strategy.buildStatsCards(context, profile),
          strategy.buildDetailsSection(context, profile, canViewAdvancedContent),
        ],
      ),
    );
  }
}