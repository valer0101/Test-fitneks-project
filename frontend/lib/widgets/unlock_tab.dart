// lib/widgets/unlock_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../app_theme.dart';

class UnlockTab extends ConsumerWidget {
  const UnlockTab({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    
    return profileAsync.when(
      data: (profile) {
        // Check if user has completed a 30-minute stream this week
        final hasCompletedStream = profile.lastStreamCompletedAt != null &&
            DateTime.now().difference(profile.lastStreamCompletedAt!).inDays < 7;
        
        final unlockedGifts = profile.unlockedGifts ?? {};
        final hasGiftsToUnlock = unlockedGifts.isNotEmpty;
        
        return Container(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasGiftsToUnlock) ...[
                    // No gifts available state
                    Icon(
                      Icons.lock_outline,
                      size: isDesktop ? 100 : 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No gifts to unlock yet',
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete a 30-minute workout to unlock!',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (hasCompletedStream) ...[
                    // Ready to collect state
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 32 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_open,
                            size: isDesktop ? 80 : 60,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '\$${_calculateUnlockedValue(unlockedGifts)}',
                            style: TextStyle(
                              fontSize: isDesktop ? 48 : 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ready to collect!',
                            style: TextStyle(
                              fontSize: isDesktop ? 18 : 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _collectGifts(context, ref),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 16 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'COLLECT',
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
                  ] else ...[
                    // Locked state - needs to complete stream
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 32 : 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock,
                            size: isDesktop ? 80 : 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '\$${_calculateUnlockedValue(unlockedGifts)}',
                            style: TextStyle(
                              fontSize: isDesktop ? 48 : 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete a 30-minute workout to unlock!',
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 16 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'COLLECT',
                                style: TextStyle(
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Complete a 30-minute workout to unlock these gifts',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
            const Text('Failed to load unlock data'),
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
  
  int _calculateUnlockedValue(Map<String, dynamic> unlockedGifts) {
    int total = 0;
    if (unlockedGifts['proteinShakes'] != null) {
      total += (unlockedGifts['proteinShakes'] as int) * 5;
    }
    if (unlockedGifts['proteinBars'] != null) {
      total += (unlockedGifts['proteinBars'] as int) * 3;
    }
    return total;
  }
  
  void _collectGifts(BuildContext context, WidgetRef ref) {
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Gifts Collected!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your gifts have been added to your account',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Update the backend to transfer gifts
              ref.read(profileProvider.notifier).refreshProfile();
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}