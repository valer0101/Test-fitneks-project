// lib/widgets/gifts_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class GiftsTab extends ConsumerWidget {
  const GiftsTab({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    
    return profileAsync.when(
      data: (profile) => Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          children: [
            // Gift Cards
            Expanded(
              child: Column(
                children: [
                  _buildGiftCard(
                    context,
                    count: profile.proteinShakes,
                    title: 'Protein Shakes',
                    icon: Icons.local_drink,
                    color: Colors.blue,
                    isDesktop: isDesktop,
                  ),
                  const SizedBox(height: 16),
                  _buildGiftCard(
                    context,
                    count: profile.proteinBars,
                    title: 'Protein Bars',
                    icon: Icons.rectangle,
                    color: const Color(0xFFFF6B00),
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ),
            
            // Cash Out Section
            Container(
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
                  Text(
                    '\$${profile.giftValue}',
                    style: TextStyle(
                      fontSize: isDesktop ? 48 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: profile.giftValue > 0 
                        ? () => _cashOut(context, ref)
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        'CASH OUT',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            const Text('Failed to load gifts'),
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
  
  Widget _buildGiftCard(
    BuildContext context, {
    required int count,
    required String title,
    required IconData icon,
    required Color color,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
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
          // Count
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
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          
          // Icon
          Container(
            width: isDesktop ? 60 : 48,
            height: isDesktop ? 60 : 48,
            decoration: BoxDecoration(
              color: color,
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
    );
  }
  
  void _cashOut(BuildContext context, WidgetRef ref) {
    // Navigate to gift exchange page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cash Out'),
        content: const Text('Navigating to Gift Exchange page...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}