import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/live_stream_provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';

/// Shared widget for rendering a single learner participant tile
/// Used by both LearnerGridView and LearnerHorizontalView
class LearnerParticipantTile extends ConsumerStatefulWidget {
  final RemoteParticipant participant;
  final int index;
  final String livestreamId;
  final bool isMobile;
  final String? selectedLearnerId;
  final Function(String)? onLearnerTap;
  final bool showFullscreenIcon;
  final bool showTrainerControls;  
  
  const LearnerParticipantTile({
    Key? key,
    required this.participant,
    required this.index,
    required this.livestreamId,
    this.isMobile = false,
    this.selectedLearnerId,
    this.onLearnerTap,
    this.showFullscreenIcon = false,
    this.showTrainerControls = false,  
  }) : super(key: key);

  @override
  ConsumerState<LearnerParticipantTile> createState() => _LearnerParticipantTileState();
}

class _LearnerParticipantTileState extends ConsumerState<LearnerParticipantTile> {
  
  @override
  Widget build(BuildContext context) {
    final videoPublication = widget.participant.videoTrackPublications.firstOrNull;
    final audioPublication = widget.participant.audioTrackPublications.firstOrNull;
    final isAudioEnabled = audioPublication != null && !(audioPublication.muted ?? true);
    
    VideoTrack? videoTrack;
    if (videoPublication != null && videoPublication.track != null) {
      videoTrack = videoPublication.track as VideoTrack;
    }

    return GestureDetector(
      onTap: widget.onLearnerTap != null 
          ? () => widget.onLearnerTap!(widget.participant.sid)
          : () => _showParticipantOptions(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.participant.sid == widget.selectedLearnerId
                ? const Color(0xFFFF4D00)
                : Colors.grey[800]!,
            width: widget.participant.sid == widget.selectedLearnerId ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Video or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: videoTrack != null
                  ? VideoTrackRenderer(
                      videoTrack,
                      fit: VideoViewFit.cover,
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: widget.isMobile ? 20 : 30,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                widget.participant.name?.substring(0, 1).toUpperCase() ?? 'L',
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 16 : 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera off',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Fullscreen icon indicator (top left)
            if (widget.showFullscreenIcon && !widget.isMobile)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            
            // ✅ TRAINER-ONLY CONTROLS
            if (widget.showTrainerControls) ...[
              // Remove video button (top right)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeLearnerVideo,
                  child: Container(
                    width: widget.isMobile ? 28 : 36,
                    height: widget.isMobile ? 28 : 36,
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
                      size: widget.isMobile ? 16 : 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Microphone toggle button (bottom left)
              Positioned(
                bottom: widget.isMobile ? 32 : 40,
                left: 8,
                child: GestureDetector(
                  onTap: _toggleParticipantMute,
                  child: Container(
                    width: widget.isMobile ? 32 : 40,
                    height: widget.isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAudioEnabled ? Icons.mic : Icons.mic_off,
                      size: widget.isMobile ? 16 : 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            
            // Name overlay (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.participant.name ?? 'Learner ${widget.index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantOptions() {
    print('🎯 Showing options for participant: ${widget.participant.identity}');
    // TODO: Implement participant options dialog for grading, etc.
  }

  void _toggleParticipantMute() async {
    final audioPublication = widget.participant.audioTrackPublications.firstOrNull;
    
    if (audioPublication == null) {
      print('⚠️ No audio track found for participant: ${widget.participant.name}');
      return;
    }
    
    final isCurrentlyMuted = audioPublication.muted;
    
    try {
      print('🔇 Muting ${widget.participant.name} via backend: $isCurrentlyMuted -> ${!isCurrentlyMuted}');
      
      // Get the auth token from authProvider
      final authState = ref.read(authProvider);
      final token = authState.token;
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !isCurrentlyMuted 
                  ? 'Muting ${widget.participant.name ?? "Learner"}...' 
                  : 'Unmuting ${widget.participant.name ?? "Learner"}...',
            ),
            backgroundColor: const Color(0xFFFF4D00),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // Call backend API to mute the participant
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/livestreams/${widget.livestreamId}/mute-participant'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'participantIdentity': widget.participant.identity,
          'muted': !isCurrentlyMuted,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Successfully ${!isCurrentlyMuted ? "muted" : "unmuted"} ${widget.participant.name}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                !isCurrentlyMuted 
                    ? '${widget.participant.name ?? "Learner"} muted' 
                    : '${widget.participant.name ?? "Learner"} unmuted',
              ),
              backgroundColor: const Color(0xFFFF4D00),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to mute participant: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Error muting participant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mute participant: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeLearnerVideo() async {
    try {
      print('🚫 Removing learner video: ${widget.participant.name}');
      
      final roomNotifier = ref.read(roomProvider.notifier);
      await roomNotifier.publishData({
        'event': 'remove_video',
        'learnerId': widget.participant.identity.replaceFirst('learner_', ''),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${widget.participant.name ?? "learner"} from video'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error removing learner: $e');
    }
  }
}