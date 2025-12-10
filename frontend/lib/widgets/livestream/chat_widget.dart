import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import 'gift_sending_widget.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'chat_reminder_message_widget.dart';
import '../../services/chat_reminder_service.dart';
import '../../models/follow_notification_model.dart';
import '../chat_gift_prompt_widget.dart'; // ✅ NEW IMPORT
import 'package:frontend/app_theme.dart';

class ChatWidget extends ConsumerStatefulWidget {
  final String livestreamId;
  final bool isMobile;
  final bool showGiftButton;

  const ChatWidget({
    super.key,
    required this.livestreamId,
    this.isMobile = false,
    this.showGiftButton = false,
  });

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int? _previousItemCount;

  // ✅ NEW: Track if we're waiting for gift prompt response
  bool _isWaitingForGiftPrompt = false;

  @override
  Widget build(BuildContext context) {
    // ✅ Listen for periodic prompt trigger (every 15 minutes)
    ref.listen<bool>(
      shouldShowGiftPromptProvider(widget.livestreamId),
      (previous, next) {
        if (next && !_isWaitingForGiftPrompt) {
          print('🎯 Periodic timer (15 min) triggered - showing gift prompt');

          final message = _messageController.text.trim();
          if (message.isNotEmpty) {
            setState(() => _isWaitingForGiftPrompt = true);
            _focusNode.unfocus();
            _showGiftPromptDialog(message);
          }

          // Reset the trigger
          ref
              .read(shouldShowGiftPromptProvider(widget.livestreamId).notifier)
              .state = false;
        }
      },
    );

    final chatMessages = ref.watch(chatMessagesProvider(widget.livestreamId));
    final reminders = ref.watch(chatRemindersProvider(widget.livestreamId));
    final followNotifications =
        ref.watch(followNotificationsProvider(widget.livestreamId)).value ?? [];

    print(
        'DEBUG: ChatWidget - ${chatMessages.length} chat messages, ${reminders.length} reminders, ${followNotifications.length} follow notifications');

    // Interleave messages, reminders, AND follow notifications by timestamp
    final allItems = <dynamic>[];

    int messageIndex = 0;
    int reminderIndex = 0;
    int followIndex = 0;

    while (messageIndex < chatMessages.length ||
        reminderIndex < reminders.length ||
        followIndex < followNotifications.length) {
      DateTime? messageTime = messageIndex < chatMessages.length
          ? chatMessages[messageIndex].timestamp
          : null;
      DateTime? reminderTime = reminderIndex < reminders.length
          ? reminders[reminderIndex].createdAt
          : null;
      DateTime? followTime = followIndex < followNotifications.length
          ? followNotifications[followIndex].timestamp
          : null;

      DateTime? earliestTime;
      String? earliestType;

      if (messageTime != null) {
        earliestTime = messageTime;
        earliestType = 'message';
      }

      if (reminderTime != null &&
          (earliestTime == null || reminderTime.isBefore(earliestTime))) {
        earliestTime = reminderTime;
        earliestType = 'reminder';
      }

      if (followTime != null &&
          (earliestTime == null || followTime.isBefore(earliestTime))) {
        earliestTime = followTime;
        earliestType = 'follow';
      }

      if (earliestType == 'message') {
        allItems.add(chatMessages[messageIndex]);
        messageIndex++;
      } else if (earliestType == 'reminder') {
        allItems.add(reminders[reminderIndex]);
        reminderIndex++;
      } else if (earliestType == 'follow') {
        allItems.add(followNotifications[followIndex]);
        followIndex++;
      }
    }

    // Auto-scroll to bottom on new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && chatMessages.isNotEmpty) {
        final previousLength = _previousItemCount ?? 0;
        final currentLength = allItems.length;

        if (currentLength > previousLength && previousLength > 0) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }

