import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import 'auth_provider.dart';

/// Enum for payout period filtering
enum PayoutPeriod { week, month }

/// Payout model class
class Payout {
  final int id;
  final int amount;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  Payout({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'],
      amount: json['amount'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

/// Payment state class
class PaymentState {
  final bool isStripeLinked;
  final List<Payout> payouts;
  final PayoutPeriod selectedPeriod;
  final bool isLoading;
  final String? error;

  PaymentState({
    this.isStripeLinked = false,
    this.payouts = const [],
    this.selectedPeriod = PayoutPeriod.week,
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    bool? isStripeLinked,
    List<Payout>? payouts,
    PayoutPeriod? selectedPeriod,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      isStripeLinked: isStripeLinked ?? this.isStripeLinked,
      payouts: payouts ?? this.payouts,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Payment state notifier for managing payment-related state
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService;
  final Ref _ref;

  PaymentNotifier(this._paymentService, this._ref) : super(PaymentState());

  /// Loads payout history from the backend
  Future<void> loadPayoutHistory() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Get token from auth provider
      final authState = _ref.read(authProvider);
      final token = authState.token;

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final periodString = 
          state.selectedPeriod == PayoutPeriod.week ? 'week' : 'month';
      
      final payouts = await _paymentService.getPayoutHistory(periodString, token);
      final isLinked = await _paymentService.isStripeAccountLinked(token);

      state = state.copyWith(
        payouts: payouts,
        isStripeLinked: isLinked,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Changes the filter period and reloads data
  Future<void> changeFilter(PayoutPeriod period) async {
    if (state.selectedPeriod != period) {
      state = state.copyWith(selectedPeriod: period);
      await loadPayoutHistory();
    }
  }

  /// Updates Stripe link status
  void updateStripeLinkedStatus(bool isLinked) {
    state = state.copyWith(isStripeLinked: isLinked);
  }

  /// Clears any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for payment state management
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) {
    final paymentService = PaymentService();
    return PaymentNotifier(paymentService, ref);
  },
);