import '../providers/payment_provider.dart';
import 'api_service.dart';

/// Service class for handling payment-related API calls
class PaymentService {
  final ApiService _apiService = ApiService();

  /// Gets Stripe onboarding URL for account linking
  Future<String?> getStripeOnboardingUrl(String token) async {
    try {
      final response = await _apiService.post(
        '/api/payment/onboard-stripe',
        {},
        token: token,
      );
      return response['url'] as String?;
    } catch (e) {
      print('Error getting Stripe onboarding URL: $e');
      rethrow;
    }
  }

  /// Fetches payout history with optional period filter
  Future<List<Payout>> getPayoutHistory(String period, String token) async {
    try {
      final response = await _apiService.get(
        '/api/payment/payouts?period=$period',
        token: token,
      );
      
      final payoutsList = response['payouts'] as List;
      return payoutsList.map((json) => Payout.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching payout history: $e');
      rethrow;
    }
  }

  /// Checks if the user has linked their Stripe account
Future<bool> isStripeAccountLinked(String token) async {
  try {
    final response = await _apiService.get(
      '/api/payment/stripe-status',
      token: token,
    );
    return response['isLinked'] as bool? ?? false;
  } catch (e) {
    print('Error checking Stripe status: $e');
    return false;
  }
}




  
}