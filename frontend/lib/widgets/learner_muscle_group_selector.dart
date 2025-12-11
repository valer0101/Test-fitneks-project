import 'package:flutter/material.dart';
import '../app_theme.dart';

class MuscleGroupSelector extends StatelessWidget {
  final Map<String, int> muscleGroups;
  final List<String> selectedGroups;
  final Function(String) onToggle;

  const MuscleGroupSelector({
    Key? key,
    required this.muscleGroups,
    required this.selectedGroups,
    required this.onToggle,
  }) : super(key: key);

  // Define colors for each muscle group
  Color _getGroupColor(String group) {
    switch (group.toLowerCase()) {
      case 'arms':
        return Colors.red;
      case 'chest':
        return Colors.blue;
      case 'back':
        return Colors.green;
      case 'abs':
        return Colors.purple;
      case 'legs':
        return AppTheme.primaryOrange;
      case 'chlng':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: muscleGroups.entries.map((entry) {
        final isSelected = selectedGroups.contains(entry.key);
        final color = _getGroupColor(entry.key);
        
        return InkWell(
          onTap: () => onToggle(entry.key),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}