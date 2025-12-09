import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';  // ✅ ADD THIS
import 'dart:typed_data';  // ✅ ADD THIS
import '../../providers/live_stream_provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/public_profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../models/public_profile_model.dart';



class ViewerTallyWidget extends ConsumerWidget {
  final String livestreamId;
  final bool isMobile;
  
  const ViewerTallyWidget({
    Key? key,
    required this.livestreamId,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final streamState = ref.watch(liveStreamProvider(livestreamId));
    final maxViewers = streamState.livestream?.maxParticipants ?? 150;
    final currentViewers = roomState.viewerCount;
    
    return GestureDetector(
      onTap: () => _showViewersDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D00).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF4D00),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility, color: Color(0xFFFF4D00), size: 16),
            const SizedBox(width: 6),
            Text(
              '$currentViewers/$maxViewers',
              style: const TextStyle(
                color: Color(0xFFFF4D00),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'working out now',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

 void _showViewersDialog(BuildContext context, WidgetRef ref) {
  final participants = ref.read(roomProvider).remoteParticipants;
  
  print('🔍 [ViewerTally] Opening dialog with ${participants.length} participants');
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF242424),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Current Viewers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: participants.isEmpty
                  ? const Center(
                      child: Text(
                        'No viewers yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        final participantName = participant.name ?? 'Learner';

                        String? userId;
                        String? username;
                        
                        try {
                          final metadata = participant.metadata;
                          
                          if (metadata != null && metadata.isNotEmpty) {
                            try {
                              final metadataJson = json.decode(metadata);
                              userId = metadataJson['userId']?.toString();
                              username = metadataJson['userName']?.toString();
                            } catch (jsonError) {
                              final userIdMatch = RegExp(r'"userId":"?(\d+)"?').firstMatch(metadata);
                              userId = userIdMatch?.group(1);
                              
                              final usernameMatch = RegExp(r'"userName":"?([^"]+)"?').firstMatch(metadata);
                              username = usernameMatch?.group(1);
                            }
                          }
                        } catch (e) {
                          print('❌ Error parsing metadata: $e');
                        }
                        
                        final finalUsername = username ?? participantName;
                        
                        // ✅ CRITICAL: Use Consumer for each row
                        return Consumer(
                          builder: (context, ref, child) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFF4D00).withOpacity(0.3),
                                child: Text(
                                  participantName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                participantName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_isSelf(ref, userId))
                                    _buildFollowButtonSimple(context, ref, finalUsername, userId),
                                  
                                  if (_isTrainer(ref)) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () {
                                        _showRemoveConfirmation(
                                          context, 
                                          ref, 
                                          participantName,
                                          userId,
                                          participant.sid,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ✅ NEW: Simplified follow button without StateSetter
Widget _buildFollowButtonSimple(
  BuildContext context,
  WidgetRef ref,
  String username,
  String? userId,
) {
  if (userId == null) {
    return const SizedBox.shrink();
  }

  print('🔍 [_buildFollowButton] Loading profile for username: $username');

  final profileAsync = ref.watch(userProfileProvider(username));
  
  return profileAsync.when(
    data: (profile) {
      print('🔍 [_buildFollowButton] Loaded profile: ${profile.username} (ID: ${profile.id})');
      
      final isFollowing = profile.viewerContext.viewerIsFollowing;
      
      if (isFollowing) {
        return ElevatedButton(
          onPressed: () => _unfollowUserSimple(context, ref, profile),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'Following',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
      
      return ElevatedButton(
        onPressed: () => _followUserSimple(context, ref, profile),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4D00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    },
    loading: () => SizedBox(
      width: 70,
      height: 30,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFF4D00),
          ),
        ),
      ),
    ),
    error: (error, stack) {
      print('❌ Error loading profile: $error');
      
      return ElevatedButton(
        onPressed: () {
          ref.invalidate(userProfileProvider(username));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4D00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    },
  );
}

// ✅ NEW: Follow without StateSetter
Future<void> _followUserSimple(
  BuildContext context,
  WidgetRef ref,
  PublicProfileModel profile,
) async {
  try {
    final service = ref.read(profilesServiceProvider);
    await service.followUser(profile.username);
    
    ref.invalidate(userProfileProvider(profile.username));
    ref.invalidate(friendsProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Now following ${profile.displayName ?? profile.username}!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to follow: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ✅ NEW: Unfollow without StateSetter
Future<void> _unfollowUserSimple(
  BuildContext context,
  WidgetRef ref,
  PublicProfileModel profile,
) async {
  try {
    final service = ref.read(profilesServiceProvider);
    await service.unfollowUser(profile.username);
    
    ref.invalidate(userProfileProvider(profile.username));
    ref.invalidate(friendsProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unfollowed ${profile.displayName ?? profile.username}')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfollow: $e'), backgroundColor: Colors.red),
      );
    }
  }
}




// Check if this participant is the current user
bool _isSelf(WidgetRef ref, String? targetUserId) {
  if (targetUserId == null) return true;
  
  final currentUser = ref.read(authProvider).user;
  return currentUser?.id.toString() == targetUserId;
}

// Check if current user is a trainer
bool _isTrainer(WidgetRef ref) {
  final roomState = ref.read(roomProvider);
  final room = roomState.room;
  
  if (room == null) return false;
  
  final localParticipant = room.localParticipant;
  if (localParticipant == null) return false;
  
  try {
    final metadata = localParticipant.metadata;
    if (metadata != null && metadata.isNotEmpty) {
      final metadataJson = json.decode(metadata);
      final role = metadataJson['role']?.toString();
      return role == 'trainer';
    }
  } catch (e) {
    print('❌ Error checking trainer role: $e');
  }
  
  return false;
}

// Build follow button with async profile loading
Widget _buildFollowButton(
  BuildContext context,
  WidgetRef ref,
  String username,
  String? userId,
  StateSetter setDialogState,
) {
  if (userId == null) {
    return const SizedBox.shrink();
  }

  print('🔍 [_buildFollowButton] Loading profile for username: $username');

  final profileAsync = ref.watch(userProfileProvider(username));
  
  return profileAsync.when(
    data: (profile) {
      print('🔍 [_buildFollowButton] Loaded profile: ${profile.username} (ID: ${profile.id})');  // ✅ ADD THIS
      
      final isFollowing = profile.viewerContext.viewerIsFollowing;
      
      if (isFollowing) {
        // Already following - gray button with unfollow capability
        return ElevatedButton(
          onPressed: () => _unfollowUserSimple(context, ref, profile),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),  // ✅ MATCH PADDING
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'Following',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
      
      // Not following - orange Follow button
      return ElevatedButton(
        onPressed: () => _followUserSimple(context, ref, profile),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4D00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),  // ✅ CONSISTENT PADDING
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    },
    loading: () => SizedBox(
      width: 70,
      height: 30,  // ✅ FIXED HEIGHT FOR LOADING STATE
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFF4D00),
          ),
        ),
      ),
    ),
   error: (error, stack) {
  print('❌ Error loading profile for follow button: $error');
  print('❌ Stack trace: $stack');  // ✅ ADD THIS
  
  // Show clickable Follow button on error
  return ElevatedButton(
    onPressed: () async {
      print('🔄 Retrying profile load for: $username');  // ✅ ADD THIS
      ref.invalidate(userProfileProvider(username));
      await Future.delayed(Duration(milliseconds: 100));
      setDialogState(() {});
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF4D00),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: const Text(
      'Follow',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
},
  );
}



  void _showRemoveConfirmation(
    BuildContext context, 
    WidgetRef ref, 
    String userName,
    String? userId,
    String participantSid,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text(
          'Remove User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently remove $userName from this livestream?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'They will be kicked immediately and cannot rejoin.',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog
              await _removeParticipant(context, ref, userId, participantSid, userName);
            },
            child: const Text('Remove Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeParticipant(
  BuildContext context,
  WidgetRef ref,
  String? userId,
  String participantSid,
  String userName,
) async {
  if (userId == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not identify user to remove'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Store the navigator for safe popping after async operations
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const Center(
      child: CircularProgressIndicator(color: Color(0xFFFF4D00)),
    ),
  );

  try {
    final authState = ref.read(authProvider);
    final token = authState.token;
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final apiService = ref.read(apiServiceProvider);
    
    print('🚫 ========================================');
    print('🚫 REMOVING PARTICIPANT');
    print('🚫 Name: $userName');
    print('🚫 User ID: $userId (type: ${userId.runtimeType})');
    print('🚫 Participant SID: $participantSid');
    print('🚫 Livestream ID: $livestreamId');
    print('🚫 ========================================');

    // Step 1: Call backend to ban user from stream
    print('🚫 Step 1: Calling backend API to ban user...');
    final response = await apiService.post(
      '/api/livestreams/$livestreamId/remove-participant',
      {
        'userId': userId,  // Send as string - backend will parse it
        'participantSid': participantSid,
      },
      token: token,
    );
    
    print('✅ Backend response: $response');

    // Step 2: Kick from LiveKit room via data message
    print('🚫 Step 2: Sending kick message via LiveKit...');
    final roomNotifier = ref.read(roomProvider.notifier);
    await roomNotifier.publishData({
      'type': 'kick',
      'targetSid': participantSid,
      'userId': userId,
      'reason': 'Removed by trainer',
    });

    print('✅ Kick message sent via LiveKit');
    print('🚫 ========================================');

    // Close dialogs and show success - use stored navigator
    navigator.pop(); // Close loading dialog
    navigator.pop(); // Close viewers dialog
    
    messenger.showSnackBar(
      SnackBar(
        content: Text('$userName has been permanently removed and banned'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    print('❌ ========================================');
    print('❌ ERROR REMOVING PARTICIPANT');
    print('❌ Error: $e');
    print('❌ Stack trace: ${StackTrace.current}');
    print('❌ ========================================');
    
    // Close loading dialog and show error - use stored navigator
    navigator.pop(); // Close loading dialog
    
    messenger.showSnackBar(
      SnackBar(
        content: Text('Failed to remove user: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
}