import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== GIFTS ====================
  
  /// Send a gift during a livestream
 /// Send a gift during a livestream
Future<void> sendGift({
  required String livestreamId,
  required String senderId,
  required String senderName,
  required String giftType,
  required double amount,
  required int quantity,
}) async {
  // ✅ Write to gifts collection (for analytics/counting)
  await _firestore.collection('gifts').add({
    'livestreamId': livestreamId,
    'senderId': senderId,
    'senderName': senderName,
    'giftType': giftType,
    'amount': amount,
    'quantity': quantity,
    'timestamp': Timestamp.now(),
  });
  
  // ✅ FIXED: Write chat message with actual sender name
  final giftMessage = _formatGiftMessage(giftType, quantity);
  await _firestore
      .collection('livestreams')
      .doc(livestreamId)
      .collection('messages')
      .add({
        'senderId': senderId,  // ✅ FIXED: Use actual sender ID
        'senderName': senderName,  // ✅ FIXED: Use actual sender name
        'message': giftMessage,
        'isTrainer': false,
        'isGiftSender': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
  
  print('🎁 Gift written to gifts collection');
  print('💬 Gift message written to chat: $giftMessage');
}






/// Format gift message for chat display
String _formatGiftMessage(String giftType, int quantity) {
  switch (giftType) {
    case 'RUBY':
      return 'sent $quantity ${quantity > 1 ? "rubies" : "ruby"} 💎';
    case 'PROTEIN':
      return 'sent $quantity ${quantity > 1 ? "proteins" : "protein"} 💪';
    case 'PROTEIN_SHAKE':
      return 'sent $quantity protein ${quantity > 1 ? "shakes" : "shake"} 🥤';
    case 'PROTEIN_BAR':
      return 'sent $quantity protein ${quantity > 1 ? "bars" : "bar"} 🍫';
    default:
      return 'sent a gift 🎁';
  }
}


  /// Listen to gifts for a specific livestream
  Stream<List<Map<String, dynamic>>> watchGifts(String livestreamId) {
    return _firestore
        .collection('gifts')
        .where('livestreamId', isEqualTo: livestreamId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // ==================== JOIN REQUESTS ====================
  
  /// Send a join request from learner to trainer
  Future<void> sendJoinRequest({
    required String livestreamId,
    required String learnerId,
    required String learnerName,
    String? profilePicture,
  }) async {
    await _firestore.collection('joinRequests').add({
      'livestreamId': livestreamId,
      'learnerId': learnerId,
      'learnerName': learnerName,
      'profilePicture': profilePicture,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Listen to join requests for a specific livestream
  Stream<List<Map<String, dynamic>>> watchJoinRequests(String livestreamId) {
    return _firestore
        .collection('joinRequests')
        .where('livestreamId', isEqualTo: livestreamId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Approve a join request
  Future<void> approveJoinRequest(String requestId) async {
    await _firestore.collection('joinRequests').doc(requestId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Decline a join request
  Future<void> declineJoinRequest(String requestId) async {
    await _firestore.collection('joinRequests').doc(requestId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }




// ==================== FOLLOW NOTIFICATIONS ====================

/// Record a follow action during a livestream (shows in chat)
Future<void> recordFollowInLivestream({
  required String livestreamId,
  required String followerId,
  required String followerName,
  required String trainerId,
}) async {
  // Write to follow_notifications subcollection under the livestream
  await _firestore
      .collection('livestreams')
      .doc(livestreamId)
      .collection('follow_notifications')
      .add({
    'followerId': followerId,
    'followerName': followerName,
    'trainerId': trainerId,
    'timestamp': FieldValue.serverTimestamp(),
  });
  
  print('👥 Follow notification written to livestreams/$livestreamId/follow_notifications');
}

/// Listen to follow notifications for a specific livestream
Stream<List<Map<String, dynamic>>> watchFollowNotifications(String livestreamId) {
  return _firestore
      .collection('livestreams')
      .doc(livestreamId)
      .collection('follow_notifications')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList());
}



  // ==================== CHAT MESSAGES ====================

  /// Send a chat message
  /// Send a chat message
Future<void> sendChatMessage({
  required String livestreamId,
  required String senderId,
  required String senderName,
  required String message,
  required bool isTrainer,
  bool isGiftSender = false,
}) async {
  // ✅ FIXED: Write to the SAME path that watchChatMessages reads from
  await _firestore
      .collection('livestreams')
      .doc(livestreamId)
      .collection('messages')  // ← Must match watchChatMessages
      .add({
    'senderId': senderId,
    'senderName': senderName,
    'message': message,
    'isTrainer': isTrainer,
    'isGiftSender': isGiftSender,
    'timestamp': FieldValue.serverTimestamp(),
  });
  
  print('💬 Chat message written to livestreams/$livestreamId/messages');
}

  /// Listen to chat messages for a specific livestream
  Stream<List<Map<String, dynamic>>> watchChatMessages(String livestreamId) {
  print('DEBUG: Watching messages at path: livestreams/$livestreamId/messages'); // ADD THIS

  return _firestore
      .collection('livestreams')
      .doc(livestreamId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
        print('DEBUG: Snapshot received with ${snapshot.docs.length} documents'); // ADD THIS
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          print('DEBUG: Message data: $data'); // ADD THIS
          return data;
        }).toList();
      });
}



Stream<List<Map<String, dynamic>>> watchLivestreamInvitesForUser(String userId) {
  print('👀 Watching livestream invites for user: $userId');
  
  return _firestore
      .collection('livestreamInvites')
      .where('recipientId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        print('📨 Received ${snapshot.docs.length} pending invites');
        
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
}

Future<void> acceptLivestreamInvite(String inviteId) async {
  try {
    await _firestore
        .collection('livestreamInvites')
        .doc(inviteId)
        .update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Livestream invite accepted: $inviteId');
  } catch (e) {
    print('❌ Error accepting livestream invite: $e');
    rethrow;
  }
}

Future<void> declineLivestreamInvite(String inviteId) async {
  try {
    await _firestore
        .collection('livestreamInvites')
        .doc(inviteId)
        .update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Livestream invite declined: $inviteId');
  } catch (e) {
    print('❌ Error declining livestream invite: $e');
    rethrow;
  }
}







}