import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import './grade_learner_dialog.dart';

/// Shows floating notifications when learners request grades
class GradeRequestNotification extends ConsumerWidget {
  final String livestreamId;
  
  const GradeRequestNotification({
    Key? key,
    required this.livestreamId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeRequests = ref.watch(gradeRequestProvider(livestreamId));
    
    if (gradeRequests.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Show the most recent request
    final latestRequest = gradeRequests.last;
    
    return Positioned(
      top: 80,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D00),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${latestRequest.userName} requests points!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gradeRequests.length > 1)
                      Text(
                        '+${gradeRequests.length - 1} more',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () => _showGradeDialog(context, ref, latestRequest),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGradeDialog(BuildContext context, WidgetRef ref, GradeRequest request) {
    showDialog(
      context: context,
      builder: (dialogContext) => GradeLearnerDialog(
        livestreamId: livestreamId,
        learnerId: request.userId,
        learnerName: request.userName,
      ),
    ).then((_) {
      // Remove the request after dialog closes
      ref.read(gradeRequestProvider(livestreamId).notifier)
        .removeRequest(request.userId);
    });
  }
}