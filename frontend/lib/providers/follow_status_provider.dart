import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'public_profile_provider.dart';

/// Simple provider to check if current user is following a specific trainer
/// Returns true if following, false if not following
final isFollowingTrainerProvider = FutureProvider.family<bool, String>((ref, trainerUsername) async {
  try {
    // Get the trainer's public profile
    final profile = await ref.watch(userProfileProvider(trainerUsername).future);
    
    // Check the viewerContext to see if the current user is following
    final isFollowing = profile.viewerContext.viewerIsFollowing;
    
    print('✅ [FollowStatus] User ${isFollowing ? "IS" : "IS NOT"} following $trainerUsername');
    return isFollowing;
    
  } catch (e) {
    print('❌ [FollowStatus] Error checking follow status: $e');
    return false; // Default to not following if error
  }
});