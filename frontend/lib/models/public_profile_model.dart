class PublicProfileModel {
  final int id;
  final String displayName;
  final String username;
  final String userType;
  final bool isPublic;
  final String? profilePictureUrl;
  final String liveStatus;
  final String? aboutMe;
  final PublicProfileStats stats;
  final ViewerContext viewerContext;
  final List<String>? specialties;
  final List<CalendarEvent>? calendarEvents;
  final List<String>? interests;
  final List<String>? goals;
  final AdvancedMetrics? advancedMetrics;

  PublicProfileModel({
    required this.id,
    required this.displayName,
    required this.username,
    required this.userType,
    required this.isPublic,
    this.profilePictureUrl,
    required this.liveStatus,
    this.aboutMe,
    required this.stats,
    required this.viewerContext,
    this.specialties,
    this.calendarEvents,
    this.interests,
    this.goals,
    this.advancedMetrics,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id'] as int,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      userType: json['userType'] as String,
      isPublic: json['isPublic'] as bool,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      liveStatus: json['liveStatus'] as String,
      aboutMe: json['aboutMe'] as String?,
      stats: PublicProfileStats.fromJson(json['stats']),
      viewerContext: ViewerContext.fromJson(json['viewerContext']),
      specialties: (json['specialties'] as List?)?.cast<String>(),
      calendarEvents: (json['calendarEvents'] as List?)
          ?.map((e) => CalendarEvent.fromJson(e))
          .toList(),
      interests: (json['interests'] as List?)?.cast<String>(),
      goals: (json['goals'] as List?)?.cast<String>(),
      advancedMetrics: json['advancedMetrics'] != null
          ? AdvancedMetrics.fromJson(json['advancedMetrics'])
          : null,
    );
  }
}

class PublicProfileStats {
  final int? lifetimePoints;
  final int? lifetimeXP;
  final int? trainerLevel;
  final int lifetimeSessions;
  final int lifetimeChallenges;

  PublicProfileStats({
    this.lifetimePoints,
    this.lifetimeXP,
    this.trainerLevel,
    required this.lifetimeSessions,
    required this.lifetimeChallenges,
  });

  factory PublicProfileStats.fromJson(Map<String, dynamic> json) {
    return PublicProfileStats(
      lifetimePoints: json['lifetimePoints'] as int?,
      lifetimeXP: json['lifetimeXP'] as int?,
      trainerLevel: json['trainerLevel'] as int?,
      lifetimeSessions: json['lifetimeSessions'] as int,
      lifetimeChallenges: json['lifetimeChallenges'] as int,
    );
  }
}

class ViewerContext {
  final bool viewerIsFollowing;
  final bool profileIsFollowingViewer;

  ViewerContext({
    required this.viewerIsFollowing,
    required this.profileIsFollowingViewer,
  });

  factory ViewerContext.fromJson(Map<String, dynamic> json) {
    return ViewerContext(
      viewerIsFollowing: json['viewerIsFollowing'] as bool,
      profileIsFollowingViewer: json['profileIsFollowingViewer'] as bool,
    );
  }
}

class CalendarEvent {
  final String date;
  final String type;

  CalendarEvent({required this.date, required this.type});

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      date: json['date'] as String,
      type: json['type'] as String,
    );
  }
}

class AdvancedMetrics {
  final Map<String, dynamic> weeklyPointsGraph;
  final Map<String, dynamic> heatmap;

  AdvancedMetrics({
    required this.weeklyPointsGraph,
    required this.heatmap,
  });

  factory AdvancedMetrics.fromJson(Map<String, dynamic> json) {
    return AdvancedMetrics(
      weeklyPointsGraph: json['weeklyPointsGraph'] as Map<String, dynamic>,
      heatmap: json['heatmap'] as Map<String, dynamic>,
    );
  }
}