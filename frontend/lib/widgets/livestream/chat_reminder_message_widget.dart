import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat_reminder_service.dart';
import '../../providers/profile_provider.dart';
import '../../services/profiles_service.dart';
import 'gift_sending_widget.dart';  
import '../learner_ruby_purchase_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart' as auth;

import 'dart:developer' as developer;
import '../../providers/public_profile_provider.dart';
import '../../app_theme.dart';

// Widget to display chat reminder messages with action buttons
class ChatReminderMessageWidget extends ConsumerStatefulWidget {
  final ChatReminderMessage reminderData;
  final String livestreamId;
  
  const ChatReminderMessageWidget({
    Key? key,
    required this.reminderData,
    required this.livestreamId,
  }) : super(key: key);
  
  @override
  ConsumerState<ChatReminderMessageWidget> createState() => _ChatReminderMessageWidgetState();
}

class _ChatReminderMessageWidgetState extends ConsumerState<ChatReminderMessageWidget> {
  bool _isLoading = false;
  bool _actionCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _logDebug('🎬 ChatReminderMessageWidget initState', {
      'type': widget.reminderData.type.toString(),
      'livestreamId': widget.livestreamId,
    });
  }
  
@override
Widget build(BuildContext context) {
  _logDebug('🎨 Building ChatReminderMessageWidget', {
    'type': widget.reminderData.type.toString(),
    'actionCompleted': _actionCompleted,
    'isLoading': _isLoading,
  });
  
  // ✅ Hide follow reminder if user is already following
  if (widget.reminderData.type == ReminderType.follow && 
      widget.reminderData.isAlreadyFollowing != null) {
    final isFollowing = widget.reminderData.isAlreadyFollowing!();
    if (isFollowing) {
      _logDebug('⏭️ Hiding follow reminder - user already following', {});
      return const SizedBox.shrink();  // Return empty widget
    }
  }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Card(
        elevation: 4,
        color: _getBackgroundColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon and message row
              Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitle(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.reminderData.message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action button
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (widget.reminderData.type) {
      case ReminderType.follow:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
        break;
      case ReminderType.gift:
        iconData = Icons.card_giftcard;
        iconColor = Colors.green;
        break;
      case ReminderType.payment:
        iconData = Icons.diamond;
        iconColor = Colors.red;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
  
  String _getTitle() {
    switch (widget.reminderData.type) {
      case ReminderType.follow:
        return 'Stay Connected!';
      case ReminderType.gift:
        return 'Show Support!';
      case ReminderType.payment:
        return 'Get More Rubies!';
    }
  }
  
  Color _getBackgroundColor() {
    switch (widget.reminderData.type) {
      case ReminderType.follow:
        return const Color(0xFF1E3A5F); // Dark blue
      case ReminderType.gift:
        return const Color(0xFF1B4332); // Dark green
      case ReminderType.payment:
        return const Color(0xFF4A1A1A); // Dark red
    }
  }
  
  Color _getBorderColor() {
    switch (widget.reminderData.type) {
      case ReminderType.follow:
        return Colors.blue.withOpacity(0.5);
      case ReminderType.gift:
        return Colors.green.withOpacity(0.5);
      case ReminderType.payment:
        return Colors.red.withOpacity(0.5);
    }
  }
  
  Widget _buildActionButton() {
    if (_actionCompleted) {
      _logDebug('✅ Showing completed state', {});
      
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'Completed!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getButtonColor(),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getButtonIcon(),
                const SizedBox(width: 8),
                Text(
                  widget.reminderData.actionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
  
  Icon _getButtonIcon() {
    switch (widget.reminderData.type) {
      case ReminderType.follow:
        return const Icon(Icons.person_add, size: 18);
      case ReminderType.gift:
        return const Icon(Icons.card_giftcard, size: 18);
      case ReminderType.payment:
        return const Icon(Icons.diamond, size: 18);
    }
  }
  
  Color _getButtonColor() {
    switch (widget.reminderData.type) {
      case ReminderType.follow:
        return Colors.blue;
      case ReminderType.gift:
        return Colors.green;
      case ReminderType.payment:
        return Colors.red;
    }
  }
  
  Future<void> _handleAction() async {
  _logDebug('🎯 Reminder action clicked', {
    'type': widget.reminderData.type.toString(),
  });
  
  setState(() => _isLoading = true);
  
  try {
    // Log the click event
    await _logReminderAction('clicked');
    
    switch (widget.reminderData.type) {
      case ReminderType.follow:
        await _handleFollowAction();
        // Log completion for follow (happens immediately)
        await _logReminderAction('completed');
        _logDebug('✅ Action completed successfully', {
          'type': widget.reminderData.type.toString(),
        });
        if (mounted) {
          setState(() {
            _actionCompleted = true;
            _isLoading = false;
          });
        }
        break;
        
     case ReminderType.gift:
  // ✅ Open gift dialog - completion handled by callback
  setState(() => _isLoading = false); // Stop loading immediately
  
  if (!mounted) return;
  
  showDialog(
    context: context,
    builder: (context) => GiftSendingWidget(
      livestreamId: widget.livestreamId,
      onGiftSent: (giftType) {  // ✅ NOT async anymore
        _logDebug('✅ Gift sent successfully', {
          'giftType': giftType,
        });
        
        // ✅ Only mark complete when gift is actually sent
        _logReminderAction('completed');  // ✅ NOT awaited
        
        if (mounted) {
          setState(() => _actionCompleted = true);
        }
      },
    ),
  );
  return; // ✅ Exit early - don't mark complete yet
        
      case ReminderType.payment:
        // ✅ Open payment modal - optional completion handling
        setState(() => _isLoading = false); // Stop loading immediately
        
        if (!mounted) return;
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const RubyPurchaseModal(
            defaultPaymentMethodId: '',
          ),
        ).then((purchased) {
          // Optional: mark complete if they purchased
          if (purchased == true && mounted) {
            _logReminderAction('completed');
            setState(() => _actionCompleted = true);
          }
        });
        return; // ✅ Exit early
    }
  } catch (e, stackTrace) {
    _logError('❌ Error handling action', e, stackTrace);
    
    await _logReminderAction('failed');
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _logReminderAction(String action) async {
    _logDebug('📊 Logging reminder action', {
      'action': action,
      'type': widget.reminderData.type.toString(),
    });
    
    try {
      final userId = ref.read(auth.authProvider).user?.id;
      if (userId == null) {
        _logDebug('⚠️ Cannot log action - user ID is null', {});
        return;
      }
      
      await FirebaseFirestore.instance
        .collection('livestream_reminders')
        .doc(widget.livestreamId)
        .collection('events')
        .add({
          'userId': userId,
          'trainerId': widget.reminderData.trainerId,
          'reminderType': widget.reminderData.type.toString().split('.').last,
          'action': action,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
      _logDebug('✅ Action logged to Firestore', {
        'action': action,
      });
    } catch (e) {
      _logDebug('⚠️ Failed to log action (non-critical)', {
        'error': e.toString(),
      });
    }
  }
  
 Future<void> _handleFollowAction() async {
  _logDebug('💙 Handling follow action', {
    'trainerUsername': widget.reminderData.trainerUsername,
  });
  
  setState(() => _isLoading = true);
  
  try {
    final service = ref.read(profilesServiceProvider);
    await service.followUser(widget.reminderData.trainerUsername);
    
    // ✅ Invalidate the profile cache so all follow buttons update
    ref.invalidate(userProfileProvider(widget.reminderData.trainerUsername));
    
    // ✅ NEW: Record follow in livestream chat for notification
    final user = ref.read(auth.authProvider).user;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
          .collection('livestreams')
          .doc(widget.livestreamId)
          .collection('follow_notifications')
          .add({
            'followerId': user.id.toString(),
            'followerName': user.displayName ?? user.username,
            'trainerId': widget.reminderData.trainerId.toString(),
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'follow',
          });
        
        _logDebug('✅ Follow notification recorded in livestream', {
          'livestreamId': widget.livestreamId,
          'followerId': user.id,
        });
      } catch (e) {
        _logDebug('⚠️ Failed to record follow notification (non-critical)', {
          'error': e.toString(),
        });
      }
    }
    
    _logDebug('✅ Follow action successful', {});
    
    if (mounted) {
      setState(() {
        _actionCompleted = true;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Following ${widget.reminderData.trainerUsername}!'),
          backgroundColor: AppTheme.primaryOrange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e, stackTrace) {
    _logError('❌ Follow action failed', e, stackTrace);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  
  Future<String> _getTrainerUsername() async {
    // This should fetch the actual trainer username from the livestream data
    // For now, returning a placeholder
    return 'trainer_username';
  }
  
  void _notifyFollowStateChange(bool isFollowing) {
    // This will notify any other follow buttons in the UI to update their state
    // You can use a provider or event bus for this
  }
  
  void _logDebug(String message, Map<String, dynamic> data) {
    if (!ChatReminderService.debugMode) return;

    final logMessage = '$message ${data.isNotEmpty ? data.toString() : ''}';
    developer.log(
      logMessage,
      name: 'ChatReminderMessageWidget',
      time: DateTime.now(),
    );
    
    print('🔍 [ChatReminderMessageWidget] $logMessage');
  }

  void _logError(String message, dynamic error, StackTrace? stackTrace) {
    final logMessage = '$message: $error';
    developer.log(
      logMessage,
      name: 'ChatReminderMessageWidget',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
      level: 1000,
    );
    
    print('❌ [ChatReminderMessageWidget ERROR] $logMessage');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}

// Simplified version for rendering in chat list
class ChatReminderTile extends StatelessWidget {
  final ChatReminderMessage reminderData;
  final String livestreamId;
  
  const ChatReminderTile({
    Key? key,
    required this.reminderData,
    required this.livestreamId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    print('🔍 [ChatReminderTile] Building tile for type: ${reminderData.type}');
    
    return ChatReminderMessageWidget(
      reminderData: reminderData,
      livestreamId: livestreamId,
    );
  }
}