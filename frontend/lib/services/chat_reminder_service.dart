import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/live_stream_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'dart:developer' as developer;
import 'reminder_eligibility_service.dart';
import '../providers/public_profile_provider.dart';


// Service to manage in-chat reminder messages during live streams
// Shows reminders after 90 seconds, then every 4 minutes
class ChatReminderService {
  final String livestreamId;
  final int trainerId;
  final String trainerUsername;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref ref;
  
  late final ReminderEligibilityService _eligibilityService;
  
  Timer? _reminderTimer;
  DateTime? _streamJoinTime;
  DateTime? _lastReminderTime;
  bool _hasShownFirstReminder = false;

  final Set<ReminderType> _shownReminders = {};

  bool _isDisposed = false;
  
  // Configurable thresholds
  static const int initialPresenceSeconds = 90; // 90 seconds for first reminder
  static const int recurringPresenceSeconds = 240; // 4 minutes for subsequent reminders
  
  // Debug mode control
  static const bool debugMode = true;
  
  ChatReminderService({
    required this.livestreamId,
    required this.trainerId,
    required this.trainerUsername,
    required this.ref,
  }) {
    _logDebug('🎬 ChatReminderService CONSTRUCTOR called', {
      'livestreamId': livestreamId,
      'trainerId': trainerId,
      'trainerUsername': trainerUsername,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _eligibilityService = ReminderEligibilityService(
      ref: ref,
      trainerUsername: trainerUsername,
      trainerId: trainerId,
    );
  }
  
  String _getTrainerUsername() {
    return trainerUsername;
  }

  void initialize() {
    _logDebug('🔧 Initializing ChatReminderService', {
      'livestreamId': livestreamId,
    });
    
    _streamJoinTime = DateTime.now();
    _hasShownFirstReminder = false;
    _startReminderTimer();
    
    _logDebug('✅ ChatReminderService initialized successfully', {
      'streamJoinTime': _streamJoinTime?.toIso8601String(),
      'timerActive': _reminderTimer?.isActive ?? false,
      'initialDelay': '${initialPresenceSeconds}s',
      'recurringDelay': '${recurringPresenceSeconds}s',
    });
  }
  
  void dispose() {
    _logDebug('🗑️ Disposing ChatReminderService', {
      'livestreamId': livestreamId,
      'timerActive': _reminderTimer?.isActive ?? false,
    });
    
    _isDisposed = true;
    _reminderTimer?.cancel();
    
    _logDebug('✅ ChatReminderService disposed', {});
  }

  void trackMessage() {
    _logDebug('💬 Message tracked (no-op for time-based reminders)', {
      'hasShownFirstReminder': _hasShownFirstReminder,
    });
    // In-chat reminders don't care about message count, only time
  }
  
  void trackGift(String giftType, String senderId) {
    _logDebug('🎁 Gift tracked (no-op for time-based reminders)', {
      'giftType': giftType,
      'senderId': senderId,
    });
    // In-chat reminders continue even after gifts
  }
  
  void _startReminderTimer() {
    _logDebug('⏰ Starting reminder timer', {
      'checkInterval': '10 seconds',
      'initialThreshold': '${initialPresenceSeconds}s (90s)',
      'recurringThreshold': '${recurringPresenceSeconds}s (4 min)',
    });
    
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(
      const Duration(seconds: 10), // Check every 10 seconds
      (_) => _checkPresence(),
    );
    
    _logDebug('✅ Reminder timer started', {
      'isActive': _reminderTimer?.isActive ?? false,
    });
  }
  
  void _checkPresence() {
    if (_isDisposed) {
      _logDebug('⚠️ Timer tick but service is disposed, skipping', {});
      return;
    }
    
    if (_streamJoinTime == null) {
      _logDebug('⚠️ Timer tick but _streamJoinTime is null', {});
      return;
    }
    
    final now = DateTime.now();
    
    if (!_hasShownFirstReminder) {
      // Check for first reminder (90 seconds since join)
      final secondsSinceJoin = now.difference(_streamJoinTime!).inSeconds;
      
      _logDebug('⏰ Timer tick - checking for FIRST reminder', {
        'secondsSinceJoin': secondsSinceJoin,
        'threshold': initialPresenceSeconds,
      });
      
      if (secondsSinceJoin >= initialPresenceSeconds) {
        _logDebug('🎯 FIRST REMINDER THRESHOLD MET (90s)', {
          'secondsSinceJoin': secondsSinceJoin,
        });
        _triggerReminder();
        _hasShownFirstReminder = true;
        _lastReminderTime = now;
      } else {
        _logDebug('ℹ️ Waiting for first reminder', {
          'secondsSinceJoin': secondsSinceJoin,
          'needsMoreSeconds': initialPresenceSeconds - secondsSinceJoin,
        });
      }
    } else {
      // Check for recurring reminders (4 minutes since last reminder)
      if (_lastReminderTime == null) {
        _logDebug('⚠️ Has shown first but no lastReminderTime set', {});
        _lastReminderTime = now;
        return;
      }
      
      final secondsSinceLastReminder = now.difference(_lastReminderTime!).inSeconds;
      
      _logDebug('⏰ Timer tick - checking for RECURRING reminder', {
        'secondsSinceLastReminder': secondsSinceLastReminder,
        'threshold': recurringPresenceSeconds,
      });
      
      if (secondsSinceLastReminder >= recurringPresenceSeconds) {
        _logDebug('🎯 RECURRING REMINDER THRESHOLD MET (4 min)', {
          'secondsSinceLastReminder': secondsSinceLastReminder,
        });
        _triggerReminder();
        _lastReminderTime = now;
      } else {
        _logDebug('ℹ️ Waiting for next reminder', {
          'secondsSinceLastReminder': secondsSinceLastReminder,
          'needsMoreSeconds': recurringPresenceSeconds - secondsSinceLastReminder,
        });
      }
    }
  }
  
  void _triggerReminder() {
    _logDebug('🚀 Triggering in-chat reminder', {
      'livestreamId': livestreamId,
      'shownReminders': _shownReminders.map((r) => r.toString()).toList(),
      'isFirstReminder': !_hasShownFirstReminder,
    });
    
    try {
      final reminder = _selectNextReminder();
      
      if (reminder != null) {
        _logDebug('📝 Selected reminder', {
          'type': reminder.type.toString(),
          'message': reminder.message,
        });
        
        _sendReminderToChat(reminder);
      } else {
        _logDebug('⚠️ No reminder selected (null returned)', {});
      }
    } catch (e, stackTrace) {
      _logError('❌ Error in _triggerReminder', e, stackTrace);
    }
  }
  
  ChatReminderMessage? _selectNextReminder() {
    _logDebug('🎲 Selecting next reminder', {
      'shownReminders': _shownReminders.map((r) => r.toString()).toList(),
    });
    
    final eligibleTypes = _eligibilityService.getEligibleReminderTypes();
    
    _logDebug('✅ Eligible reminder types', {
      'types': eligibleTypes.map((t) => t.toString()).toList(),
    });
    
    // Find the first eligible type that hasn't been shown yet
    for (final type in eligibleTypes) {
      if (!_shownReminders.contains(type)) {
        _shownReminders.add(type);
        return _createReminderMessage(type);
      }
    }
    
    // All eligible reminders shown - reset and start over
    _logDebug('🔄 All eligible reminders shown, resetting cycle', {});
    _shownReminders.clear();
    
    if (eligibleTypes.isNotEmpty) {
      final type = eligibleTypes.first;
      _shownReminders.add(type);
      return _createReminderMessage(type);
    }
    
    _logDebug('⚠️ No eligible reminders available', {});
    return null;
  }
  
  ChatReminderMessage _createReminderMessage(ReminderType type) {
    switch (type) {
      case ReminderType.follow:
  return ChatReminderMessage(
    type: ReminderType.follow,
    trainerId: trainerId,
    trainerName: _getTrainerName(),
    trainerUsername: trainerUsername,
    message: "Don't miss out! Follow ${_getTrainerName()} to get notified of future streams 🔔",
    actionText: "Follow",
    onAction: () => _handleFollowAction(),
    createdAt: DateTime.now(),
    isAlreadyFollowing: _isUserFollowingTrainer,  // ✅ Add this
  );
      
      case ReminderType.gift:
        return ChatReminderMessage(
          type: ReminderType.gift,
          trainerId: trainerId,
          trainerName: _getTrainerName(),
          trainerUsername: trainerUsername,
          message: "Show your support! Send a Protein Bar to ${_getTrainerName()} 💪",
          actionText: "Send Gift",
          onAction: () => _handleGiftAction(),
          createdAt: DateTime.now(),
        );
      
      case ReminderType.payment:
        return ChatReminderMessage(
          type: ReminderType.payment,
          trainerId: trainerId,
          trainerName: _getTrainerName(),
          trainerUsername: trainerUsername,
          message: "Get Rubies to send more gifts and unlock special features! 💎",
          actionText: "Get Rubies",
          onAction: () => _handlePaymentAction(),
          createdAt: DateTime.now(),
        );
    }
  }
  
  void _sendReminderToChat(ChatReminderMessage reminder) {
    _logDebug('📤 Sending reminder to chat', {
      'type': reminder.type.toString(),
      'livestreamId': livestreamId,
    });
    
    try {
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) {
        _logDebug('⚠️ Cannot show reminder - user is null', {});
        return;
      }
      
      if (currentUser.id == trainerId) {
        _logDebug('⚠️ Skipping reminder - current user is the trainer', {
          'userId': currentUser.id,
          'trainerId': trainerId,
        });
        return;
      }
      
// ✅ Skip follow reminders if user is already following
if (reminder.type == ReminderType.follow) {
  final isFollowing = _isUserFollowingTrainer();
  if (isFollowing) {
    _logDebug('⏭️ Skipping follow reminder - user already following', {
      'trainerId': trainerId,
      'trainerUsername': trainerUsername,
    });
    return;
  }
}



      final remindersNotifier = ref.read(chatRemindersProvider(livestreamId).notifier);
      
      _logDebug('📤 Adding reminder to provider', {
        'currentStateLength': remindersNotifier.state.length,
      });
      
      remindersNotifier.addReminder(reminder);
      
      _logDebug('✅ Reminder added to provider', {
        'newStateLength': remindersNotifier.state.length,
      });
      
      _logReminderEvent(reminder, 'shown');
      
    } catch (e, stackTrace) {
      _logError('❌ Error sending reminder to chat', e, stackTrace);
    }
  }
  
  Future<void> _logReminderEvent(ChatReminderMessage reminder, String action) async {
    _logDebug('📊 Logging reminder event', {
      'type': reminder.type.toString(),
      'action': action,
    });
    
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) {
        _logDebug('⚠️ Cannot log event - user ID is null', {});
        return;
      }
      
      await _firestore
        .collection('livestream_reminders')
        .doc(livestreamId)
        .collection('events')
        .add({
          'userId': userId,
          'trainerId': trainerId,
          'reminderType': reminder.type.toString().split('.').last,
          'action': action,
          'timestamp': FieldValue.serverTimestamp(),
          'triggeredBy': _hasShownFirstReminder ? 'recurring_timer' : 'initial_timer',
        });
      
      _logDebug('✅ Logged reminder event to Firestore', {
        'type': reminder.type.toString(),
        'action': action,
      });
      
    } catch (e, stackTrace) {
      _logError('❌ Failed to log reminder event', e, stackTrace);
    }
  }
  

