import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/create_stream_provider.dart';

class SchedulingPage extends ConsumerWidget {
  final PageController pageController;
  
  const SchedulingPage({
    super.key,
    required this.pageController,
  });

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(createStreamProvider.notifier);
    final state = ref.read(createStreamProvider);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: state.scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF4D00)),
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
  }

  Future<void> _selectTime(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(createStreamProvider.notifier);
    final state = ref.read(createStreamProvider);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        state.scheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF4D00)),
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStreamProvider);
    final notifier = ref.read(createStreamProvider.notifier);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Go live now toggle
          SwitchListTile(
            title: const Text('Go Live Now'),
            value: state.goLiveNow,
            onChanged: notifier.toggleGoLiveNow,
            activeColor: const Color(0xFFFF4D00),
          ),
          
          if (!state.goLiveNow) ...[
            const SizedBox(height: 24),
            const Text('Select Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, ref),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      state.scheduledAt != null
                          ? dateFormat.format(state.scheduledAt!)
                          : 'Select Date',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, ref),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      state.scheduledAt != null
                          ? timeFormat.format(state.scheduledAt!)
                          : 'Select Time',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            SwitchListTile(
              title: const Text('Repeat weekly for 4 weeks'),
              subtitle: const Text('Creates 4 recurring sessions'),
              value: state.isRecurring,
              onChanged: notifier.toggleRecurring,
              activeColor: const Color(0xFFFF4D00),
            ),
          ],
        ],
      ),
    );
  }
}