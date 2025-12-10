import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ Add this
import '../../models/gift_type.dart';
import '../../providers/gift_exchange_provider.dart';
import '../../app_theme.dart';
import '../learner_ruby_purchase_modal.dart'; // ✅ Add this import


class GiftPurchaseWidget extends ConsumerWidget {
  const GiftPurchaseWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPanel = ref.watch(showPurchasePanelProvider);
    final selectedGift = ref.watch(selectedGiftProvider);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final quantity = ref.watch(quantityProvider);
    final balancesAsync = ref.watch(balancesProvider);
    final isExchanging = ref.watch(isExchangingProvider);

    return AnimatedSize(  // ✅ Changed from AnimatedContainer
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: showPanel && selectedGift != null
          ? Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(  // ✅ Added scrolling
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,  // ✅ Important for AnimatedSize
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getGiftIcon(selectedGift),
                                color: _getGiftColor(selectedGift),
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Buy ${selectedGift.displayName}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getGiftColor(selectedGift),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              ref.read(showPurchasePanelProvider.notifier).state = false;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Exchange rate display
                      _buildExchangeRateText(selectedGift, selectedCurrency),
                      const SizedBox(height: 20),

                      // Currency selector (if Protein is selected)
                      if (selectedGift == GiftType.protein)
                        _buildCurrencySelector(ref, selectedCurrency, balancesAsync),
                      if (selectedGift != GiftType.protein)
                        _buildRubiesDisplay(balancesAsync),
                      const SizedBox(height: 20),

                      // Quantity controls
                      _buildQuantityControls(ref, selectedGift, selectedCurrency, quantity),
                      const SizedBox(height: 20),

                      // Exchange button
                      _buildExchangeButton(context, ref, selectedGift, quantity, isExchanging),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  }

  // ✅ Helper method to get gift icon
  IconData _getGiftIcon(GiftType giftType) {
    switch (giftType) {
      case GiftType.proteinBar:
        return Icons.local_drink;
      case GiftType.proteinShake:
        return Icons.liquor;
      case GiftType.protein:
        return Icons.food_bank;
    }
  }

  // ✅ Helper method to get gift color
  Color _getGiftColor(GiftType giftType) {
    switch (giftType) {
      case GiftType.proteinBar:
        return AppTheme.primaryOrange;
      case GiftType.proteinShake:
        return const Color(0xFF4E6FFF);
      case GiftType.protein:
        return const Color(0xFF4CAF50);
    }
  }

  Widget _buildExchangeRateText(GiftType selectedGift, CurrencyType selectedCurrency) {
    String rateText = 'Exchange Rate: ';
    switch (selectedGift) {
      case GiftType.protein:
        if (selectedCurrency == CurrencyType.tokens) {
          rateText += '20 Tokens = 1 Protein';
        } else {
          rateText += '3 Rubies = 1 Protein';
        }
        break;
      case GiftType.proteinShake:
        rateText += '9 Rubies = 1 Protein Shake';
        break;
      case GiftType.proteinBar:
        rateText += '15 Rubies = 1 Protein Bar';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rateText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(WidgetRef ref, CurrencyType selectedCurrency, AsyncValue balancesAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCurrencyOption(
          ref,
          CurrencyType.rubies,
          selectedCurrency,
          Icons.diamond,
          balancesAsync,
        ),
        _buildCurrencyOption(
          ref,
          CurrencyType.tokens,
          selectedCurrency,
          Icons.token,
          balancesAsync,
        ),
      ],
    );
  }

  Widget _buildCurrencyOption(
    WidgetRef ref,
    CurrencyType currency,
    CurrencyType selectedCurrency,
    IconData icon,
    AsyncValue balancesAsync,
  ) {
    final isSelected = selectedCurrency == currency;
    final balance = balancesAsync.when(
      data: (data) => currency == CurrencyType.tokens ? data.fitneksTokens : data.rubies,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return GestureDetector(
      onTap: () {
        ref.read(selectedCurrencyProvider.notifier).state = currency;
        ref.read(quantityProvider.notifier).state = 0;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange.withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryOrange : Colors.grey),
            const SizedBox(width: 8),
            Text(
              '$balance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryOrange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRubiesDisplay(AsyncValue balancesAsync) {
    final balance = balancesAsync.when(
      data: (data) => data.rubies,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Rubies',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '$balance',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(WidgetRef ref, GiftType selectedGift, CurrencyType selectedCurrency, int quantity) {
    // ✅ ALWAYS increment by 1 (one gift at a time)
    const int incrementAmount = 1; // Changed to const to make it clear it never changes

    // Calculate cost per unit
    int costPerUnit = 0;
    switch (selectedGift) {
      case GiftType.protein:
        costPerUnit = selectedCurrency == CurrencyType.tokens ? 20 : 3;
        break;
      case GiftType.proteinShake:
        costPerUnit = 9;
        break;
      case GiftType.proteinBar:
        costPerUnit = 15;
        break;
    }
    final totalCost = quantity * costPerUnit;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: quantity > 0
                  ? () {
                      // ✅ Decrement by 1
                      ref.read(quantityProvider.notifier).state = quantity - 1;
                    }
                  : null,
              icon: const Icon(Icons.remove_circle),
              iconSize: 40,
              color: AppTheme.primaryOrange,
            ),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Qty: $quantity',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: () {
                // ✅ Increment by 1
                ref.read(quantityProvider.notifier).state = quantity + 1;
              },
              icon: const Icon(Icons.add_circle),
              iconSize: 40,
              color: AppTheme.primaryOrange,
            ),
          ],
        ),
        if (quantity > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Total Cost: $totalCost ${selectedCurrency == CurrencyType.tokens ? 'Tokens' : 'Rubies'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExchangeButton(BuildContext context, WidgetRef ref, GiftType? selectedGift, int quantity, bool isExchanging) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: selectedGift != null && quantity > 0 && !isExchanging
            ? () async {
                try {
                  await ref.read(exchangeGiftProvider).exchange();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Congratulations, you have gifts to give your trainers!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    ref.read(showPurchasePanelProvider.notifier).state = false;
                  }
                } on InsufficientBalanceException catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Exchange Failed',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          e.message,
                          style: const TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'OK',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          if (e.needsRubies)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Close error dialog
                                
                                // ✅ Show ruby purchase modal instead of navigating
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const RubyPurchaseModal(
                                    defaultPaymentMethodId: '', // We'll handle this differently
                                  ),
                                ).then((_) {
                                  // ✅ After modal closes, refresh balances
                                  ref.read(balancesProvider.notifier).refreshBalances();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Top up rubies',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Exchange Failed'),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isExchanging
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'EXCHANGE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }