import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/live_stream_provider.dart';

/// Shows the learner's own video when they're participating
/// Includes controls to request points or stop sharing video
class LearnerSelfView extends ConsumerStatefulWidget {
  final String livestreamId;
  final VoidCallback onRequestGrade;
  final VoidCallback onStopSharing;

  const LearnerSelfView({
    Key? key,
    required this.livestreamId,
    required this.onRequestGrade,
    required this.onStopSharing,
  }) : super(key: key);

  @override
  ConsumerState<LearnerSelfView> createState() => _LearnerSelfViewState();
}

class _LearnerSelfViewState extends ConsumerState<LearnerSelfView> {
  EventsListener<RoomEvent>? _roomListener;

  @override
  void initState() {
    super.initState();
    _setupMicStateListener();
  }

  @override
  void dispose() {
    _roomListener?.dispose();
    super.dispose();
  }

  // ✅ NEW: Listen for mic mute/unmute events
  void _setupMicStateListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final room = ref.read(roomProvider).room;
      if (room == null) return;

      _roomListener = room.createListener();
      
      // Listen for local audio track muted/unmuted
      _roomListener!.on<TrackMutedEvent>((event) {
        if (event.participant is LocalParticipant && 
            event.publication.kind == TrackType.AUDIO) {
          print('🔇 Local mic muted by trainer');
          if (mounted) setState(() {});
        }
      });

      _roomListener!.on<TrackUnmutedEvent>((event) {
        if (event.participant is LocalParticipant && 
            event.publication.kind == TrackType.AUDIO) {
          print('🔊 Local mic unmuted by trainer');
          if (mounted) setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {  // ✅ FIXED: Removed WidgetRef parameter
    final roomState = ref.watch(roomProvider);
    final localParticipant = roomState.localParticipant;
    
    // If not connected yet, show loading
    if (localParticipant == null) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4D00),
        ),
      );
    }
    
    // Find video track
    VideoTrack? videoTrack;

    // First try published tracks
    for (final pub in localParticipant.trackPublications.values) {
      if (pub.kind == TrackType.VIDEO && pub.track != null) {
        videoTrack = pub.track as VideoTrack;
        break;
      }
    }

    // If no video and camera not enabled, show message
    if (videoTrack == null && !roomState.isCameraEnabled) {
      return Center(
        child: Text(
          'Camera not enabled',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // If camera is enabled but no video track yet, show loading
    if (videoTrack == null && roomState.isCameraEnabled) {
      return Center(
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

    // ✅ Check ACTUAL mic state from the local participant's audio track
    bool isMicEnabled = roomState.isMicEnabled;
    final audioPublication = localParticipant.audioTrackPublications.firstOrNull;
    if (audioPublication != null) {
      // Use the actual track mute state (trainer can change this)
      isMicEnabled = !(audioPublication.muted ?? true);
    }

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
                videoTrack!,
                fit: VideoViewFit.cover,
              ),
            ),
          
          // If no video track, show placeholder
          if (videoTrack == null)
            Container(
              color: Colors.grey[800],
              child: Center(
                child: Text(
                  'Camera initializing...',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
              
          // Close button (top right) - More transparent red
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: widget.onStopSharing,  // ✅ FIXED: Added 'widget.'
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFFD32F2F).withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
        // Request Points button (top left)
          Positioned(
            top: 12,
            left: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onRequestGrade,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D00),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'REQUEST POINTS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Microphone toggle button (bottom left) - Minimalist, no outline
          Positioned(
            bottom: 16,
            left: 16,
            child: GestureDetector(
              onTap: () async {
                // Only allow toggle if not muted by trainer
                if (audioPublication?.muted ?? false) {
                  // Show message that trainer has control
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Trainer has muted your microphone'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                
                // Toggle microphone on/off
                final newState = !isMicEnabled;
                print('🎤 Toggling microphone: $isMicEnabled → $newState');
                await ref.read(roomProvider.notifier).enableMicrophone(newState);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMicEnabled ? Icons.mic : Icons.mic_off,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}