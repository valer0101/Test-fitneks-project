import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/live_stream_provider.dart';

/// Displays the trainer's video in fullscreen
/// This is the main video view that learners watch
class TrainerVideoView extends ConsumerWidget {
  final String livestreamId;

  const TrainerVideoView({
    super.key,
    required this.livestreamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get livestream data for trainer info
    final liveStreamState = ref.watch(liveStreamProvider(livestreamId));
    final livestream = liveStreamState.livestream;
    
    // Get the LiveKit room from provider
    final roomState = ref.watch(roomProvider);
    final room = roomState.room;

    // Find the trainer among all remote participants
    RemoteParticipant? trainer;
    VideoTrack? videoTrack;
    
    if (room != null) {
      for (final participant in room.remoteParticipants.values) {
        final metadata = participant.metadata;
        if (metadata != null) {
          try {
            final meta = json.decode(metadata);
            if (meta['role'] == 'trainer') {
              trainer = participant;
              // Get trainer's video track
              for (final pub in trainer.trackPublications.values) {
                if (pub.kind == TrackType.VIDEO && pub.track != null) {
                  videoTrack = pub.track as VideoTrack;
                  break;
                }
              }
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }
    }


  // If we have video, show it
if (videoTrack != null) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.black,
    child: VideoTrackRenderer(
      videoTrack,
      fit: VideoViewFit.contain,
    ),
  );
}


    // Otherwise show trainer profile placeholder
    return _buildTrainerPlaceholder(livestream);
  }

 Widget _buildTrainerPlaceholder(dynamic livestream) {
  // Get trainer info from livestream data
  String trainerName = 'Trainer';
  String? profileUrl;
  
  try {
    if (livestream != null) {
      final livestreamMap = livestream.toJson();
      final trainerData = livestreamMap['trainer'] as Map<String, dynamic>?;
      trainerName = trainerData?['displayName'] ?? trainerData?['username'] ?? 'Trainer';
      profileUrl = trainerData?['profilePictureUrl'];
    }
  } catch (e) {
    // Use defaults
  }

  return Container(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),  // ✅ Moved down to avoid header
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,  // ✅ Changed from center
          children: [
            // Trainer profile picture or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D00),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 3,
                ),
              ),
              child: profileUrl != null
    ? ClipOval(
        child: Image.network(
          profileUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 40,  // ✅ Reduced from 60
              color: Colors.white,
            );
          },
        ),
      )
    : const Icon(
        Icons.person,
        size: 40,  // ✅ Reduced from 60
        color: Colors.white,
      ),
            ),
            
            const SizedBox(height: 24),
            
            // Trainer name
            Text(
              trainerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,  // ✅ Reduced from 24
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,  // ✅ Prevent overflow
              overflow: TextOverflow.ellipsis,  // ✅ Add ellipsis
            ),
            
            const SizedBox(height: 12),
            
            // Status message
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Waiting for trainer video',  // ✅ Updated text
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // ✅ Removed the hint text
          ],
        ),
      ),
    ),
  );
}
}