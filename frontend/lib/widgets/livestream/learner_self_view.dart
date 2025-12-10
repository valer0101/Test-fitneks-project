import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/live_stream_provider.dart';

/// Shows the learner's own video when they're participating
/// Includes controls to request points or stop sharing video
class LearnerSelfView extends ConsumerWidget {
  final String livestreamId;
  final VoidCallback onRequestGrade;
  final VoidCallback onStopSharing;

  const LearnerSelfView({
    super.key,
    required this.livestreamId,
    required this.onRequestGrade,
    required this.onStopSharing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final localParticipant = roomState.localParticipant;
    
    // If not connected yet, show loading
    if (localParticipant == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4D00),
        ),
      );
    }
    
    // Find video track
    // Find video track - check both published and unpublished tracks
VideoTrack? videoTrack;

// First try published tracks
for (final pub in localParticipant.trackPublications.values) {
  if (pub.kind == TrackType.VIDEO && pub.track != null) {
    videoTrack = pub.track as VideoTrack;
    break;
  }
}

// If no published track, try local tracks directly
// If no video and camera not enabled, show message
if (videoTrack == null && !roomState.isCameraEnabled) {
  return const Center(
    child: Text(
      'Camera not enabled',
      style: TextStyle(color: Colors.grey),
    ),
  );
}

// If camera is enabled but no video track yet, show loading
if (videoTrack == null && roomState.isCameraEnabled) {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Color(0xFFFF4D00)),
        SizedBox(height: 8),
        Text('Initializing camera...', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}

// Also check camera state from room provider as fallback
final isCameraEnabled = roomState.isCameraEnabled;
print('🎥 Video track found: ${videoTrack != null}, Camera enabled: $isCameraEnabled');
    
  return Container(
  width: double.infinity,
  height: double.infinity,
  color: Colors.black,
  child: Stack(
    fit: StackFit.expand,
    children: [
      // Mirrored video
      if (videoTrack != null)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
          child: VideoTrackRenderer(
            videoTrack,
            fit: VideoViewFit.cover,
          ),
        ),
      
      // If no video track, show placeholder
      if (videoTrack == null)
        Container(
          color: Colors.grey[800],
          child: const Center(
            child: Text(
              'Camera initializing...',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
          
      // Close button (top right)
      Positioned(
        top: 8,
        right: 8,
        child: CircleAvatar(
          backgroundColor: Colors.red,
          radius: 18,
          child: IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white,
            padding: EdgeInsets.zero,
            onPressed: onStopSharing,
          ),
        ),
      ),
      
      // Request Points button (bottom center)
      Positioned(
        bottom: 16,
        left: 0,
        right: 0,
        child: Center(
          child: ElevatedButton.icon(
            onPressed: onRequestGrade,
            icon: const Icon(Icons.star),
            label: const Text('REQUEST POINTS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ),
      
      // Microphone indicator (bottom left)
      Positioned(
        bottom: 16,
        left: 16,
        child: CircleAvatar(
          backgroundColor: roomState.isMicEnabled 
              ? const Color(0xFF2B5FFF)
              : Colors.grey,
          radius: 16,
          child: Icon(
            roomState.isMicEnabled ? Icons.mic : Icons.mic_off,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    ],
  ),
);
  }
}