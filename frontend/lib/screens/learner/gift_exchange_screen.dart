import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/gift_exchange/gift_balance_summary.dart';
import '../../widgets/gift_exchange/gift_purchase_widget.dart';
import '../../widgets/learner_ruby_purchase_modal.dart';
import '../../providers/gift_exchange_provider.dart';
import '../../models/gift_exchange_purchase.dart';
import '../../models/gift_type.dart';
import '../../app_theme.dart';

// Add local state provider for selected period
final selectedPeriodProvider = StateProvider<String>((ref) => 'week');

class GiftExchangeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  
  const GiftExchangeScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<GiftExchangeScreen> createState() => _GiftExchangeScreenState();
}

class _GiftExchangeScreenState extends ConsumerState<GiftExchangeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/learner-dashboard');
            }
          },
        ),
        title: const Text(
          'Gift Exchange',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Custom Tab Bar (matching Friends page style)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryOrange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryOrange,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Gifts'),
                Tab(text: 'Rubies'),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiftsTab(),
                _buildRubiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsTab() {
    final showPurchasePanel = ref.watch(showPurchasePanelProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final purchaseHistoryAsync = ref.watch(purchaseHistoryProvider(selectedPeriod));

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const GiftBalanceSummary(),
          if (showPurchasePanel) const GiftPurchaseWidget(),
          const SizedBox(height: 24),
          
          // Gift History Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gifts History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _buildPeriodToggle(),
                  ],
                ),
                const SizedBox(height: 16),
                
                // History List
                purchaseHistoryAsync.when(
                  loading: () => Container(
                    padding: const EdgeInsets.all(40),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Error loading history: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  data: (purchases) {
                        print('=== GIFT HISTORY DEBUG ===');
                        for (var p in purchases) {
                          print('Gift: ${p.giftName}, Quantity: ${p.quantity}, Date: ${p.date}');
                        }
                        print('========================');


                    if (purchases.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No gift history yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        final purchase = purchases[index];
                        return _buildHistoryItem(purchase);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ✅ Fixed: Matching profile page toggle style
 Widget _buildPeriodToggle() {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Week', 'week', selectedPeriod),
          _buildToggleOption('Month', 'month', selectedPeriod),
        ],
      ),
    );
  }

 Widget _buildToggleOption(String label, String value, String selectedPeriod) {
    final isSelected = selectedPeriod == value;
    
    return GestureDetector(
      onTap: () {
        ref.read(selectedPeriodProvider.notifier).state = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFE4D6) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: AppTheme.primaryOrange),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Fixed: Show actual quantity and gift name
  Widget _buildHistoryItem(GiftExchangePurchase purchase) {
    final giftType = _parseGiftType(purchase.giftName);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            _getGiftIcon(giftType),
            size: 32,
            color: _getGiftColor(giftType),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.giftName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${purchase.quantity} ${purchase.quantity == 1 ? 'gift' : 'gifts'}', // ✅ Fixed: Show actual quantity
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(purchase.date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  GiftType _parseGiftType(String giftName) {
    final lowerName = giftName.toLowerCase();
    
    if (lowerName.contains('shake')) {
      return GiftType.proteinShake;
    } else if (lowerName.contains('bar')) {
      return GiftType.proteinBar;
    } else if (lowerName.contains('protein')) {
      return GiftType.protein;
    }
    
    return GiftType.protein;
  }

  IconData _getGiftIcon(GiftType type) {
    switch (type) {
      case GiftType.protein:
        return Icons.food_bank;
      case GiftType.proteinShake:
        return Icons.liquor;
      case GiftType.proteinBar:
        return Icons.local_drink;
    }
  }

  Color _getGiftColor(GiftType type) {
    switch (type) {
      case GiftType.protein:
        return const Color(0xFF4CAF50);
      case GiftType.proteinShake:
        return const Color(0xFF4E6FFF);
      case GiftType.proteinBar:
        return AppTheme.primaryOrange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal(); // Convert UTC to local time
    
    // Reset time to midnight for accurate day comparison
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(localDate.year, localDate.month, localDate.day);
    final difference = today.difference(compareDate).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${localDate.month}/${localDate.day}/${localDate.year}';
    }
  }

  Widget _buildRubiesTab() {
    final balancesAsync = ref.watch(balancesProvider);

    return balancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(balancesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (balances) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ruby Balance Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      balances.rubies.toString(),
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
              const SizedBox(height: 24),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use rubies to buy gifts for your trainers during their live streams!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Buy Rubies Button
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const RubyPurchaseModal(
                      defaultPaymentMethodId: '',
                    ),
                  ).then((_) {
                    ref.read(balancesProvider.notifier).refreshBalances();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'BUY RUBIES',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}