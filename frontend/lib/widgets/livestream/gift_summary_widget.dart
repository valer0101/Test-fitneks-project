import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import '../../app_theme.dart';

class GiftSummaryWidget extends ConsumerWidget {
  final String livestreamId;
  
  const GiftSummaryWidget({
    Key? key,
    required this.livestreamId,
  }) : super(key: key);

 @override
Widget build(BuildContext context, WidgetRef ref) {
final giftData = ref.watch(giftDataProvider(livestreamId));
  
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildGiftBadge(Icons.diamond, giftData.rubyCount, Colors.red),
      const SizedBox(width: 4),
      _buildGiftBadge(Icons.local_drink, giftData.proteinShakeCount, const Color(0xFF2B5FFF)),
      const SizedBox(width: 4),
      _buildGiftBadge(Icons.bakery_dining, giftData.proteinBarCount, AppTheme.primaryOrange),
      const SizedBox(width: 4),
      _buildGiftBadge(Icons.coffee, giftData.proteinPowderCount, AppTheme.primaryOrange),
    ],
  );
}

  Widget _buildGiftBadge(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}