        _previousItemCount = currentLength;
      }
    });

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasEnoughSpace = constraints.maxHeight > 100;

          return Column(
            children: [
              // Header
              if (!widget.isMobile)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat, color: AppTheme.primaryOrange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Live Questions',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: hasEnoughSpace
                    ? allItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final item = allItems[index];

                              if (item is ChatReminderMessage) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ChatReminderTile(
                                    reminderData: item,
                                    livestreamId: widget.livestreamId,
                                  ),
                                );
                              } else if (item is FollowNotification) {
                                return _buildFollowNotificationTile(item);
                              } else if (item is ChatMessage) {
                                return _buildMessageTile(item);
                              }

                              return const SizedBox.shrink();
                            },
                          )
                    : const SizedBox.shrink(),
              ),

              // Input field
              if (hasEnoughSpace)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppTheme.primaryOrange.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 8),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            textInputAction: TextInputAction.send,
                            enabled:
                                !_isWaitingForGiftPrompt, // ✅ Disable while waiting
                          ),
                        ),
                        if (widget.showGiftButton)
                          GestureDetector(
                            onTap: _showGiftDialog,
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryOrange,
                              ),
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.send,
                              color: AppTheme.primaryOrange),
                          onPressed:
                              _isWaitingForGiftPrompt ? null : _sendMessage,
                          padding: const EdgeInsets.all(8),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageTile(ChatMessage message) {
    final user = ref.read(authProvider).user; // ✅ ADD THIS LINE
    final isCurrentUser =
        user?.id.toString() == message.senderId; // ✅ ADD THIS LINE

    Color? backgroundColor;
    Color nameColor = Colors.white70;

    if (message.isTrainer) {
      nameColor = const Color(0xFFFF4D00);
    }

    if (message.isGiftSender) {
      backgroundColor = AppTheme.primaryOrange.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                message.isTrainer ? AppTheme.primaryOrange : Colors.grey[700],
            child: Text(
              message.senderName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${message.senderName} ',
                    style: TextStyle(
                      color: nameColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  TextSpan(
                    text: message.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ✅ FIXED: Only show gift badge to current user
          if (message.isGiftSender &&
              isCurrentUser) // ✅ ADD isCurrentUser check
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard, size: 10, color: Colors.white),
                  SizedBox(width: 2),
                  Text(
                    'Gift',
                    style: TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowNotificationTile(FollowNotification notification) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2B5FFF).withOpacity(0.15),
            const Color(0xFFFF4D00).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2B5FFF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2B5FFF).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add,
              color: Color(0xFF2B5FFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: notification.followerName,
                    style: const TextStyle(
                      color: Color(0xFF2B5FFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const TextSpan(
                    text: ' started following!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.favorite,
            color: AppTheme.primaryOrange,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isWaitingForGiftPrompt) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final giftPromptService =
        ref.read(chatGiftPromptServiceProvider(widget.livestreamId));

    // ✅ Track message and check if prompt should show NOW
    final shouldShowPrompt = giftPromptService?.trackMessage() ?? false;

    if (shouldShowPrompt) {
      print('🎯 Initial threshold (3 messages) met - showing gift prompt');

      setState(() => _isWaitingForGiftPrompt = true);
      _focusNode.unfocus();

      _showGiftPromptDialog(message);
    } else {
      // Send message normally
      _sendMessageDirectly(message, null);
    }
  }

  // ✅ Show the gift prompt dialog
  void _showGiftPromptDialog(String pendingMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChatGiftPromptWidget(
        livestreamId: widget.livestreamId,
        pendingMessage: pendingMessage,
        onComplete: (giftType) {
          // User completed the prompt (with or without gift)
          setState(() => _isWaitingForGiftPrompt = false);

          final giftPromptService =
              ref.read(chatGiftPromptServiceProvider(widget.livestreamId));

          if (giftType != null) {
            // ✅ User sent gift - track it
            giftPromptService?.trackGift();
          } else {
            // ✅ User dismissed without gift - reset counter
            giftPromptService?.dismissPrompt();
          }

          // Send the message
          _sendMessageDirectly(pendingMessage, giftType);
        },
      ),
    );
  }

  // ✅ Actually send the message to Firestore
  Future<void> _sendMessageDirectly(String message, String? giftType) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      final isGiftSender = giftType != null;

      await FirebaseFirestore.instance
          .collection('livestreams')
          .doc(widget.livestreamId)
          .collection('messages')
          .add({
        'senderId': user.id.toString(),
        'senderName': user.displayName ?? user.username,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isTrainer': user.role == 'Trainer',
        'isGiftSender': isGiftSender,
      });

      _messageController.clear();

      // ✅ DON'T track for gift prompt if we just showed the modal
      // Tracking already happened before modal was shown

      // ✅ Track for in-chat reminder system (they're separate)
      final reminderService =
          ref.read(chatReminderServiceProvider(widget.livestreamId));
      reminderService?.trackMessage();

      print('✅ Message sent successfully${isGiftSender ? " with gift" : ""}');
    } catch (e) {
      print('Error sending message: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGiftDialog() {
    final reminderService =
        ref.read(chatReminderServiceProvider(widget.livestreamId));
    final user = ref.read(authProvider).user;

    showDialog(
      context: context,
      builder: (context) => GiftSendingWidget(
        livestreamId: widget.livestreamId,
        onGiftSent: (giftType) {
          if (user != null) {
            reminderService?.trackGift(giftType, user.id.toString());

            // ✅ Also track for gift prompt service
            final giftPromptService =
                ref.read(chatGiftPromptServiceProvider(widget.livestreamId));
            giftPromptService?.trackGift();
          }
        },
      ),
    );
  }
}