bool _isUserFollowingTrainer() {
  try {
    final profileAsync = ref.read(userProfileProvider(trainerUsername));
    
    return profileAsync.when(
      data: (profile) {
        final isFollowing = profile.viewerContext.viewerIsFollowing;
        _logDebug('✅ Follow status check', {
          'isFollowing': isFollowing,
          'trainerUsername': trainerUsername,
        });
        return isFollowing;
      },
      loading: () {
        _logDebug('⏳ Profile still loading, assuming not following', {});
        return false;
      },
      error: (e, stack) {
        _logDebug('⚠️ Error checking follow status', {'error': e.toString()});
        return false;
      },
    );
  } catch (e) {
    _logDebug('⚠️ Exception checking follow status', {'error': e.toString()});
    return false;
  }
}



  String _getTrainerName() {
    try {
      final streamState = ref.read(liveStreamProvider(livestreamId));
      final name = streamState.livestream?.trainer?.displayName ?? 
                   streamState.livestream?.trainer?.username ?? 
                   "Trainer";
      
      _logDebug('👤 Retrieved trainer name', {'name': name});
      return name;
    } catch (e) {
      _logDebug('⚠️ Failed to get trainer name, using default', {'error': e.toString()});
      return "Trainer";
    }
  }
  
  void _handleFollowAction() {
    _logDebug('💙 Follow action triggered', {
      'trainerId': trainerId,
      'trainerUsername': trainerUsername,
    });
  }
  
  void _handleGiftAction() {
    _logDebug('🎁 Gift action triggered', {
      'trainerId': trainerId,
    });
  }
  
  void _handlePaymentAction() {
    _logDebug('💳 Payment action triggered', {});
  }
  
  void _logDebug(String message, Map<String, dynamic> data) {
    if (!debugMode) return;

    final logMessage = '$message ${data.isNotEmpty ? data.toString() : ''}';
    developer.log(
      logMessage,
      name: 'ChatReminderService',
      time: DateTime.now(),
    );
    
    print('🔍 [ChatReminderService] $logMessage');
  }

  void _logError(String message, dynamic error, StackTrace? stackTrace) {
    final logMessage = '$message: $error';
    developer.log(
      logMessage,
      name: 'ChatReminderService',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
      level: 1000,
    );
    
    print('❌ [ChatReminderService ERROR] $logMessage');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}

enum ReminderType {
  follow,
  gift,
  payment,
}

class ChatReminderMessage {
  final ReminderType type;
  final int trainerId;
  final String trainerName;
  final String trainerUsername;
  final String message;
  final String actionText;
  final VoidCallback onAction;
  final DateTime createdAt;
  final bool Function()? isAlreadyFollowing;  // ✅ Add this
  
  ChatReminderMessage({
    required this.type,
    required this.trainerId,
    required this.trainerName,
    required this.trainerUsername,
    required this.message,
    required this.actionText,
    required this.onAction,
    required this.createdAt,
    this.isAlreadyFollowing,  // ✅ Add this
  });
  
  @override
  String toString() {
    return 'ChatReminderMessage(type: $type, trainerId: $trainerId, trainerName: $trainerName)';
  }
}