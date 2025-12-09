import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/gift_exchange_provider.dart';
import '../../app_theme.dart';

class GiftHistoryList extends ConsumerWidget {
  const GiftHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(historyPeriodProvider);
    final historyAsync = ref.watch(purchaseHistoryProvider(selectedPeriod));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gifts History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildPeriodToggle(ref, selectedPeriod),
            ],
          ),
        ),
        historyAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading history: $error'),
            ),
          ),
          data: (purchases) {
            if (purchases.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No purchases in this period'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return _buildHistoryItem(purchase.giftName, purchase.quantity, purchase.date);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPeriodToggle(WidgetRef ref, String selectedPeriod) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1), // ✅ Light grey border
        borderRadius: BorderRadius.circular(25),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodTab(ref, 'week', 'Week', selectedPeriod, isLeft: true),
          _buildPeriodTab(ref, 'month', 'Month', selectedPeriod, isRight: true),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(
    WidgetRef ref,
    String period,
    String label,
    String selectedPeriod, {
    bool isLeft = false,
    bool isRight = false,
  }) {
    final isSelected = selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        ref.read(historyPeriodProvider.notifier).state = period;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFFF4ED)  // ✅ Light peach/cream for selected
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(25) : Radius.zero,
            right: isRight ? const Radius.circular(25) : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check,
                size: 18,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? AppTheme.primaryOrange  // ✅ Orange when selected
                    : const Color(0xFF9CA3AF),  // ✅ Light grey when not selected
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String giftName, int quantity, DateTime date) {
    Color iconColor;
    IconData icon;

    if (giftName.contains('Bar')) {
      iconColor = AppTheme.primaryOrange;
      icon = Icons.local_drink;
    } else if (giftName.contains('Shake')) {
      iconColor = const Color(0xFF4E6FFF);
      icon = Icons.liquor;
    } else {
      iconColor = const Color(0xFF4CAF50);
      icon = Icons.food_bank;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor),
      ),
      title: Text('$quantity $giftName'),
      trailing: Text(
        DateFormat('dd MMM yyyy').format(date),
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}