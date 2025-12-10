import 'package:flutter/material.dart';
import '../models/friend_user_model.dart';

class FriendUserCard extends StatelessWidget {
  final FriendUser user;
  final bool isFollowing;
  final VoidCallback onActionPressed;

  const FriendUserCard({
    super.key,
    required this.user,
    required this.isFollowing,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          print('Navigate to ${user.username}\'s profile');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 28,
                backgroundImage: user.imageUrl != null
                    ? NetworkImage(user.imageUrl!)
                    : null,
                backgroundColor: Colors.grey[300],
                child: user.imageUrl == null
                    ? Icon(Icons.person, size: 28, color: Colors.grey[600])
                    : null,
              ),
              const SizedBox(width: 12),
              // Name and Username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action Button
              OutlinedButton(
                onPressed: onActionPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B00),
                  side: const BorderSide(color: Color(0xFFFF6B00)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isFollowing ? 'Unfollow' : 'Remove'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}