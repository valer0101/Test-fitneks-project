import 'package:cloud_firestore/cloud_firestore.dart';

class FollowNotification {
  final String id;
  final String followerId;
  final String followerName;
  final String trainerId;
  final DateTime timestamp;

  FollowNotification({
    required this.id,
    required this.followerId,
    required this.followerName,
    required this.trainerId,
    required this.timestamp,
  });

  factory FollowNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return FollowNotification(
      id: id,
      followerId: data['followerId'] ?? '',
      followerName: data['followerName'] ?? 'Someone',
      trainerId: data['trainerId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}