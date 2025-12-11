import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import '../../app_theme.dart';

class WaitlistWidget extends ConsumerWidget {
  final String livestreamId;
  final bool isDialog;
  
  const WaitlistWidget({
    Key? key,
    required this.livestreamId,
    this.isDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitlist = ref.watch(waitlistProvider(livestreamId));    
    if (waitlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.white38, size: isDialog ? 48 : 32),
            const SizedBox(height: 8),
            const Text(
              'No learners waiting',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDialog)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Live Waitlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${waitlist.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {}, // Show more
                  child: const Text(
                    'Show more',
                    style: TextStyle(color: AppTheme.primaryOrange),
                  ),
                ),
              ],
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: waitlist.length,
            itemBuilder: (context, index) {
              final entry = waitlist[index];
              return _buildWaitlistItem(entry, ref);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaitlistItem(WaitlistEntry entry, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryOrange.withOpacity(0.3),
            backgroundImage: entry.profilePicture != null
                ? NetworkImage(entry.profilePicture!)
                : null,
            child: entry.profilePicture == null
                ? Text(
                    entry.userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Waiting to join',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Accept button
          IconButton(
            onPressed: () => ref.read(waitlistProvider(livestreamId).notifier).approveUser(entry.userId),
            icon: const Icon(Icons.check_circle),
            color: Colors.green,
            tooltip: 'Approve',
          ),
          // Decline button
          IconButton(
          onPressed: () => ref.read(waitlistProvider(livestreamId).notifier).declineUser(entry.userId),
            icon: const Icon(Icons.cancel),
            color: Colors.red,
            tooltip: 'Decline',
          ),
        ],
      ),
    );
  }
}