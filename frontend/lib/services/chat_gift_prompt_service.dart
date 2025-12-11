import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

/// Service to manage the chat gift prompt feature
class ChatGiftPromptService {
  final String livestreamId;
  final String userId;
  final WidgetRef ref;
  
  Timer? _periodicTimer;
  int _messageCount = 0;
  bool _hasShownInitialPrompt = false;
  bool _hasSentGift = false;
  bool _isDisposed = false;
  DateTime? _lastPromptShown;
  
  static const int initialMessageThreshold = 3;
  static const int periodicIntervalMinutes = 15;
  static const bool debugMode = true;
  
  // ✅ Callback to trigger prompt in UI (called by periodic timer)
  final VoidCallback? shouldShowPrompt;
  
  ChatGiftPromptService({
    required this.livestreamId,
    required this.userId,
    required this.ref,
    this.shouldShowPrompt,
  }) {
    _logDebug('🎬 ChatGiftPromptService CONSTRUCTOR called', {
      'livestreamId': livestreamId,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  void initialize() {
    _logDebug('🔧 Initializing ChatGiftPromptService', {
      'livestreamId': livestreamId,
      'userId': userId,
    });
    
    _messageCount = 0;
    _hasShownInitialPrompt = false;
    _hasSentGift = false;
    _lastPromptShown = null;
    
    _logDebug('✅ ChatGiftPromptService initialized successfully', {
      'messageCount': _messageCount,
      'hasShownInitialPrompt': _hasShownInitialPrompt,
      'hasSentGift': _hasSentGift,
    });
  }
  
  void dispose() {
    _logDebug('🗑️ Disposing ChatGiftPromptService', {
      'livestreamId': livestreamId,
      'timerActive': _periodicTimer?.isActive ?? false,
    });
    
    _isDisposed = true;
    _periodicTimer?.cancel();
    
    _logDebug('✅ ChatGiftPromptService disposed', {});
  }
  
  /// Call this every time the user sends a message
  /// Returns TRUE if the prompt should be shown NOW
  bool trackMessage() {
    if (_isDisposed || _hasSentGift) {
      _logDebug('⏭️ Skipping message tracking', {
        'isDisposed': _isDisposed,
        'hasSentGift': _hasSentGift,
      });
      return false;
    }
    
    _messageCount++;
    
    _logDebug('💬 Message tracked', {
      'messageCount': _messageCount,
      'hasShownInitialPrompt': _hasShownInitialPrompt,
      'threshold': initialMessageThreshold,
    });
    
    // ✅ ONLY show initial prompt on 3rd message, NOT every 3 messages
    if (!_hasShownInitialPrompt && _messageCount >= initialMessageThreshold) {
      _logDebug('🎯 INITIAL THRESHOLD MET - Should show prompt', {
        'messageCount': _messageCount,
        'threshold': initialMessageThreshold,
      });
      
      _hasShownInitialPrompt = true;
      _lastPromptShown = DateTime.now();
      _startPeriodicTimer();
      
      return true; // ✅ Tell caller to show prompt
    }
    
    // After initial prompt, periodic timer handles subsequent prompts
    return false;
  }
  
  /// Call this when user sends a gift
  void trackGift() {
    _logDebug('🎁 Gift tracked - disabling further prompts', {
      'messageCount': _messageCount,
      'hadShownInitialPrompt': _hasShownInitialPrompt,
    });
    
    _hasSentGift = true;
    _periodicTimer?.cancel();
    
    _logDebug('✅ Gift prompt disabled for this session', {});
  }
  
  /// Call this when user dismisses the prompt without sending a gift
  void dismissPrompt() {
    _logDebug('🚫 Prompt dismissed without gift', {
      'messageCount': _messageCount,
    });
    
    // Reset message counter for next periodic interval
    _messageCount = 0;
    
    _logDebug('✅ Message counter reset after dismissal', {
      'newMessageCount': _messageCount,
    });
  }
  
  /// Reset on rejoin (called when user leaves and rejoins stream)
  void reset() {
    _logDebug('🔄 Resetting ChatGiftPromptService', {
      'oldMessageCount': _messageCount,
      'oldHasShownInitialPrompt': _hasShownInitialPrompt,
      'oldHasSentGift': _hasSentGift,
    });
    
    _periodicTimer?.cancel();
    _messageCount = 0;
    _hasShownInitialPrompt = false;
    _hasSentGift = false;
    _lastPromptShown = null;
    
    _logDebug('✅ ChatGiftPromptService reset', {
      'newMessageCount': _messageCount,
    });
  }
  
  void _startPeriodicTimer() {
    if (_hasSentGift || _isDisposed) {
      _logDebug('⏭️ Not starting periodic timer', {
        'hasSentGift': _hasSentGift,
        'isDisposed': _isDisposed,
      });
      return;
    }
    
    _logDebug('⏰ Starting periodic timer', {
      'intervalMinutes': periodicIntervalMinutes,
    });
    
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      Duration(minutes: periodicIntervalMinutes),
      (_) => _checkPeriodicPrompt(),
    );
    
    _logDebug('✅ Periodic timer started', {
      'isActive': _periodicTimer?.isActive ?? false,
    });
  }
  
  void _checkPeriodicPrompt() {
    if (_isDisposed || _hasSentGift) {
      _logDebug('⏭️ Skipping periodic prompt check', {
        'isDisposed': _isDisposed,
        'hasSentGift': _hasSentGift,
      });
      return;
    }
    
    _logDebug('⏰ Periodic timer tick - checking if should show prompt', {
      'messageCount': _messageCount,
      'lastPromptShown': _lastPromptShown?.toIso8601String(),
    });
    
    // Only show if user has sent messages since last prompt
    if (_messageCount > 0) {
      _logDebug('🎯 PERIODIC CONDITION MET - Calling callback', {
        'messageCount': _messageCount,
      });
      
      _lastPromptShown = DateTime.now();
      _messageCount = 0; // Reset counter for next interval
      
      // ✅ Call callback to trigger prompt in UI
      shouldShowPrompt?.call();
    } else {
      _logDebug('ℹ️ No messages since last prompt, skipping', {});
    }
  }
  
  // Getters for state inspection
  bool get hasShownInitialPrompt => _hasShownInitialPrompt;
  bool get hasSentGift => _hasSentGift;
  int get messageCount => _messageCount;
  
  void _logDebug(String message, Map<String, dynamic> data) {
    if (!debugMode) return;

    final logMessage = '$message ${data.isNotEmpty ? data.toString() : ''}';
    developer.log(
      logMessage,
      name: 'ChatGiftPromptService',
      time: DateTime.now(),
    );
    
    print('🔍 [ChatGiftPromptService] $logMessage');
  }
}