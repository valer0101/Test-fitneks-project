import 'package:flutter/material.dart';
import '../models/livestream_model.dart';

class EquipmentUtils {
  /// Single source of truth for equipment icons
  /// Format: 'material:icon_name' for Material icons
  ///         'asset:path/to/icon.svg' for custom SVGs (to be added later)
  static const Map<Equipment, String> _iconPaths = {
    Equipment.DUMBBELLS: 'material:fitness_center',
    Equipment.KETTLEBELL: 'material:sports_mma',
    Equipment.PLATES: 'material:album',
    Equipment.YOGA_BLOCK: 'material:square',
    Equipment.YOGA_MAT: 'material:view_agenda',
    Equipment.RESISTANCE_BAND: 'material:cable',
    Equipment.PULL_UP_BAR: 'material:horizontal_rule',
    Equipment.NO_EQUIPMENT: 'material:block',
  };

  /// Get widget for equipment icon
  /// Currently returns Material icons, will support custom SVGs in the future
  static Widget getIconWidget(Equipment equipment, {double size = 16, Color? color}) {
    final iconPath = _iconPaths[equipment] ?? 'material:sports';
    
    if (iconPath.startsWith('material:')) {
      final iconName = iconPath.substring(9);
      return Icon(
        _getMaterialIcon(iconName),
        size: size,
        color: color,
      );
    }
    // TODO: Add SVG support when custom icons are ready
    // else if (iconPath.startsWith('asset:')) {
    //   return SvgPicture.asset(...)
    // }
    
    return Icon(Icons.sports, size: size, color: color);
  }

  /// Map icon names to Material Icons
  static IconData _getMaterialIcon(String name) {
    switch (name) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'album':
        return Icons.album;
      case 'square':
        return Icons.square;
      case 'view_agenda':
        return Icons.view_agenda;
      case 'cable':
        return Icons.cable;
      case 'horizontal_rule':
        return Icons.horizontal_rule;
      case 'block':
        return Icons.block;
      default:
        return Icons.sports;
    }
  }

  /// Format equipment name for display
  /// RESISTANCE_BAND -> Resistance Band
  static String formatName(Equipment equipment) {
    final name = equipment.toString().split('.').last;
    return name
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get icon widget from string (for dynamic equipment lists)
  static Widget getIconWidgetFromString(String equipmentStr, {double size = 16, Color? color}) {
    final cleanStr = equipmentStr.contains('.')
        ? equipmentStr.split('.').last
        : equipmentStr;
    
    try {
      final equipment = Equipment.values.firstWhere(
        (e) => e.toString().split('.').last == cleanStr,
      );
      return getIconWidget(equipment, size: size, color: color);
    } catch (e) {
      return Icon(Icons.sports, size: size, color: color);
    }
  }

  /// Format string name for display
  static String formatStringName(String equipmentStr) {
    final cleanStr = equipmentStr.contains('.')
        ? equipmentStr.split('.').last
        : equipmentStr;
    
    return cleanStr
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }




/// Get icon for workout style
static IconData getWorkoutStyleIcon(WorkoutStyle style) {
  switch (style) {
    case WorkoutStyle.WEIGHTS:
      return Icons.fitness_center;
    case WorkoutStyle.CALISTHENICS:
      return Icons.accessibility_new;
    case WorkoutStyle.RESISTANCE:
      return Icons.sports_martial_arts;
    case WorkoutStyle.YOGA:
      return Icons.self_improvement;
    case WorkoutStyle.PILATES:
      return Icons.spa;
    case WorkoutStyle.MOBILITY:
      return Icons.directions_run;
  }
}

/// Get workout style icon from string
static IconData getWorkoutStyleIconFromString(String styleStr) {
  final cleanStr = styleStr.contains('.')
      ? styleStr.split('.').last
      : styleStr;
  
  try {
    final style = WorkoutStyle.values.firstWhere(
      (s) => s.toString().split('.').last == cleanStr,
    );
    return getWorkoutStyleIcon(style);
  } catch (e) {
    return Icons.sports;
  }
}

/// Format workout style name for display
static String formatWorkoutStyleName(String styleStr) {
  final cleanStr = styleStr.contains('.')
      ? styleStr.split('.').last
      : styleStr;
  
  return cleanStr[0].toUpperCase() + cleanStr.substring(1).toLowerCase();
}



}