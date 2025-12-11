// lib/screens/trainer/gift_exchange_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/profile_provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe; // Add 'as stripe'
import 'package:frontend/services/ruby_purchase_service.dart';
import 'package:frontend/app_theme.dart';
import '../../widgets/gradient_elevated_button.dart';



class RubyPackage {
  final String id;
  final int rubies;
  final double price;
  final String displayPrice;

  const RubyPackage({
    required this.id,
    required this.rubies,
    required this.price,
    required this.displayPrice,
  });

  static const List<RubyPackage> packages = [
    RubyPackage(id: 'package_3', rubies: 3, price: 1.99, displayPrice: '\$1.99'),
    RubyPackage(id: 'package_9', rubies: 9, price: 4.99, displayPrice: '\$4.99'),
    RubyPackage(id: 'package_15', rubies: 15, price: 6.99, displayPrice: '\$6.99'),
    RubyPackage(id: 'package_30', rubies: 30, price: 12.99, displayPrice: '\$12.99'),
    RubyPackage(id: 'package_60', rubies: 60, price: 24.99, displayPrice: '\$24.99'),
    RubyPackage(id: 'package_120', rubies: 120, price: 48.99, displayPrice: '\$48.99'),
    RubyPackage(id: 'package_240', rubies: 240, price: 96.99, displayPrice: '\$96.99'),
    RubyPackage(id: 'package_480', rubies: 480, price: 192.99, displayPrice: '\$192.99'),
  ];
}

class GiftExchangeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  
  const GiftExchangeScreen({
    Key? key,
    this.initialTab = 0, // Default to first tab
  }) : super(key: key);

  @override
  ConsumerState<GiftExchangeScreen> createState() => _GiftExchangeScreenState();
}

class _GiftExchangeScreenState extends ConsumerState<GiftExchangeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
    void initState() {
    super.initState();
    print('🔍 GiftExchangeScreen initialTab: ${widget.initialTab}'); // Add this

    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTab, // Use passed index
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void navigateToTab(int index) {
    setState(() {
      _tabController.index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Use go_router for navigation
            if (context.canPop()) {
              context.pop();
            } else {
              // Navigate to the main trainer dashboard
              context.go('/trainer-dashboard');
            }
          },
        ),
        title: const Text(
          'Gift Exchange',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'WITHDRAW'),
            Tab(text: 'BOOSTS'),
            Tab(text: 'RUBIES'),
          ],
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryOrange,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            const WithdrawTab(),
            BoostsTab(onBuyBoosts: () => _showBoostPurchaseModal()),
            const RubiesTab(),
          ],
        ),
      ),
    );
  }

  void _showBoostPurchaseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BoostPurchaseModal(
        navigateToRubiesTab: () => navigateToTab(2),
      ),
    );
  }
}

class WithdrawTab extends ConsumerStatefulWidget {
  const WithdrawTab({Key? key}) : super(key: key);

  @override
  ConsumerState<WithdrawTab> createState() => _WithdrawTabState();
}

