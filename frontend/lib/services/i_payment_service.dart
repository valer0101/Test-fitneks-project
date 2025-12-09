import '../models/payment_models.dart';

/// Interface that both web and mobile payment services must implement
/// This allows the app to work with either service without knowing which one it is
abstract class IPaymentService {
  /// Creates a setup intent for adding a new payment method
  Future<SetupIntentResponse> createSetupIntent();
  
  /// Gets all saved payment methods for the current user
  Future<List<PaymentMethod>> getPaymentMethods();
  
  /// Adds a new payment method to the user's account
  Future<PaymentMethod> addPaymentMethod(String paymentMethodId, bool setAsDefault);
  
  /// Removes a payment method from the user's account
  Future<void> removePaymentMethod(String methodId);
  
  /// Sets a payment method as the default
  Future<void> setDefaultPaymentMethod(String methodId);
  
  /// Gets the purchase history for a given period and page
  Future<PurchaseHistoryResponse> getPurchaseHistory(String period, int page);
  
  /// Purchases rubies using a payment method
  Future<PurchaseResponse> purchaseRubies(int rubiesAmount, String paymentMethodId);
  
  /// Confirms a purchase after payment is complete
  Future<void> confirmPurchase(String purchaseId);
  
  /// Gets the current rubies balance
  Future<int> getRubiesBalance();


  /// Web-specific: Setup card using Stripe.js (returns null on mobile)
  Future<String?> setupCardWithStripeJs(String clientSecret);



}