class ConnectionStatusLiveActivityModel {
  final String selfName;
  final String selfActivity;
  final int connectedCount;
  final List<ConnectedUser> connectedUsers;

  const ConnectionStatusLiveActivityModel({
    required this.selfName,
    required this.selfActivity,
    this.connectedCount = 0,
    this.connectedUsers = const [],
  });

  Map<String, dynamic> toMap() {
    final map = {
      'selfName': selfName,
      'selfActivity': selfActivity,
      'connectedCount': connectedCount,
      'users': connectedUsers.map((user) => user.toMap()).toList(),
    };

    return map;
  }

  ConnectionStatusLiveActivityModel copyWith({
    String? selfName,
    String? selfActivity,
    int? connectedCount,
    List<ConnectedUser>? connectedUsers,
  }) {
    return ConnectionStatusLiveActivityModel(
      selfName: selfName ?? this.selfName,
      selfActivity: selfActivity ?? this.selfActivity,
      connectedCount: connectedCount ?? this.connectedCount,
      connectedUsers: connectedUsers ?? this.connectedUsers,
    );
  }
}

class ConnectedUser {
  final String name;
  final String activity;

  const ConnectedUser({
    required this.name,
    required this.activity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'activity': activity,
    };
  }
}
