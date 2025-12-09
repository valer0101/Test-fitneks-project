import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/public_profile_model.dart';
import '../services/profiles_service.dart';
import '../providers/profile_provider.dart';
import '../providers/public_profile_provider.dart';
import '../providers/auth_provider.dart';  
import '../providers/friends_provider.dart';  
import '../services/firestore_service.dart';  
import '../providers/live_stream_provider.dart';  // ✅ ADD THIS - contains firestoreServiceProvider


class FollowActionButton extends ConsumerStatefulWidget {
  final PublicProfileModel profile;
  final String? livestreamId;  // ✅ ADD THIS - optional for livestream context
  
  const FollowActionButton({
    Key? key, 
    required this.profile,
    this.livestreamId,  // ✅ ADD THIS
  }) : super(key: key);

  @override
  ConsumerState<FollowActionButton> createState() => _FollowActionButtonState();
}

class _FollowActionButtonState extends ConsumerState<FollowActionButton> {
  bool isLoading = false;

  String get buttonText {
    if (widget.profile.viewerContext.viewerIsFollowing) {
      return 'Following';
    } else if (widget.profile.viewerContext.profileIsFollowingViewer) {
      return 'Follow Back';
    } else if (!widget.profile.isPublic) {
      return 'Request to Follow';
    } else {
      return 'Follow';
    }
  }

  Future<void> _handleFollow() async {
  setState(() => isLoading = true);
  
  try {
    final service = ref.read(profilesServiceProvider);
    
    if (widget.profile.viewerContext.viewerIsFollowing) {
      // ✅ Unfollowing with error handling
      try {
        await service.unfollowUser(widget.profile.username);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed ${widget.profile.displayName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // ✅ Handle 500 error gracefully - user might already be unfollowed
        if (e.toString().contains('500') || e.toString().contains('Failed to unfollow')) {
          print('⚠️ Unfollow error (likely already unfollowed): $e');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Follow state was out of sync. Refreshing...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          rethrow;
        }
      }
    } else {
      // ✅ Following
      await service.followUser(widget.profile.username);
      
      // ✅ Record follow in livestream chat if we're in a livestream
      if (widget.livestreamId != null) {
        final authState = ref.read(authProvider);
        final currentUser = authState.user;
        
        if (currentUser != null) {
          try {
            final firestoreService = ref.read(firestoreServiceProvider);
            await firestoreService.recordFollowInLivestream(
              livestreamId: widget.livestreamId!,
              followerId: currentUser.id.toString(),
              followerName: currentUser.displayName ?? currentUser.username,
              trainerId: widget.profile.id.toString(),
            );
            print('👥 Follow recorded in livestream chat');
          } catch (e) {
            print('⚠️ Failed to record follow in livestream: $e');
          }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following ${widget.profile.displayName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    
    // ✅ CRITICAL: Always invalidate profile cache
      ref.invalidate(userProfileProvider(widget.profile.username));

      // ✅ NEW: Invalidate friends provider so Friends page updates
      ref.invalidate(friendsProvider);
    
  } catch (e) {
    print('❌ Follow/Unfollow error: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.profile.viewerContext.viewerIsFollowing
            ? Colors.grey[300]
            : const Color(0xFFFF6B00),
        foregroundColor: widget.profile.viewerContext.viewerIsFollowing
            ? Colors.black
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(buttonText),
    );
  }
}