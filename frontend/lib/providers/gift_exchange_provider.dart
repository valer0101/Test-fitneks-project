import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gift_exchange_balances.dart';
import '../models/gift_exchange_purchase.dart';
import '../models/gift_type.dart';
import '../services/gift_exchange_service.dart';
import 'auth_provider.dart';

// Export authProvider so it can be accessed with gift.authProvider
export 'auth_provider.dart' show authProvider;  // ✅ Add this line


// ✅ Add custom exception class
class InsufficientBalanceException implements Exception {
  final String message;
  final bool needsRubies;

  InsufficientBalanceException(this.message, this.needsRubies);

  @override
  String toString() => message;
}

// Service provider
final giftExchangeServiceProvider = Provider<GiftExchangeService>((ref) {
  final authState = ref.watch(authProvider);
  final token = authState.token;
  
  print('🔑 Auth token for gift exchange: ${token?.substring(0, 20)}...'); // ✅ Add this
  
  return GiftExchangeService(authToken: token);
});

// Balances state provider
final balancesProvider = StateNotifierProvider<BalancesNotifier, AsyncValue<GiftExchangeBalances>>((ref) {
  return BalancesNotifier(ref.read(giftExchangeServiceProvider));
});

class BalancesNotifier extends StateNotifier<AsyncValue<GiftExchangeBalances>> {
  final GiftExchangeService _service;

  BalancesNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchBalances();
  }

 Future<void> fetchBalances() async {
  state = const AsyncValue.loading();
  try {
    final balances = await _service.getBalances();
    print('🔍 Fetched balances: ${balances.rubies} rubies'); // ✅ Add this
    state = AsyncValue.data(balances);
  } catch (e, stackTrace) {
    print('❌ Balance fetch error: $e'); // ✅ Add this
    state = AsyncValue.error(e, stackTrace);
  }
}

  Future<void> refreshBalances() async {
    await fetchBalances();
  }
}

// Purchase history provider
final purchaseHistoryProvider = StateNotifierProvider.family<PurchaseHistoryNotifier, AsyncValue<List<GiftExchangePurchase>>, String>((ref, period) {
  return PurchaseHistoryNotifier(ref.read(giftExchangeServiceProvider), period);
});

class PurchaseHistoryNotifier extends StateNotifier<AsyncValue<List<GiftExchangePurchase>>> {
  final GiftExchangeService _service;
  final String period;

  PurchaseHistoryNotifier(this._service, this.period) : super(const AsyncValue.loading()) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _service.getHistory(period);
      state = AsyncValue.data(history);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Selected gift type provider
final selectedGiftProvider = StateProvider<GiftType?>((ref) => null);

// Selected currency provider (only matters for Protein)
final selectedCurrencyProvider = StateProvider<CurrencyType>((ref) => CurrencyType.rubies);

// Quantity provider
final quantityProvider = StateProvider<int>((ref) => 0);

// Loading state for exchange button
final isExchangingProvider = StateProvider<bool>((ref) => false);

// Show purchase panel provider
final showPurchasePanelProvider = StateProvider<bool>((ref) => false);

// Selected history period provider
final historyPeriodProvider = StateProvider<String>((ref) => 'week');

// Exchange gift action
final exchangeGiftProvider = Provider<ExchangeGiftAction>((ref) {
  return ExchangeGiftAction(ref);
});

class ExchangeGiftAction {
  final Ref _ref;

  ExchangeGiftAction(this._ref);

  Future<void> exchange() async {
    final selectedGift = _ref.read(selectedGiftProvider);
    final quantity = _ref.read(quantityProvider);
    final currency = _ref.read(selectedCurrencyProvider);

    if (selectedGift == null || quantity <= 0) {
      throw Exception('Please select a gift and quantity');
    }

    // ✅ Check if user has enough balance BEFORE attempting exchange
    final balancesAsync = _ref.read(balancesProvider);
    
    await balancesAsync.when(
      data: (balances) async {
        int costPerUnit = 0;
        String currencyName = '';
        int availableBalance = 0;

        // Calculate cost and check balance
        switch (selectedGift) {
          case GiftType.protein:
            if (currency == CurrencyType.tokens) {
              costPerUnit = 20;
              currencyName = 'Tokens';
              availableBalance = balances.fitneksTokens;
            } else {
              costPerUnit = 3;
              currencyName = 'Rubies';
              availableBalance = balances.rubies;
            }
            break;
          case GiftType.proteinShake:
            costPerUnit = 9;
            currencyName = 'Rubies';
            availableBalance = balances.rubies;
            break;
          case GiftType.proteinBar:
            costPerUnit = 15;
            currencyName = 'Rubies';
            availableBalance = balances.rubies;
            break;
        }

        final totalCost = quantity * costPerUnit;

        // ✅ Check if user has enough balance
        if (availableBalance < totalCost) {
          throw InsufficientBalanceException(
            'You need $totalCost $currencyName to get these gifts. You currently have $availableBalance $currencyName.',
            currencyName == 'Rubies',
          );
        }
      },
      loading: () => throw Exception('Loading balances...'),
      error: (e, s) => throw Exception('Error loading balances'),
    );

    _ref.read(isExchangingProvider.notifier).state = true;

    try {
      final service = _ref.read(giftExchangeServiceProvider);
      final newBalances = await service.exchangeGift(
        giftType: selectedGift,
        quantity: quantity,
        currencyUsed: currency,
      );

      // Update balances
      _ref.read(balancesProvider.notifier).state = AsyncValue.data(newBalances);

      // Reset quantity
      _ref.read(quantityProvider.notifier).state = 0;

      // Refresh history
      final period = _ref.read(historyPeriodProvider);
      _ref.invalidate(purchaseHistoryProvider(period));

      return;
    } catch (e) {
      rethrow;
    } finally {
      _ref.read(isExchangingProvider.notifier).state = false;
    }
  }
}