class _WithdrawTabState extends ConsumerState<WithdrawTab> {
  int _shakeQuantity = 0;
  int _barQuantity = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(profileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (profile) {
        final totalAmount = (_shakeQuantity * 3 + _barQuantity * 5);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.fitneksGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalAmount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Amount earned as Trainer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _CounterCard(
                title: '\$3 per\nProtein Shake',
                available: profile.proteinShakes,
                selected: _shakeQuantity,
                value: _shakeQuantity * 3.0,
                color: AppTheme.challengeColor,
                onIncrement: () {
                  if (_shakeQuantity < profile.proteinShakes) {
                    setState(() => _shakeQuantity++);
                  }
                },
                onDecrement: () {
                  if (_shakeQuantity > 0) {
                    setState(() => _shakeQuantity--);
                  }
                },
              ),
              const SizedBox(height: 16),
              _CounterCard(
                title: '\$5 per\nProtein Bar',
                available: profile.proteinBars,
                selected: _barQuantity,
                value: _barQuantity * 5.0,
                color: AppTheme.primaryOrange,
                onIncrement: () {
                  if (_barQuantity < profile.proteinBars) {
                    setState(() => _barQuantity++);
                  }
                },
                onDecrement: () {
                  if (_barQuantity > 0) {
                    setState(() => _barQuantity--);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_shakeQuantity > 0 || _barQuantity > 0)
                    ? () => _processWithdrawal(profile)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'WITHDRAW \$${totalAmount}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processWithdrawal(dynamic profile) async {
    final totalAmount = _shakeQuantity * 3 + _barQuantity * 5;
    
    try {
      // Show processing indicator with proper context handling
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: Material(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        );
      }

      // TODO: Implement actual Stripe withdrawal logic here
      // This would typically involve:
      // 1. Calling your backend API to initiate a payout
      // 2. Backend creates a Stripe payout to the trainer's connected account
      // 3. Update the trainer's balance in the database
      // 4. Return success/failure response
      
      // Simulated API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading dialog safely
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully initiated withdrawal of \${totalAmount}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Reset quantities after successful withdrawal
        setState(() {
          _shakeQuantity = 0;
          _barQuantity = 0;
        });
        
        // Refresh profile to update balances
        ref.invalidate(profileProvider);
      }
    } catch (e) {
      // Close loading dialog safely if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _CounterCard extends StatelessWidget {
  final String title;
  final int available;
  final int selected;
  final double value;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterCard({
    required this.title,
    required this.available,
    required this.selected,
    required this.value,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  available.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'X',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                selected.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onDecrement,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.remove, size: 18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: onIncrement,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text(
            '=',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '\$${value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class BoostsTab extends ConsumerWidget {
  final VoidCallback onBuyBoosts;

  const BoostsTab({Key? key, required this.onBuyBoosts}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(profileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (profile) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Your Boosts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showBoostsHelp(context),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BoostCard(
                count: profile.profileBoosts,
                title: 'Profile Boost',
                subtitle: 'Stand out in your expertise',
                icon: Icons.bolt,
                iconColor: AppTheme.boosticonColor,
              ),
              const SizedBox(height: 12),
              _BoostCard(
                count: profile.notifyBoosts,
                title: 'Notify Boost',
                subtitle: 'Notify people around you about your live!',
                icon: Icons.campaign,
                iconColor: AppTheme.boosticonColor,
              ),
              const SizedBox(height: 32),
              const Text(
                'Your Protein',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${profile.proteinShakes + profile.proteinBars}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.proteinColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Protein',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.proteinColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.proteinColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.local_drink,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showProteinHelp(context, profile),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientElevatedButton(
                onPressed: onBuyBoosts,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'BUY BOOSTS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBoostsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Boosts'),
        content: const Text(
          'Boost your profile before going live to increase viewers',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showProteinHelp(BuildContext context, dynamic profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Protein Gifts'),
        content: const Text(
          'Protein Gifts are earned during your live streams. Use them to buy Boosts',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _BoostCard extends StatelessWidget {
  final int count;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _BoostCard({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class RubiesTab extends ConsumerStatefulWidget {
  const RubiesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<RubiesTab> createState() => _RubiesTabState();
}

class _RubiesTabState extends ConsumerState<RubiesTab> {
  RubyPackage? _selectedPackage;
  int _quantity = 0;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(profileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (profile) {
        // Don't show loading if we're just refreshing
        if (_isProcessing) {
          return Stack(
            children: [
              _buildContent(profile),
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Material(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return _buildContent(profile);
      },
    );
  }

  Widget _buildContent(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profile.rubies.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Rubies',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: RubyPackage.packages.length,
              itemBuilder: (context, index) {
                final package = RubyPackage.packages[index];
                final isSelected = _selectedPackage?.id == package.id;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedPackage?.id == package.id) {
                        _selectedPackage = null;
                        _quantity = 0;
                      } else {
                        _selectedPackage = package;
                        _quantity = 1;
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryOrange : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.diamond,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          package.rubies.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          package.displayPrice,
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
          if (_selectedPackage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: $_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'TOTAL: ${_selectedPackage!.displayPrice}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _processRubyPurchase(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CHECK OUT',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

 void _processRubyPurchase() async {
  if (_selectedPackage == null) return;
  
  setState(() {
    _isProcessing = true;
  });
  
  try {
    // Get current profile
    final currentProfile = ref.read(profileProvider).value;
    if (currentProfile == null) {
      throw Exception('Profile not found');
    }
    
    // Get purchase service (automatically uses token from authProvider)
    final purchaseService = ref.read(rubyPurchaseServiceProvider);
    
    // Process payment
    final success = await purchaseService.purchaseRubies(
      userId: currentProfile.id,
      packageId: _selectedPackage!.id,
      rubies: _selectedPackage!.rubies,
      amount: _selectedPackage!.price,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${_selectedPackage!.rubies} rubies!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      setState(() {
        _selectedPackage = null;
        _quantity = 0;
        _isProcessing = false;
      });
      
      // Wait for webhook to process, then refresh
      await Future.delayed(const Duration(seconds: 1));
      ref.invalidate(profileProvider);
    }
  } on stripe.StripeException catch (e) {
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
  } catch (e) {
    if (mounted) {
      setState(() => _isProcessing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
}

class BoostPurchaseModal extends ConsumerStatefulWidget {
  final VoidCallback navigateToRubiesTab;

  const BoostPurchaseModal({
    Key? key,
    required this.navigateToRubiesTab,
  }) : super(key: key);

  @override
  ConsumerState<BoostPurchaseModal> createState() => _BoostPurchaseModalState();
}

class _BoostPurchaseModalState extends ConsumerState<BoostPurchaseModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedBoostType = 'PROFILE';
  String _selectedCurrency = 'RUBIES';
  int _rubyQuantity = 0;
  int _proteinQuantity = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      setState(() {
        _selectedBoostType = _tabController.index == 0 ? 'PROFILE' : 'NOTIFY';
        _rubyQuantity = 0;
        _proteinQuantity = 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (profile) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.bolt),
                    text: 'Profile Boost',
                  ),
                  Tab(
                    icon: Icon(Icons.campaign),
                    text: 'Notify Boost',
                  ),
                ],
                labelColor: AppTheme.primaryOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryOrange,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBoostTab(
                      boostType: 'PROFILE',
                      exchangeRate: '9 Rubies or 3 Protein = 1 Profile Boost',
                      rubyRate: 9,
                      proteinRate: 3,
                      profile: profile,
                    ),
                    _buildBoostTab(
                      boostType: 'NOTIFY',
                      exchangeRate: '15 Rubies or 5 Protein = 1 Notify Boost',
                      rubyRate: 15,
                      proteinRate: 5,
                      profile: profile,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoostTab({
    required String boostType,
    required String exchangeRate,
    required int rubyRate,
    required int proteinRate,
    required dynamic profile,
  }) {
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalProtein = profile.proteinShakes + profile.proteinBars;
    
    final String boostTitle = boostType == 'PROFILE' 
        ? 'Buy Profile Boosts' 
        : 'Buy Notify Boosts';
    
    final String boostDescription = boostType == 'PROFILE'
        ? 'Make your profile stand out in search results and recommendations'
        : 'Send push notifications to users nearby when you go live';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              boostTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              boostDescription,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: Text(
                'Exchange Rate:\n$exchangeRate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            _PaymentOption(
              icon: Icons.diamond,
              iconColor: Colors.red,
              quantity: _rubyQuantity,
              available: profile.rubies,
              rate: rubyRate,
              isSelected: _selectedCurrency == 'RUBIES',
              onSelect: () => setState(() {
                _selectedCurrency = 'RUBIES';
                _proteinQuantity = 0;
              }),
              onIncrement: () => setState(() {
                if (profile.rubies >= (_rubyQuantity + 1) * rubyRate) {
                  _rubyQuantity++;
                  _proteinQuantity = 0;
                  _selectedCurrency = 'RUBIES';
                }
              }),
              onDecrement: () => setState(() {
                if (_rubyQuantity > 0) _rubyQuantity--;
              }),
            ),
            const SizedBox(height: 16),
            _PaymentOption(
              icon: Icons.local_drink,
              iconColor: Colors.green,
              quantity: _proteinQuantity,
              available: totalProtein,
              rate: proteinRate,
              isSelected: _selectedCurrency == 'PROTEIN',
              onSelect: () => setState(() {
                _selectedCurrency = 'PROTEIN';
                _rubyQuantity = 0;
              }),
              onIncrement: () => setState(() {
                if (totalProtein >= (_proteinQuantity + 1) * proteinRate) {
                  _proteinQuantity++;
                  _rubyQuantity = 0;
                  _selectedCurrency = 'PROTEIN';
                }
              }),
              onDecrement: () => setState(() {
                if (_proteinQuantity > 0) _proteinQuantity--;
              }),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Qty: ',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  Text(
                    (_selectedCurrency == 'RUBIES' ? _rubyQuantity : _proteinQuantity).toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_rubyQuantity > 0 || _proteinQuantity > 0)
                  ? () => _processExchange(boostType, _selectedCurrency == 'RUBIES' ? _rubyQuantity : _proteinQuantity)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'EXCHANGE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _processExchange(String boostType, int quantity) async {
    try {
      // Show processing indicator with proper context handling
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: Material(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        );
      }

      // TODO: Implement actual exchange logic with backend
      // This would typically involve:
      // 1. Calling your backend API to process the exchange
      // 2. Deducting rubies/protein from user balance
      // 3. Adding boosts to user account
      // 4. Updating the database
      
      // Simulated API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading dialog safely
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Close modal safely
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully exchanged for $quantity $boostType boost(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Refresh profile to update balances
      ref.invalidate(profileProvider);
    } catch (e) {
      // Close loading dialog safely if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exchange failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int quantity;
  final int available;
  final int rate;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PaymentOption({
    required this.icon,
    required this.iconColor,
    required this.quantity,
    required this.available,
    required this.rate,
    required this.isSelected,
    required this.onSelect,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 16),
            Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}