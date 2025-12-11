import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:intl/intl.dart';
import '../../providers/learner_payment_provider.dart';
import '../../models/payment_models.dart';
import '../../providers/gift_exchange_provider.dart' as gift; // ✅ Add this
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/stripe_web_service.dart';
import '../../app_theme.dart';


class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isAddingCard = false;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learnerPaymentProvider.notifier).loadPaymentMethods();
      ref.read(purchaseHistoryProvider.notifier).loadHistory(_selectedPeriod);
    });
  }

  Future<void> _handleAddCard() async {
  if (kIsWeb) {
    await _handleAddCardWeb();
  } else {
    await _handleAddCardMobile();
  }
}

// Web implementation using Stripe.js
Future<void> _handleAddCardWeb() async {
  setState(() => _isAddingCard = true);

  try {
    final setupIntent = await ref
        .read(learnerPaymentProvider.notifier)
        .createSetupIntent();

    if (setupIntent == null) {
      throw Exception('Failed to create setup intent');
    }

    print('🌐 [WEB] Starting card setup with Stripe.js...');
    
    // Get the web service and call Stripe.js setup
    final service = ref.read(learnerPaymentServiceProvider);
    final paymentMethodId = await service.setupCardWithStripeJs(setupIntent.clientSecret);
    
    if (paymentMethodId != null) {
      print('✅ [WEB] Got payment method ID: $paymentMethodId');
      
      await ref.read(learnerPaymentProvider.notifier).addPaymentMethod(
        paymentMethodId,
        setAsDefault: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added successfully')),
        );
      }
    } else {
      print('⚠️ [WEB] Card setup cancelled');
    }
  } catch (e) {
    print('❌ [WEB] Card setup error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  } finally {
    setState(() => _isAddingCard = false);
  }
}

// Mobile implementation using Flutter Stripe SDK
Future<void> _handleAddCardMobile() async {
  setState(() => _isAddingCard = true);

  try {
    final setupIntent = await ref
        .read(learnerPaymentProvider.notifier)
        .createSetupIntent();

    if (setupIntent == null) {
      throw Exception('Failed to create setup intent');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'FITNEKS',
        setupIntentClientSecret: setupIntent.clientSecret,
        style: ThemeMode.light,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: AppTheme.primaryOrange,
          ),
          shapes: PaymentSheetShape(
            borderRadius: 8.0,
          ),
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    
    final setupIntentResult = await Stripe.instance.retrieveSetupIntent(
      setupIntent.clientSecret,
    );

    if (setupIntentResult.paymentMethodId != null) {
      await ref.read(learnerPaymentProvider.notifier).addPaymentMethod(
        setupIntentResult.paymentMethodId!,
        setAsDefault: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added successfully')),
        );
      }
    }
  } on StripeException catch (e) {
    if (mounted && e.error.code != FailureCode.Canceled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.error.message}')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  } finally {
    setState(() => _isAddingCard = false);
  }
}

  void _handleRemoveCard(String methodId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: const Text('Are you sure you want to remove this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(learnerPaymentProvider.notifier)
                  .removePaymentMethod(methodId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card removed')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _handleSetDefault(String methodId) async {
    await ref
        .read(learnerPaymentProvider.notifier)
        .setDefaultPaymentMethod(methodId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default card updated')),
    );
  }


  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(learnerPaymentProvider);
    final historyState = ref.watch(purchaseHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(learnerPaymentProvider.notifier).loadPaymentMethods();
          await ref
              .read(purchaseHistoryProvider.notifier)
              .loadHistory(_selectedPeriod);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPaymentMethodsSection(paymentState),
              const SizedBox(height: 30),

              _buildPurchaseHistorySection(historyState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(LearnerPaymentState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Methods',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (!_isAddingCard)
                TextButton.icon(
                  onPressed: _handleAddCard,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Card'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryOrange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (state.isLoading && state.paymentMethods.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (state.paymentMethods.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.credit_card_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No payment methods added',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a card to purchase rubies',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...state.paymentMethods.map((method) => _buildPaymentMethodCard(method)),




          if (_isAddingCard) ...[
            const SizedBox(height: 20),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                  ),
                  SizedBox(width: 16),
                  Text('Adding card...'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: method.isDefault ? AppTheme.primaryOrange.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: method.isDefault ? AppTheme.primaryOrange : Colors.grey[300]!,
          width: method.isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: _getCardBrandIcon(method.cardBrand),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '•••• ${method.cardLast4}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Expires ${method.cardExpMonth.toString().padLeft(2, '0')}/${method.cardExpYear}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'default') {
                _handleSetDefault(method.id);
              } else if (value == 'remove') {
                _handleRemoveCard(method.id);
              }
            },
            itemBuilder: (context) => [
              if (!method.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 20),
                      SizedBox(width: 8),
                      Text('Set as Default'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getCardBrandIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Text('VISA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
      case 'mastercard':
        return const Text('MC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
      case 'amex':
        return const Text('AMEX', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
      default:
        return Icon(Icons.credit_card, size: 20, color: Colors.grey[600]);
    }
  }

  Widget _buildPurchaseHistorySection(PurchaseHistoryState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Purchase History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'week',
                      label: SizedBox(
                        width: double.infinity,
                        child: Text('Week', textAlign: TextAlign.center),
                      ),
                    ),
                    ButtonSegment(
                      value: 'month',
                      label: SizedBox(
                        width: double.infinity,
                        child: Text('Month', textAlign: TextAlign.center),
                      ),
                    ),
                    ButtonSegment(
                      value: 'all',
                      label: SizedBox(
                        width: double.infinity,
                        child: Text('All', textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (val) {
                    setState(() => _selectedPeriod = val.first);
                    ref
                        .read(purchaseHistoryProvider.notifier)
                        .loadHistory(val.first);
                  },
                ),
              ),
            ],
          ),



          const SizedBox(height: 20),

            Container(
              width: double.infinity, // ✅ Add this
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3), width: 2),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final balancesAsync = ref.watch(gift.balancesProvider);
                  return balancesAsync.when(
                    data: (balances) => Column(
                      children: [
                        const Icon(Icons.diamond, color: AppTheme.primaryOrange, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '${balances.rubies}',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Current Ruby Balance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading balance'),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          

          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.purchases.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No purchases in this period',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.purchases.length,
              itemBuilder: (context, index) {
                final purchase = state.purchases[index];
                return _buildPurchaseItem(purchase);
              },
            ),
        ],
      ),
    );
  }

 Widget _buildPurchaseItem(PurchaseHistoryItem item) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.diamond, color: AppTheme.primaryOrange, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              '${item.rubiesAmount} Rubies',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          
          // ✅ Just show the date on the right
          Text(
            dateFormat.format(item.createdAt),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}