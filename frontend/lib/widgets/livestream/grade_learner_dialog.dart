import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import '../../providers/auth_provider.dart';
import '../../app_theme.dart';

class GradeLearnerDialog extends ConsumerStatefulWidget {
  final String livestreamId;
  final String learnerId;
  final String learnerName;
  
  const GradeLearnerDialog({
    Key? key,
    required this.livestreamId,
    required this.learnerId,
    required this.learnerName,
  }) : super(key: key);

  @override
  ConsumerState<GradeLearnerDialog> createState() => _GradeLearnerDialogState();
}

class _GradeLearnerDialogState extends ConsumerState<GradeLearnerDialog> {
  Map<String, int> _currentPoints = {
    'legs': 0,
    'back': 0,
    'abs': 0,
    'chest': 0,
    'arms': 0,
  };
  
  static const int MAX_POINTS_PER_MUSCLE = 5;

  @override
Widget build(BuildContext context) {
  // Get the livestream to check which muscle groups are relevant
  final livestreamState = ref.watch(liveStreamProvider(widget.livestreamId));
  final livestream = livestreamState.livestream;
  
  return Dialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      width: 450,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'GRADE THE LEARNER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Learner info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4CAF50),
                  child: Text(
                    widget.learnerName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16),
                      children: [
                        TextSpan(
                          text: widget.learnerName,
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ' has requested to be graded:',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Muscle point sliders
            ..._buildMuscleSliders(),
            
            const SizedBox(height: 24),
            
            // Total points display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Points',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_getTotalPoints()} points',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _getTotalPoints() > 0 ? _submitGrade : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'SUBMIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  List<Widget> _buildMuscleSliders() {
    final muscles = [
      {'key': 'legs', 'label': 'Legs', 'icon': Icons.directions_run},
      {'key': 'back', 'label': 'Back', 'icon': Icons.fitness_center},
      {'key': 'abs', 'label': 'Abs', 'icon': Icons.camera},
      {'key': 'chest', 'label': 'Chest', 'icon': Icons.favorite},
      {'key': 'arms', 'label': 'Arms', 'icon': Icons.front_hand},
    ];

    return muscles.map((muscle) {
      final key = muscle['key']! as String;
      final label = muscle['label']! as String;
      final icon = muscle['icon']! as IconData;
      final currentValue = _currentPoints[key]!;

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppTheme.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currentValue / $MAX_POINTS_PER_MUSCLE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: currentValue > 0 ? const Color(0xFFFF4D00) : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF4D00),
                inactiveTrackColor: Colors.grey[300],
                thumbColor: const Color(0xFFFF4D00),
                overlayColor: const Color(0xFFFF4D00).withOpacity(0.2),
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: currentValue.toDouble(),
                min: 0,
                max: MAX_POINTS_PER_MUSCLE.toDouble(),
                divisions: MAX_POINTS_PER_MUSCLE,
                onChanged: (value) {
                  setState(() {
                    _currentPoints[key] = value.round();
                  });
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  int _getTotalPoints() {
    return _currentPoints.values.fold(0, (sum, points) => sum + points);
  }

 void _submitGrade() async {
  print('⭐ Submitting grade for ${widget.learnerName}');
  print('⭐ Points: $_currentPoints');
  print('⭐ Total: ${_getTotalPoints()}');
  
  // Get auth token
  final authState = ref.read(authProvider);
  final token = authState.token;
  
  // Call backend API to save points
  try {
    final response = await ref.read(apiServiceProvider).post(
      '/api/livestreams/${widget.livestreamId}/award-points',
      {
        'learnerId': widget.learnerId,
        'points': _currentPoints,
      },
      token: token,
    );
    print('✅ Points saved to database: $response');
  } catch (e) {
    print('❌ Error saving points to database: $e');
  }
  
  final room = ref.read(roomProvider.notifier);
  
  // Send the grade data via LiveKit
  await room.publishData({
    'event': 'grade_received',
    'learnerId': widget.learnerId,
    'points': _currentPoints,
    'totalPoints': _getTotalPoints(),
    'timestamp': DateTime.now().toIso8601String(),
  });
  
  print('✅ Grade data published');
  
  // Remove from grade requests
  ref.read(gradeRequestProvider(widget.livestreamId).notifier)
    .removeRequest(widget.learnerId);
  
  if (mounted) {
    Navigator.of(context).pop();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getTotalPoints()} points awarded to ${widget.learnerName}'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}
}