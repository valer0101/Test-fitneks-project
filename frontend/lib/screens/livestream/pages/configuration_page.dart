import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/livestream_model.dart';
import '../../../providers/create_stream_provider.dart';
import '../../../app_theme.dart';

class ConfigurationPage extends ConsumerWidget {
  final PageController pageController;

  const ConfigurationPage({
    super.key,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStreamProvider);
    final notifier = ref.read(createStreamProvider.notifier);

    final participantOptions = [10, 25, 50, 100, 150, 200];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Visibility toggle
          // Visibility toggle
          const Text('Visibility',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public, size: 18),
                      SizedBox(width: 8),
                      Text('Public'),
                    ],
                  ),
                  selected: state.visibility == LiveStreamVisibility.PUBLIC,
                  onSelected: (selected) {
                    if (selected) {
                      notifier.updateVisibility(LiveStreamVisibility.PUBLIC);
                    }
                  },
                  selectedColor: AppTheme.primaryOrange,
                  labelStyle: TextStyle(
                    color: state.visibility == LiveStreamVisibility.PUBLIC
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 18),
                      SizedBox(width: 8),
                      Text('Private'),
                    ],
                  ),
                  selected: state.visibility == LiveStreamVisibility.PRIVATE,
                  onSelected: (selected) {
                    if (selected) {
                      notifier.updateVisibility(LiveStreamVisibility.PRIVATE);
                    }
                  },
                  selectedColor: AppTheme.primaryOrange,
                  labelStyle: TextStyle(
                    color: state.visibility == LiveStreamVisibility.PRIVATE
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Max participants dropdown
          DropdownButtonFormField<int>(
            initialValue: state.maxParticipants,
            decoration: const InputDecoration(
              labelText: 'Maximum Participants',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
              ),
            ),
            items: participantOptions.map((count) {
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
}
