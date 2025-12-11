import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gift_exchange_balances.dart';
import '../../models/gift_type.dart';
import '../../providers/gift_exchange_provider.dart';
import '../../app_theme.dart';

class GiftBalanceSummary extends ConsumerWidget {
  const GiftBalanceSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(balancesProvider);
    final showPurchasePanel = ref.watch(showPurchasePanelProvider);

    return balancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (balances) {
        if (showPurchasePanel) {
          // ✅ Show "CLOSE" button when panel is open
          return _buildCloseButton(context, ref);
        } else {
          // Show gift cards when panel is closed
          return _buildGiftCards(context, ref, balances);
        }
      },
    );
  }

  // ✅ New close button (replaces cards when panel is open)
  Widget _buildCloseButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: () {
            // Close the panel and go back to cards
            ref.read(showPurchasePanelProvider.notifier).state = false;
            ref.read(selectedGiftProvider.notifier).state = null;
            ref.read(quantityProvider.notifier).state = 0;
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text(
            'BACK TO GIFTS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftCards(BuildContext context, WidgetRef ref, GiftExchangeBalances balances) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isMobile
          ? Column(
              children: [
                _buildGiftCard(
                  context,
                  ref,
                  giftType: GiftType.proteinBar,
                  quantity: balances.proteinBars,
                  color: AppTheme.primaryOrange,
                  icon: Icons.local_drink,
                ),
                const SizedBox(height: 16),
                _buildGiftCard(
                  context,
                  ref,
                  giftType: GiftType.proteinShake,
                  quantity: balances.proteinShakes,
                  color: AppTheme.challengeColor,
                  icon: Icons.liquor,
                ),
                const SizedBox(height: 16),
                _buildGiftCard(
                  context,
                  ref,
                  giftType: GiftType.protein,
                  quantity: balances.protein,
                  color: AppTheme.proteinColor,
                  icon: Icons.food_bank,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGiftCard(
                  context,
                  ref,
                  giftType: GiftType.proteinBar,
                  quantity: balances.proteinBars,
                  color: AppTheme.primaryOrange,
                  icon: Icons.local_drink,
                ),
                _buildGiftCard(
                  context,
                  ref,
                  giftType: GiftType.proteinShake,
                  quantity: balances.proteinShakes,
                  color: AppTheme.challengeColor,
                  icon: Icons.liquor,
                ),
                _buildGiftCard(
                  context,
                  ref,
                  giftType: GiftType.protein,
                  quantity: balances.protein,
                  color: AppTheme.proteinColor,
                  icon: Icons.food_bank,
                ),
              ],
            ),
    );
  }

  Widget _buildGiftCard(
    BuildContext context,
    WidgetRef ref, {
    required GiftType giftType,
    required int quantity,
    required Color color,
    required IconData icon,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return isMobile
        ? Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$quantity',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          giftType.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(selectedGiftProvider.notifier).state = giftType;
                      ref.read(showPurchasePanelProvider.notifier).state = true;
                      ref.read(quantityProvider.notifier).state = 0;
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.08),
                      side: BorderSide(color: color, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: color,
                    ),
                    child: const Text(
                      'BUY\nMORE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(icon, size: 40, color: color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      giftType.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(selectedGiftProvider.notifier).state = giftType;
                        ref.read(showPurchasePanelProvider.notifier).state = true;
                        ref.read(quantityProvider.notifier).state = 0;
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: color.withOpacity(0.08),
                        side: BorderSide(color: color, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: color,
                      ),
                      child: const Text(
                        'BUY MORE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}