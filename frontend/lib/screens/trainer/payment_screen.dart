import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../services/payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_elevated_button.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentData();
    });
  }

  /// Loads payment data including Stripe link status and payout history
  Future<void> _loadPaymentData() async {
    final paymentState = ref.read(paymentProvider.notifier);
    await paymentState.loadPayoutHistory();
  }

  /// Handles Stripe account linking/management
Future<void> _handleStripeLink() async {
  try {
    // Get token first, before showing dialog
    final authState = ref.read(authProvider);
    final token = authState.token;

    if (token == null) {
      _showErrorMessage('No authentication token available');
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD35400),
        ),
      ),
    );

    // Get Stripe onboarding URL
    final url = await _paymentService.getStripeOnboardingUrl(token);
    
    // Close loading dialog
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Refresh after user returns
        if (mounted) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _loadPaymentData();
          });
        }
      } else {
        if (mounted) _showErrorMessage('Could not open Stripe link');
      }
    } else {
      if (mounted) _showErrorMessage('No URL received from server');
    }
  } catch (e) {
    // Always try to close dialog if it's open
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (mounted) {
      _showErrorMessage('Failed to connect to Stripe: ${e.toString()}');
    }
  }
}

  /// Shows error message to user
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    const primaryOrange = Color(0xFFD35400);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadPaymentData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GO LIVE Button (matching the image)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: GradientElevatedButton(
                    onPressed: () {
                      // Navigate to go live functionality
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'GO LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Stripe Account Section
                _buildStripeAccountSection(paymentState, primaryOrange),
                const SizedBox(height: 48),

                // Payout History Section
                _buildPayoutHistorySection(paymentState, primaryOrange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Stripe account linking/management section
  Widget _buildStripeAccountSection(
    PaymentState paymentState,
    Color primaryOrange,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paymentState.isStripeLinked
                ? 'Your payout account is linked ✓'
                : 'Link your account to receive payouts',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: GradientElevatedButton(
              onPressed: _handleStripeLink,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                paymentState.isStripeLinked
                    ? 'Manage Account'
                    : 'Link Payout Account',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the payout history section with filter buttons
  Widget _buildPayoutHistorySection(
    PaymentState paymentState,
    Color primaryOrange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // History title and filter buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                _buildFilterButton(
                  'Week',
                  paymentState.selectedPeriod == PayoutPeriod.week,
                  primaryOrange,
                  () {
                    ref
                        .read(paymentProvider.notifier)
                        .changeFilter(PayoutPeriod.week);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  'Month',
                  paymentState.selectedPeriod == PayoutPeriod.month,
                  primaryOrange,
                  () {
                    ref
                        .read(paymentProvider.notifier)
                        .changeFilter(PayoutPeriod.month);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Payout list or empty state
        if (paymentState.isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (paymentState.payouts.isEmpty)
          _buildEmptyState(paymentState.selectedPeriod)
        else
          _buildPayoutList(paymentState.payouts),
      ],
    );
  }

  /// Builds individual filter button
  Widget _buildFilterButton(
    String label,
    bool isActive,
    Color primaryOrange,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? primaryOrange : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Builds the list of payouts
  Widget _buildPayoutList(List<Payout> payouts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return _buildPayoutItem(payout);
      },
    );
  }

  /// Builds individual payout item
  Widget _buildPayoutItem(Payout payout) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currencyFormatter.format(payout.amount / 100),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormatter.format(payout.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          _buildStatusBadge(payout.status),
        ],
      ),
    );
  }

  /// Builds status badge for payout
  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        label = 'Completed';
        break;
      case 'PENDING':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        label = 'Pending';
        break;
      case 'FAILED':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        label = 'Failed';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Builds empty state message
  Widget _buildEmptyState(PayoutPeriod period) {
    final periodText = period == PayoutPeriod.week ? 'week' : 'month';
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "You don't have any payment in this $periodText.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}