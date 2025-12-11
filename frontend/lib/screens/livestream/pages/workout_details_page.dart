import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/livestream_model.dart';
import '../../../providers/create_stream_provider.dart';
import '../../../utils/equipment_utils.dart';

class WorkoutDetailsPage extends ConsumerWidget {
  final PageController pageController;
  
  const WorkoutDetailsPage({
    super.key,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStreamProvider);
    final notifier = ref.read(createStreamProvider.notifier);
    
final hasNoEquipment = state.equipmentNeeded.contains(Equipment.NO_EQUIPMENT);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Equipment section
          const Text('Equipment Needed', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: Equipment.values.map((equipment) {
              final isSelected = state.equipmentNeeded.contains(equipment);
              final isDisabled = hasNoEquipment && equipment != Equipment.NO_EQUIPMENT;

              return FilterChip(
  avatar: EquipmentUtils.getIconWidget(
    equipment,
    size: 18,
    color: isSelected ? Colors.white : const Color(0xFFFF4D00),
  ),
  label: Text(EquipmentUtils.formatName(equipment)),
  selected: isSelected,
  onSelected: isDisabled ? null : (selected) {
    notifier.toggleEquipment(equipment);
  },
  selectedColor: const Color(0xFFFF4D00),
  labelStyle: TextStyle(
    color: isSelected ? Colors.white : (isDisabled ? Colors.grey : Colors.black),
  ),
);
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Workout style section
          const Text('Workout Style', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: WorkoutStyle.values.map((style) {
              final isSelected = state.workoutStyle == style;
              return InkWell(
                onTap: () => notifier.selectWorkoutStyle(style),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF4D00) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF4D00) : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStyleIcon(style),
                        color: isSelected ? Colors.white : Colors.black54,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatStyleName(style),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  String _formatStyleName(WorkoutStyle style) {
    return style.name[0].toUpperCase() + style.name.substring(1).toLowerCase();
  }
  
  IconData _getStyleIcon(WorkoutStyle style) {
  return EquipmentUtils.getWorkoutStyleIcon(style);
}


}