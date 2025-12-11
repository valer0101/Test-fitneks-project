import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../providers/live_stream_provider.dart';

/// Displays video slot availability indicator
/// Shows current slots taken and available slots
class VideoSlotIndicator extends ConsumerWidget {
  final String livestreamId;
  final int maxSlots;
  final bool isMobile;
  final bool isTrainer;  
  final Color? backgroundColor;
  final bool includeLocalParticipant;  
  
  const VideoSlotIndicator({
    Key? key,
    required this.livestreamId,
    this.maxSlots = 4,
    this.isMobile = false,
    this.isTrainer = false,
    this.backgroundColor,
    this.includeLocalParticipant = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    
    // Count learners with video enabled
    final learnerCount = roomState.remoteParticipants.where((participant) {
      final metadata = participant.metadata;
      if (metadata == null || metadata.isEmpty) return false;
      
      try {
        final meta = json.decode(metadata);
        final role = meta['role'];
        if (role == 'learner') {
          final videoPublication = participant.videoTrackPublications.firstOrNull;
          return videoPublication != null && 
                 videoPublication.track != null &&
                 !(videoPublication.muted ?? true);
        }
        return false;
      } catch (e) {
        return false;
      }
    }).length;
    
    // ✅ Include local participant if they're participating with video
    final totalLearners = learnerCount + (includeLocalParticipant ? 1 : 0);
    final availableSlots = maxSlots - learnerCount;
    final isFull = totalLearners >= maxSlots;
    final isAlmostFull = availableSlots == 1;
    
   // Determine color based on availability
        Color indicatorColor;
        String message;

        if (isFull) {
  indicatorColor = Colors.red;
  message = isTrainer 
    ? 'FULL ($totalLearners/$maxSlots)'
    : 'FULL ($totalLearners/$maxSlots) • Join waitlist';
} else if (isAlmostFull) {
  indicatorColor = const Color(0xFFFF4D00);
  message = isTrainer
    ? '$totalLearners/$maxSlots slots • ⚡ 1 left!'
    : includeLocalParticipant
    ? '$totalLearners/$maxSlots Learner slots left • ⚡ 1 left!'
    : '$totalLearners/$maxSlots Learner slots left • ⚡ 1 left! ${isMobile ? 'Tap' : 'Click'} JOIN VIDEO';
} else if (totalLearners == 0) {
  indicatorColor = Colors.white70;
  message = isTrainer
    ? '0/$maxSlots on camera'
    : '0/$maxSlots Learner slots left • ${isMobile ? 'Tap' : 'Click'} JOIN VIDEO';
} else {
  indicatorColor = Colors.white70;
  message = isTrainer
    ? '$totalLearners/$maxSlots slots'
    : includeLocalParticipant
    ? '$totalLearners/$maxSlots Learner slots left'
    : '$totalLearners/$maxSlots Learner slots left • ${isMobile ? 'Tap' : 'Click'} JOIN VIDEO';
}
    
    return Container(
      height: isMobile ? 28 : 32,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withAlpha(127),  // ✅ Changed
        // No border radius - rectangular for seamless connection
        border: Border(
          bottom: BorderSide(
            color: indicatorColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.videocam,
            color: indicatorColor,
            size: isMobile ? 18 : 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: indicatorColor,
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}