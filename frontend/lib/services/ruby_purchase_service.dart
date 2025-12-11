import 'dart:convert';
import 'package:flutter/material.dart'; // ADD THIS LINE
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../config/stripe_config.dart';
import '../providers/auth_provider.dart';

class RubyPurchaseService {
  final String authToken;
  
  RubyPurchaseService(this.authToken);

  Future<bool> purchaseRubies({
  required int userId,
  required String packageId,
  required int rubies,
  required double amount,
}) async {
  try {
    // Step 1: Create purchase (get client secret and purchase ID)
    final createResponse = await http.post(
      Uri.parse('${StripeConfig.backendUrl}/api/learner/purchase-rubies'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rubiesAmount': rubies,
      }),
    );

    if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
      final error = jsonDecode(createResponse.body);
      throw Exception(error['message'] ?? 'Failed to create payment');
    }

    final createData = jsonDecode(createResponse.body);
    final clientSecret = createData['clientSecret'];
    final purchaseId = createData['id']; // Get purchase ID

    // Step 2: Initialize and present payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Fitneks',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // Step 3: Confirm purchase (THIS WAS MISSING!)
    final confirmResponse = await http.post(
      Uri.parse('${StripeConfig.backendUrl}/api/learner/purchase-rubies/$purchaseId/confirm'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (confirmResponse.statusCode != 200) {
      throw Exception('Failed to confirm purchase');
    }

    print('✅ Purchase confirmed and rubies added to balance');
    return true;

  } on StripeException catch (e) {
    print('Stripe error: ${e.error.localizedMessage}');
    throw Exception(e.error.localizedMessage ?? 'Payment failed');
  } catch (e) {
    print('Error: $e');
    rethrow;
  }
}
}

// Riverpod provider that uses auth token from authProvider
final rubyPurchaseServiceProvider = Provider<RubyPurchaseService>((ref) {
  final authToken = ref.watch(authProvider).token ?? '';
  
  print('🔑 Auth token for ruby purchase: ${authToken.substring(0, 20)}...'); // ✅ Add this
  
  return RubyPurchaseService(authToken);
});