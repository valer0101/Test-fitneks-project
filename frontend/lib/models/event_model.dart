import 'package:equatable/equatable.dart';

enum EventType { CLASS, CHALLENGE }
enum EventStatus { UPCOMING, COMPLETED }

class EventModel extends Equatable {
  final String id;
  final int trainerId;
  final EventType type;
  final EventStatus status;
  final String title;
  final DateTime date;
  final int? maxParticipants;
  final double? ticketValue;
  final double? giftsReceived;
  final int? xpEarned;
  final List<String> equipment;
  final String trainingType;
  final Map<String, dynamic>? pointsBreakdown;
  final int duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ✅ NEW: Fields for attended events
  final bool? attended;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final Map<String, int>? pointsEarned;
  final Map<String, dynamic>? trainer;

  const EventModel({
    required this.id,
    required this.trainerId,
    required this.type,
    required this.status,
    required this.title,
    required this.date,
    this.maxParticipants,
    this.ticketValue,
    this.giftsReceived,
    this.xpEarned,
    required this.equipment,
    required this.trainingType,
    this.pointsBreakdown,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
        // ✅ NEW
    this.attended,
    this.joinedAt,
    this.leftAt,
    this.pointsEarned,
    this.trainer,

  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      trainerId: json['trainerId'],
      type: EventType.values.firstWhere(
        (e) => e.toString() == 'EventType.${json['type']}',
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == 'EventStatus.${json['status']}',
      ),
      title: json['title'],
      date: DateTime.parse(json['date']),
      maxParticipants: json['maxParticipants'],
      ticketValue: json['ticketValue']?.toDouble(),
      giftsReceived: json['giftsReceived']?.toDouble(),
      xpEarned: json['xpEarned'],
      equipment: List<String>.from(json['equipment'] ?? []),
      trainingType: json['trainingType'],
      pointsBreakdown: json['pointsBreakdown'],
      duration: json['duration'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    // ✅ NEW
      attended: json['attended'],
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
      pointsEarned: json['pointsEarned'] != null 
          ? Map<String, int>.from(json['pointsEarned'])
          : null,
      trainer: json['trainer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainerId': trainerId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'title': title,
      'date': date.toIso8601String(),
      'maxParticipants': maxParticipants,
      'ticketValue': ticketValue,
      'giftsReceived': giftsReceived,
      'xpEarned': xpEarned,
      'equipment': equipment,
      'trainingType': trainingType,
      'pointsBreakdown': pointsBreakdown,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // ✅ NEW
      if (attended != null) 'attended': attended,
      if (joinedAt != null) 'joinedAt': joinedAt!.toIso8601String(),
      if (leftAt != null) 'leftAt': leftAt!.toIso8601String(),
      if (pointsEarned != null) 'pointsEarned': pointsEarned,
      if (trainer != null) 'trainer': trainer,
    };
  }

  EventModel copyWith({
    String? id,
    int? trainerId,
    EventType? type,
    EventStatus? status,
    String? title,
    DateTime? date,
    int? maxParticipants,
    double? ticketValue,
    double? giftsReceived,
    int? xpEarned,
    List<String>? equipment,
    String? trainingType,
    Map<String, dynamic>? pointsBreakdown,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? attended,
    DateTime? joinedAt,
    DateTime? leftAt,
    Map<String, int>? pointsEarned,
    Map<String, dynamic>? trainer,
  }) {
    return EventModel(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      date: date ?? this.date,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      ticketValue: ticketValue ?? this.ticketValue,
      giftsReceived: giftsReceived ?? this.giftsReceived,
      xpEarned: xpEarned ?? this.xpEarned,
      equipment: equipment ?? this.equipment,
      trainingType: trainingType ?? this.trainingType,
      pointsBreakdown: pointsBreakdown ?? this.pointsBreakdown,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attended: attended ?? this.attended,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      trainer: trainer ?? this.trainer,
    );
  }

  @override
  List<Object?> get props => [
    id, trainerId, type, status, title, date, maxParticipants,
    ticketValue, giftsReceived, xpEarned, equipment, trainingType,
    pointsBreakdown, duration, createdAt, updatedAt,
    attended, joinedAt, leftAt, pointsEarned, trainer,
  ];
}