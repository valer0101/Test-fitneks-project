import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/livestream/gift_sending_widget.dart';

/// Manages timed popup reminders during livestreams
class ReminderManager {
  Timer? _followTimer;
  Timer? _giftTimer;
  
  /// Start both reminder timers
  /// [checkIfFollowing] - callback to check if user is currently following
  /// [onFollowPressed] - callback when user clicks Follow button
  void startReminders(
    BuildContext context, 
    String livestreamId, {
    Future<bool> Function()? checkIfFollowing,
    Future<void> Function()? onFollowPressed,  // ✅ NEW callback
  }) {
    // Schedule follow reminder for 5 minutes from now
    _followTimer = Timer(Duration(minutes: 5), () async {
      if (!context.mounted) return;
      
      // ✅ Check follow status when timer fires
      bool isFollowing = false;
      if (checkIfFollowing != null) {
        try {
          isFollowing = await checkIfFollowing();
        } catch (e) {
          print('⚠️ Error checking follow status: $e');
        }
      }
      
      if (!isFollowing) {
        _showFollowReminder(context, onFollowPressed);  // ✅ Pass callback
      } else {
        print('⏭️ User already following, skipping follow reminder');
      }
    });
    
    // Schedule gift reminder for 10 minutes from now
    _giftTimer = Timer(Duration(minutes: 10), () {
      if (context.mounted) {
        _showGiftReminder(context, livestreamId);
      }
    });
  }
  
  /// Shows a banner encouraging following the trainer
  void _showFollowReminder(BuildContext context, Future<void> Function()? onFollowPressed) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(
          'Enjoying the stream? Follow to get notified of future workouts!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFFF4D00),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              
              // ✅ FIXED: Call the callback provided by the page
              if (onFollowPressed != null) {
                try {
                  await onFollowPressed();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully followed!'),
                        backgroundColor: Color(0xFFFF4D00),
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error following: $e');
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to follow'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('FOLLOW', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    Future.delayed(Duration(seconds: 10), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }
  
  /// Shows a banner encouraging gift sending
  void _showGiftReminder(BuildContext context, String livestreamId) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(
          'Show your appreciation! Send a gift to the trainer.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF2B5FFF),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              
              // ✅ FIXED: Open gift dialog
              showDialog(
                context: context,
                builder: (context) => GiftSendingWidget(
                  livestreamId: livestreamId,
                  onGiftSent: (giftType) {
                    print('🎁 Gift sent from reminder: $giftType');
                  },
                ),
              );
            },
            child: Text('SEND GIFT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    Future.delayed(Duration(seconds: 10), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }
  
  /// Clean up timers when page closes
  void dispose() {
    _followTimer?.cancel();
    _giftTimer?.cancel();
  }
}