import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../providers/gift_exchange_provider.dart' as gift;
import '../providers/learner_payment_provider.dart';  // ✅ Change this line
import '../providers/auth_provider.dart'; 
import '../app_theme.dart';


class RubyPurchaseModal extends ConsumerStatefulWidget {
  final String defaultPaymentMethodId;

  const RubyPurchaseModal({
    Key? key,
    required this.defaultPaymentMethodId, // ✅ Back to required (but not used)
  }) : super(key: key);

  @override
  ConsumerState<RubyPurchaseModal> createState() => _RubyPurchaseModalState();
}

class _RubyPurchaseModalState extends ConsumerState<RubyPurchaseModal> {
  int? selectedPackageIndex;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> packages = [
    {'rubies': 3, 'price': 1.99},
    {'rubies': 9, 'price': 4.99},
    {'rubies': 15, 'price': 6.99},
    {'rubies': 30, 'price': 12.99},
    {'rubies': 60, 'price': 24.99},
    {'rubies': 120, 'price': 48.99},
    {'rubies': 240, 'price': 96.99},
    {'rubies': 480, 'price': 192.99},
  ];

  @override
  Widget build(BuildContext context) {
    print('🏗️ RubyPurchaseModal build called');  // ✅ ADD THESE 3 LINES HERE
  print('   - Selected index: $selectedPackageIndex');
  print('   - Is processing: $_isProcessing');
    
    
    
    final selectedPackage = selectedPackageIndex != null
        ? packages[selectedPackageIndex!]
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Purchase Rubies',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Ruby Packages Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final package = packages[index];
                  final isSelected = selectedPackageIndex == index;

                  return GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () {
                            setState(() {
                              selectedPackageIndex = index;
                            });
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.diamond,
                                  color: Colors.red, size: 24),
                              const SizedBox(width: 5),
                              Text(
                                package['rubies'].toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '\$${package['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Total and Checkout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                if (selectedPackage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        '\$${selectedPackage['price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: selectedPackage != null && !_isProcessing
                        ? _processCheckout
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Check Out',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout() async {
  print('🛒 ========================================');
  print('🛒 CHECKOUT STARTED');
  print('🛒 ========================================');
  
  if (selectedPackageIndex == null) {
    print('❌ No package selected');
    return;
  }

  final selectedPackage = packages[selectedPackageIndex!];
  final rubiesAmount = selectedPackage['rubies'] as int;
  final price = selectedPackage['price'] as double;

  print('📦 Selected package:');
  print('   - Rubies: $rubiesAmount');
  print('   - Price: \$$price');

  setState(() => _isProcessing = true);

  try {
    print('🔧 Getting purchase service...');
    final purchaseService = ref.read(learnerPaymentServiceProvider);
    print('✅ Purchase service type: ${purchaseService.runtimeType}');
    
    print('👤 Getting auth state...');
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    print('   - User ID: $userId');
    print('   - User email: ${authState.user?.email}');

    if (userId == null) {
      print('❌ User not authenticated');
      throw Exception('User not authenticated');
    }

    print('💳 Calling purchaseRubies on service...');
    print('   - Service: ${purchaseService.runtimeType}');
    print('   - Rubies amount: $rubiesAmount');

    final response = await purchaseService.purchaseRubies(
      rubiesAmount,
      '', // paymentMethodId not needed for web
    );

    print('✅ purchaseRubies returned successfully');
    print('   - Response ID: ${response.id}');
    print('   - Response type: ${response.runtimeType}');

    if (response.id != null) {
      print('📝 Confirming purchase with ID: ${response.id}');
      await purchaseService.confirmPurchase(response.id);
      print('✅ Purchase confirmed successfully');
    } else {
      print('⚠️ No purchase ID returned');
    }

    if (mounted) {
      print('✅ Purchase complete, showing success message');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Successfully purchased $rubiesAmount rubies!',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        selectedPackageIndex = null;
        _isProcessing = false;
      });

      print('🔄 Refreshing balances...');
      await Future.delayed(const Duration(seconds: 1));
      ref.read(gift.balancesProvider.notifier).refreshBalances();

      if (mounted) {
        print('👋 Closing modal');
        Navigator.pop(context);
      }
    }
  } on stripe.StripeException catch (e) {
    print('❌ ========================================');
    print('❌ STRIPE EXCEPTION CAUGHT');
    print('❌ ========================================');
    print('   - Error code: ${e.error.code}');
    print('   - Error message: ${e.error.localizedMessage}');
    print('   - Error type: ${e.error.type}');
    
    if (mounted) {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.error.localizedMessage ?? 'Payment cancelled'),
          backgroundColor: AppTheme.primaryOrange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e, stackTrace) {
    print('❌ ========================================');
    print('❌ GENERAL EXCEPTION CAUGHT');
    print('❌ ========================================');
    print('   - Error: $e');
    print('   - Error type: ${e.runtimeType}');
    print('   - Stack trace:');
    print(stackTrace.toString());

    if (mounted) {
      setState(() => _isProcessing = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Purchase Failed'),
            ],
          ),
          content: Text(
            e.toString(),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  } finally {
    print('🏁 Checkout process finished');
    print('🏁 ========================================');
  }
}
}