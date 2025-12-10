// lib/widgets/boosts_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import 'gradient_elevated_button.dart';
import 'package:frontend/app_theme.dart';

class BoostsTab extends ConsumerWidget {
  const BoostsTab({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    
    return profileAsync.when(
      data: (profile) => Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          children: [
            _buildBoostCard(
              context,
              ref,
              count: profile.profileBoosts,
              title: 'Profile Boost',
              subtitle: 'Stand out in your expertise',
              icon: Icons.bolt,
              color: Colors.purple,
              isDesktop: isDesktop,
              boostType: 'profile',
            ),
            const SizedBox(height: 16),
            _buildBoostCard(
              context,
              ref,
              count: profile.notifyBoosts,
              title: 'Notify Boost',
              subtitle: 'Notify people around you about your live!',
              icon: Icons.campaign,
              color: Colors.blue,
              isDesktop: isDesktop,
              boostType: 'notify',
            ),
            const Spacer(),
            _buildGetMoreBoostsSection(context, isDesktop),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text('Failed to load boosts'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(profileProvider.notifier).refreshProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBoostCard(
    BuildContext context,
    WidgetRef ref, {
    required int count,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDesktop,
    required String boostType,
  }) {
    return GestureDetector(
      onTap: count > 0 
        ? () => _showUseBoostDialog(context, ref, boostType, title)
        : () => _showNoBoostsDialog(context, boostType),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: count > 0 ? color.withOpacity(0.3) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 60 : 48,
              height: isDesktop ? 60 : 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: count > 0 ? color : Colors.grey[400],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: count > 0 ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      color: count > 0 ? Colors.grey[600] : Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: isDesktop ? 60 : 48,
              height: isDesktop ? 60 : 48,
              decoration: BoxDecoration(
                color: count > 0 ? color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isDesktop ? 28 : 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGetMoreBoostsSection(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
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
        children: [
          Icon(
            Icons.rocket_launch,
            size: isDesktop ? 48 : 36,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 16),
          Text(
            'Need more boosts?',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get more boosts to increase your reach!',
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GradientElevatedButton(
            onPressed: () => _navigateToGiftExchange(context),
            style: ButtonStyle(
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 24,
                  vertical: isDesktop ? 12 : 10,
                ),
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textStyle: MaterialStateProperty.all<TextStyle>(
                TextStyle(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            child: Text(
              'Get Boosts',
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showUseBoostDialog(BuildContext context, WidgetRef ref, String boostType, String boostName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Use $boostName?'),
        content: Text('Would you like to use your $boostName Boost?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _activateBoost(context, ref, boostType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
            ),
            child: const Text('BOOST'),
          ),
        ],
      ),
    );
  }
  
  void _showNoBoostsDialog(BuildContext context, String boostType) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No Boosts Available'),
        content: const Text('You do not have any boosts. Would you like to boost your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryOrange,
            ),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _navigateToGiftExchangeWithBoost(context, boostType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC612A),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
  
  void _activateBoost(BuildContext context, WidgetRef ref, String boostType) {
    // Update local state
    ref.read(profileProvider.notifier).updateBoostCount(boostType, -1);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          boostType == 'profile' 
            ? 'Profile Boost activated!' 
            : 'Notify Boost activated!',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // TODO: Call backend API to activate boost
    // final dio = ref.read(dioProvider);
    // await dio.post('/boosts/activate', data: {'type': boostType});
  }
  
    void _navigateToGiftExchange(BuildContext context) {
      context.go('/trainer-dashboard/gift-exchange', extra: 1); // Pass tab index directly
    }

    void _navigateToGiftExchangeWithBoost(BuildContext context, String boostType) {
      context.go('/trainer-dashboard/gift-exchange', extra: 1); // Boosts is tab 1
    }
}