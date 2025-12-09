import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;  // ✅ Add this
import '../services/learner_payment_service.dart';
import '../services/stripe_web_service.dart';  // ✅ Add this
import '../models/payment_models.dart';
import '../services/i_payment_service.dart';

// Payment Methods State
class LearnerPaymentState {
  final List<PaymentMethod> paymentMethods;
  final bool isLoading;
  final String? error;

  LearnerPaymentState({
    this.paymentMethods = const [],
    this.isLoading = false,
    this.error,
  });

  LearnerPaymentState copyWith({
    List<PaymentMethod>? paymentMethods,
    bool? isLoading,
    String? error,
  }) {
    return LearnerPaymentState(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Payment Methods Notifier
class LearnerPaymentNotifier extends StateNotifier<LearnerPaymentState> {
  final IPaymentService _service;

  LearnerPaymentNotifier(this._service) : super(LearnerPaymentState());

  Future<void> loadPaymentMethods() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final methods = await _service.getPaymentMethods();
      state = state.copyWith(
        paymentMethods: methods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<SetupIntentResponse?> createSetupIntent() async {
    try {
      return await _service.createSetupIntent();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> addPaymentMethod(String paymentMethodId, {bool setAsDefault = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final method = await _service.addPaymentMethod(paymentMethodId, setAsDefault);
      final updatedMethods = [...state.paymentMethods];
      
      if (method.isDefault) {
        for (var m in updatedMethods) {
          m.isDefault = false;
        }
      }
      
      updatedMethods.add(method);
      state = state.copyWith(
        paymentMethods: updatedMethods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> removePaymentMethod(String methodId) async {
    try {
      await _service.removePaymentMethod(methodId);
      final updatedMethods = state.paymentMethods
          .where((m) => m.id != methodId)
          .toList();
      state = state.copyWith(paymentMethods: updatedMethods);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    try {
      await _service.setDefaultPaymentMethod(methodId);
      
      final updatedMethods = state.paymentMethods.map((m) {
        return m..isDefault = (m.id == methodId);
      }).toList();
      
      state = state.copyWith(paymentMethods: updatedMethods);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// Purchase History State
class PurchaseHistoryState {
  final List<PurchaseHistoryItem> purchases;
  final int total;
  final int totalRubies;
  final int totalSpentCents;
  final bool isLoading;
  final String? error;

  PurchaseHistoryState({
    this.purchases = const [],
    this.total = 0,
    this.totalRubies = 0,
    this.totalSpentCents = 0,
    this.isLoading = false,
    this.error,
  });

  PurchaseHistoryState copyWith({
    List<PurchaseHistoryItem>? purchases,
    int? total,
    int? totalRubies,
    int? totalSpentCents,
    bool? isLoading,
    String? error,
  }) {
    return PurchaseHistoryState(
      purchases: purchases ?? this.purchases,
      total: total ?? this.total,
      totalRubies: totalRubies ?? this.totalRubies,
      totalSpentCents: totalSpentCents ?? this.totalSpentCents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Purchase History Notifier
class PurchaseHistoryNotifier extends StateNotifier<PurchaseHistoryState> {
  final IPaymentService _service;

  PurchaseHistoryNotifier(this._service) : super(PurchaseHistoryState());

  Future<void> loadHistory(String period, {int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _service.getPurchaseHistory(period, page);
      state = state.copyWith(
        purchases: response.purchases,
        total: response.total,
        totalRubies: response.totalRubies,
        totalSpentCents: response.totalSpentCents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<PurchaseResponse?> purchaseRubies(int rubiesAmount, String paymentMethodId) async {
    try {
      return await _service.purchaseRubies(rubiesAmount, paymentMethodId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> confirmPurchase(String purchaseId) async {
    try {
      await _service.confirmPurchase(purchaseId);
      await loadHistory('month');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// Providers
final learnerPaymentServiceProvider = Provider<IPaymentService>((ref) {
  if (kIsWeb) {
    return StripeWebService();
  } else {
    return LearnerPaymentService();
  }
});

final learnerPaymentProvider = 
    StateNotifierProvider<LearnerPaymentNotifier, LearnerPaymentState>((ref) {
  final service = ref.watch(learnerPaymentServiceProvider);
  return LearnerPaymentNotifier(service);
});

final purchaseHistoryProvider = 
    StateNotifierProvider<PurchaseHistoryNotifier, PurchaseHistoryState>((ref) {
  final service = ref.watch(learnerPaymentServiceProvider);
  return PurchaseHistoryNotifier(service);
});