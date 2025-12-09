import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/calendar_provider.dart';

class MonthNavigation extends ConsumerWidget {
  const MonthNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final currentYear = ref.watch(currentYearProvider);
    final currentDate = DateTime(currentYear, currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _previousMonth(ref),
          icon: const Icon(Icons.chevron_left, color: Colors.orange),
          iconSize: 30,
        ),
        Text(
          DateFormat('MMMM yyyy').format(currentDate),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => _nextMonth(ref),
          icon: const Icon(Icons.chevron_right, color: Colors.orange),
          iconSize: 30,
        ),
      ],
    );
  }

  void _previousMonth(WidgetRef ref) {
    final currentMonth = ref.read(currentMonthProvider);
    final currentYear = ref.read(currentYearProvider);
    
    if (currentMonth == 1) {
      ref.read(currentMonthProvider.notifier).state = 12;
      ref.read(currentYearProvider.notifier).state = currentYear - 1;
    } else {
      ref.read(currentMonthProvider.notifier).state = currentMonth - 1;
    }
  }

  void _nextMonth(WidgetRef ref) {
    final currentMonth = ref.read(currentMonthProvider);
    final currentYear = ref.read(currentYearProvider);
    
    if (currentMonth == 12) {
      ref.read(currentMonthProvider.notifier).state = 1;
      ref.read(currentYearProvider.notifier).state = currentYear + 1;
    } else {
      ref.read(currentMonthProvider.notifier).state = currentMonth + 1;
    }
  }
}