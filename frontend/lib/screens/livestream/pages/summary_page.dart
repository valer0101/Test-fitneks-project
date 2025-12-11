import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/create_stream_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/calendar_provider.dart';  // ✅ ADD THIS LINE
import '../create_stream_screen.dart';
import '../../../widgets/gradient_elevated_button.dart';
import '../../../app_theme.dart';



class SummaryPage extends ConsumerStatefulWidget {  // ✅ Changed to StatefulWidget
  final PageController pageController;

  const SummaryPage({
    Key? key,
    required this.pageController,
  }) : super(key: key);

  @override
  ConsumerState<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends ConsumerState<SummaryPage> {
  // ✅ Track which sections are being edited
  bool _isEditingBasicInfo = false;
  bool _isEditingSettings = false;
  bool _isEditingSchedule = false;
  bool _isEditingWorkout = false;
  bool _isEditingMusclePoints = false;


  // ✅ Add this to track the actual livestream ID
  String? _actualLivestreamId;

  // ✅ Controllers for text fields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createStreamProvider);
    _titleController = TextEditingController(text: state.title);
    _descriptionController = TextEditingController(text: state.description);

    // ✅ Load the actual livestream ID if editing
    _loadActualLivestreamId();
  }


Future<void> _loadActualLivestreamId() async {
  final eventId = _getLivestreamId(context);
  print('🔍 Event ID from route: $eventId');
  
  if (eventId == null) {
    print('❌ No event ID found');
    return;
  }
  
  final authState = ref.read(authProvider);
  final token = authState.token;
  print('🔑 Token exists: ${token != null}');
  
  if (token == null) return;
  
  try {
    final repository = ref.read(livestreamRepositoryProvider);
    print('📡 Fetching livestream by event ID: $eventId');
    
    final livestream = await repository.getLivestreamByEventId(eventId, token);
    
    print('✅ Livestream found!');
    print('   Livestream ID: ${livestream.id}');
    print('   Event ID: ${livestream.eventId}');
    print('   Title: ${livestream.title}');
    
    setState(() {
      _actualLivestreamId = livestream.id;
    });
  } catch (e) {
    print('❌ Error loading livestream: $e');
  }
}

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


Future<void> _submitStream(BuildContext context, WidgetRef ref) async {
  final authState = ref.read(authProvider);
  final token = authState.token;
  
  if (token == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }
  
  final notifier = ref.read(createStreamProvider.notifier);
  final repository = ref.read(livestreamRepositoryProvider);
  
  // ✅ Use the stored livestream ID directly
  print('💾 Submitting with livestream ID: $_actualLivestreamId');
  
  final livestream = await notifier.submitStream(
    repository,
    token,
    livestreamId: _actualLivestreamId,  // ✅ Use stored ID
  );
  
  if (!context.mounted) return;
  
  if (livestream != null) {
    final state = ref.read(createStreamProvider);
    
    notifier.resetForm();
    
    final currentMonth = ref.read(currentMonthProvider);
    final currentYear = ref.read(currentYearProvider);
    ref.invalidate(eventsProvider((currentMonth, currentYear)));
    
    if (!state.goLiveNow && state.scheduledAt != null) {
      final scheduledMonth = state.scheduledAt!.month;
      final scheduledYear = state.scheduledAt!.year;
      
      if (scheduledMonth != currentMonth || scheduledYear != currentYear) {
        ref.invalidate(eventsProvider((scheduledMonth, scheduledYear)));
      }
    }
    
    if (state.goLiveNow) {
  // ✅ Navigate to live stream page immediately
  context.go('/livestream/${livestream.id}');
} else {
  // ✅ Navigate to calendar for scheduled streams
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Stream scheduled successfully!'),
      backgroundColor: Colors.green,
    ),
  );
  context.go('/trainer-dashboard/calendar');
}
  } else {
    final error = ref.read(createStreamProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Failed to save stream'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

 Widget _buildSummarySection({
  required String title,
  required IconData icon,
  required List<Widget> children,
  required VoidCallback onEdit,
  required bool isEditMode,  // ✅ Add this parameter
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Only show edit button if NOT in edit mode
              if (!isEditMode)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ),
  );
}

 @override
Widget build(BuildContext context) {
  final state = ref.watch(createStreamProvider);
  final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  final isEditMode = _getLivestreamId(context) != null;
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditMode ? 'Edit Stream' : 'Review & Submit',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        
        // Points Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.fitneksGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Total Points Available',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.totalPossiblePoints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // ✅ All sections with edit capability
        _buildBasicInfoSection(isEditMode),
        const SizedBox(height: 16),
        _buildSettingsSection(isEditMode),
        const SizedBox(height: 16),
        _buildScheduleSection(isEditMode),
        const SizedBox(height: 16),
        _buildWorkoutSection(isEditMode),
        const SizedBox(height: 16),
        _buildMusclePointsSection(isEditMode),
        
        const SizedBox(height: 32),
        
        // Action buttons
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientElevatedButton(
              onPressed: state.isSubmitting 
                  ? null 
                  : () => _submitStream(context, ref),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : _buildButtonContent(context, ref),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share functionality coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share This Stream'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

String? _getLivestreamId(BuildContext context) {
    final createStreamScreen = context.findAncestorWidgetOfExactType<CreateStreamScreen>();
    return createStreamScreen?.livestreamId;
  }

Widget _buildButtonContent(BuildContext context, WidgetRef ref) {  // ✅ Add ref parameter
    final livestreamId = _getLivestreamId(context);
    final state = ref.watch(createStreamProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          livestreamId != null 
              ? Icons.save
              : (state.goLiveNow ? Icons.live_tv : Icons.schedule),
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Text(
          livestreamId != null 
              ? 'Save Changes'
              : (state.goLiveNow ? 'Go Live Now' : 'Schedule Stream'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }



Widget _buildEditableBasicInfo(BuildContext context, WidgetRef ref, bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  final notifier = ref.read(createStreamProvider.notifier);
  
  if (!isEditMode) {
    return _buildSummarySection(
      title: 'Basic Information',
      icon: Icons.info_outline,
      onEdit: () => widget.pageController.jumpToPage(0),
      isEditMode: isEditMode,  // ✅ Add this
      children: [
        _buildSummaryRow('Title', state.title ?? 'Not set'),
        const SizedBox(height: 8),
        _buildSummaryRow('Description', state.description ?? 'Not set'),
      ],
    );
  }
  
  // ✅ Show editable version
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            const Text(
              'Basic Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: state.title),
          onChanged: notifier.updateTitle,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: state.description),
          onChanged: notifier.updateDescription,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLength: 200,
          maxLines: 3,
        ),
      ],
    ),
  );
}

Widget _buildEditableSettings(BuildContext context, WidgetRef ref, bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  final notifier = ref.read(createStreamProvider.notifier);  // ✅ Add this line


  if (!isEditMode) {
    return _buildSummarySection(
      title: 'Settings',
      icon: Icons.settings,
      onEdit: () => widget.pageController.jumpToPage(2),
      isEditMode: isEditMode,  // ✅ Add this
      children: [
        _buildSummaryRow('Visibility', state.visibility.name.toUpperCase()),
        const SizedBox(height: 8),
        _buildSummaryRow('Max Participants', '${state.maxParticipants ?? 0}'),
      ],
    );
  }
  
  // ✅ Editable version
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.settings, size: 20, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: state.maxParticipants,
          decoration: const InputDecoration(
            labelText: 'Max Participants',
            border: OutlineInputBorder(),
          ),
          items: [10, 25, 50, 100, 150, 200].map((count) {
            return DropdownMenuItem(
              value: count,
              child: Text('$count participants'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              notifier.updateMaxParticipants(value);
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildEditableSchedule(BuildContext context, WidgetRef ref, bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  
  if (!isEditMode) {
    return _buildSummarySection(
      title: 'Schedule',
      icon: Icons.schedule,
      onEdit: () => widget.pageController.jumpToPage(3),
      isEditMode: isEditMode,  // ✅ Add this
      children: [

        if (state.goLiveNow)
          _buildSummaryRow('Start Time', 'Immediately')
        else ...[
          _buildSummaryRow(
            'Scheduled For',
            state.scheduledAt != null 
                ? dateFormat.format(state.scheduledAt!)
                : 'Not set',
          ),
          if (state.isRecurring) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Recurring', 'Weekly for 4 weeks'),
          ],
        ],
      ],
    );
  }
  
  // ✅ For edit mode, keep as read-only for now (scheduling changes are complex)
  return _buildSummarySection(
    title: 'Schedule (read-only)',
    icon: Icons.schedule,
    onEdit: () => widget.pageController.jumpToPage(3),
    isEditMode: isEditMode,  // ✅ Add this
    children: [
      _buildSummaryRow(
        'Scheduled For',
        state.scheduledAt != null 
            ? dateFormat.format(state.scheduledAt!)
            : 'Not set',
      ),
    ],
  );
}


Widget _buildEditableWorkout(BuildContext context, WidgetRef ref, bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  
  if (!isEditMode) {
    return _buildSummarySection(
      title: 'Workout',
      icon: Icons.fitness_center,
      onEdit: () => widget.pageController.jumpToPage(4),
      isEditMode: isEditMode,  // ✅ Add this
      children: [
        _buildSummaryRow(
          'Equipment',
          state.equipmentNeeded.isEmpty 
              ? 'Not set'
              : state.equipmentNeeded
                  .map((e) => e.name.replaceAll('_', ' ').toLowerCase()
                      .split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '))
                  .join(', '),
        ),
        const SizedBox(height: 8),
        _buildSummaryRow(
          'Style',
          state.workoutStyle?.name.replaceAll('_', ' ').toLowerCase()
              .split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ') ?? 'Not set',
        ),
      ],
    );
  }
  
  // ✅ For edit mode, navigate to workout page (equipment/style selection is complex)
 return _buildSummarySection(
    title: 'Workout Details',
    icon: Icons.fitness_center,
    onEdit: () => widget.pageController.jumpToPage(4),
    isEditMode: isEditMode,  // ✅ Add this
    children: [
      _buildSummaryRow(
        'Equipment',
        state.equipmentNeeded.isEmpty 
            ? 'Not set'
            : state.equipmentNeeded
                .map((e) => e.name.replaceAll('_', ' ').toLowerCase()
                    .split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '))
                .join(', '),
      ),
      const SizedBox(height: 8),
      _buildSummaryRow(
        'Style',
        state.workoutStyle?.name.replaceAll('_', ' ').toLowerCase()
            .split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ') ?? 'Not set',
      ),
      const SizedBox(height: 8),
      const Text(
        'Tap edit to change workout details',
        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    ],
  );
}



// Editing form

Widget _buildBasicInfoSection(bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  final notifier = ref.read(createStreamProvider.notifier);
  
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Basic Workout Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (isEditMode)
                IconButton(
                  icon: Icon(_isEditingBasicInfo ? Icons.check : Icons.edit, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_isEditingBasicInfo) {
                        // Save changes
                        notifier.updateTitle(_titleController.text);
                        notifier.updateDescription(_descriptionController.text);
                      }
                      _isEditingBasicInfo = !_isEditingBasicInfo;
                    });
                  },
                  color: _isEditingBasicInfo ? Colors.green : Colors.grey[600],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isEditingBasicInfo
              ? Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 200,
                      maxLines: 3,
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildSummaryRow('Title', state.title ?? 'Not set'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Description', state.description ?? 'Not set'),
                  ],
                ),
        ),
      ],
    ),
  );
}

Widget _buildSettingsSection(bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  final notifier = ref.read(createStreamProvider.notifier);
  
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.settings, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (isEditMode)
                IconButton(
                  icon: Icon(_isEditingSettings ? Icons.check : Icons.edit, size: 20),
                  onPressed: () {
                    setState(() {
                      _isEditingSettings = !_isEditingSettings;
                    });
                  },
                  color: _isEditingSettings ? Colors.green : Colors.grey[600],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isEditingSettings
              ? DropdownButtonFormField<int>(
                  value: state.maxParticipants,
                  decoration: const InputDecoration(
                    labelText: 'Max Participants',
                    border: OutlineInputBorder(),
                  ),
                  items: [10, 25, 50, 100, 150, 200].map((count) {
                    return DropdownMenuItem(
                      value: count,
                      child: Text('$count participants'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      notifier.updateMaxParticipants(value);
                    }
                  },
                )
              : Column(
                  children: [
                    _buildSummaryRow('Visibility', state.visibility.name),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Max Participants', '${state.maxParticipants ?? 0}'),
                  ],
                ),
        ),
      ],
    ),
  );
}

Widget _buildScheduleSection(bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  final notifier = ref.read(createStreamProvider.notifier);
  final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (isEditMode)
                IconButton(
                  icon: Icon(_isEditingSchedule ? Icons.check : Icons.edit, size: 20),
                  onPressed: () {
                    setState(() {
                      _isEditingSchedule = !_isEditingSchedule;
                    });
                  },
                  color: _isEditingSchedule ? Colors.green : Colors.grey[600],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isEditingSchedule
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: AppTheme.primaryOrange),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (picked != null) {
                          final currentTime = state.scheduledAt ?? DateTime.now();
                          final newDateTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            currentTime.hour,
                            currentTime.minute,
                          );
                          notifier.updateScheduledAt(newDateTime);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        state.scheduledAt != null
                            ? DateFormat('MMM dd, yyyy').format(state.scheduledAt!)
                            : 'Select Date',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            state.scheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: AppTheme.primaryOrange),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (picked != null) {
                          final currentDate = state.scheduledAt ?? DateTime.now();
                          final newDateTime = DateTime(
                            currentDate.year,
                            currentDate.month,
                            currentDate.day,
                            picked.hour,
                            picked.minute,
                          );
                          notifier.updateScheduledAt(newDateTime);
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        state.scheduledAt != null
                            ? DateFormat('hh:mm a').format(state.scheduledAt!)
                            : 'Select Time',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                )
              : _buildSummaryRow(
                  'Scheduled For',
                  state.scheduledAt != null 
                      ? dateFormat.format(state.scheduledAt!)
                      : 'Not set',
                ),
        ),
      ],
    ),
  );
}

Widget _buildWorkoutSection(bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.fitness_center, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Workout Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (isEditMode)
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => widget.pageController.jumpToPage(4),
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSummaryRow(
                'Equipment',
                state.equipmentNeeded.isEmpty 
                    ? 'Not set'
                    : state.equipmentNeeded.map((e) => e.name).join(', '),
              ),
              const SizedBox(height: 8),
              _buildSummaryRow('Style', state.workoutStyle?.name ?? 'Not set'),
              if (isEditMode) ...[
                const SizedBox(height: 8),
                const Text(
                  'Tap arrow to edit in full form',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildMusclePointsSection(bool isEditMode) {
  final state = ref.watch(createStreamProvider);
  
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.accessibility_new, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Muscle Points Distribution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (isEditMode)
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => widget.pageController.jumpToPage(5),
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: state.hasMusclePoints
              ? Column(
                  children: state.musclePoints.entries
                      .where((entry) => entry.value > 0)
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    entry.key.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: entry.value / 5,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryOrange,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.value} pts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                )
              : const Text('No muscle points set'),
        ),
      ],
    ),
  );
}




}