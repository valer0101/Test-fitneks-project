import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/live_stream_provider.dart';
import '../../providers/auth_provider.dart';



class TrainerSelfView extends ConsumerWidget {
  final String livestreamId;
  
  const TrainerSelfView({
    Key? key,
    required this.livestreamId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final streamState = ref.watch(liveStreamProvider(livestreamId));
    
    if (!roomState.isConnected || roomState.localParticipant == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4D00)),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Video feed
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: roomState.isCameraEnabled
                ? _buildVideoView(roomState.localParticipant!)
                : _buildPlaceholder(streamState, ref),
          ),
        ),
        
        // Control overlay
        Positioned(
          bottom: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mic button
              _buildControlButton(
                icon: roomState.isMicEnabled ? Icons.mic : Icons.mic_off,
                onPressed: () => ref.read(roomProvider.notifier).enableMicrophone(!roomState.isMicEnabled),
                backgroundColor: roomState.isMicEnabled ? Colors.white24 : Colors.red,
              ),
              const SizedBox(width: 16),
              
              // Camera button
              _buildControlButton(
                icon: roomState.isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                onPressed: () => ref.read(roomProvider.notifier).enableCamera(!roomState.isCameraEnabled),
                backgroundColor: roomState.isCameraEnabled ? Colors.white24 : Colors.red,
              ),
            ],
          ),
        ),
        
      
      ],
    );
  }

 Widget _buildVideoView(LocalParticipant participant) {
  final videoTrack = participant.videoTrackPublications.firstOrNull?.track as VideoTrack?;
    
  if (videoTrack != null) {
    return VideoTrackRenderer(
      videoTrack,
      fit: VideoViewFit.contain,  // ✅ Changed from cover to contain
      mirrorMode: VideoViewMirrorMode.mirror,
    );
  }
  
  return const Center(
    child: Icon(Icons.videocam_off, color: Colors.white54, size: 64),
  );
}

  Widget _buildPlaceholder(LiveStreamState streamState, WidgetRef ref) {
  // Get user data
  final authState = ref.watch(authProvider);
  final user = authState.user;
  
  // Get initials from user
  String getInitials() {
    if (user == null) return 'TR';
    
    final name = user.displayName ?? user.username;
    final parts = name.split(' ');
    
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
  
  return Container(
    color: Colors.grey[900],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFFF4D00),
            child: Text(
              getInitials(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Camera Off',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
  padding: const EdgeInsets.all(8),  // ✅ Changed from 12
  child: Icon(icon, color: Colors.white, size: 20),  // ✅ Changed from 24
),
      ),
    );
  }
}