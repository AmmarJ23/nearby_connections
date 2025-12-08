class ConnectionStatusModel {
  final String currentUserName;
  final String currentStatus;
  final List<ConnectedUser> connectedUsers;
  final DateTime lastUpdateTime;
  final int totalConnections;

  const ConnectionStatusModel({
    required this.currentUserName,
    required this.currentStatus,
    required this.connectedUsers,
    required this.lastUpdateTime,
    this.totalConnections = 0,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'currentUserName': currentUserName,
      'currentStatus': currentStatus,
      'connectedUsersCount': connectedUsers.length,
      'connectedUsers': connectedUsers.map((user) => user.toMap()).toList(),
      'lastUpdateTime': lastUpdateTime.millisecondsSinceEpoch,
      'totalConnections': totalConnections,
      // Individual user names for easier access in widget
      'user1Name': connectedUsers.isNotEmpty ? connectedUsers[0].name : '',
      'user1Status': connectedUsers.isNotEmpty ? connectedUsers[0].status : '',
      'user2Name': connectedUsers.length > 1 ? connectedUsers[1].name : '',
      'user2Status': connectedUsers.length > 1 ? connectedUsers[1].status : '',
      'user3Name': connectedUsers.length > 2 ? connectedUsers[2].name : '',
      'user3Status': connectedUsers.length > 2 ? connectedUsers[2].status : '',
    };

    return map;
  }

  ConnectionStatusModel copyWith({
    String? currentUserName,
    String? currentStatus,
    List<ConnectedUser>? connectedUsers,
    DateTime? lastUpdateTime,
    int? totalConnections,
  }) {
    return ConnectionStatusModel(
      currentUserName: currentUserName ?? this.currentUserName,
      currentStatus: currentStatus ?? this.currentStatus,
      connectedUsers: connectedUsers ?? this.connectedUsers,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      totalConnections: totalConnections ?? this.totalConnections,
    );
  }
}

class ConnectedUser {
  final String id;
  final String name;
  final String status;
  final DateTime connectedTime;

  const ConnectedUser({
    required this.id,
    required this.name,
    required this.status,
    required this.connectedTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'connectedTime': connectedTime.millisecondsSinceEpoch,
    };
  }

  ConnectedUser copyWith({
    String? id,
    String? name,
    String? status,
    DateTime? connectedTime,
  }) {
    return ConnectedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      connectedTime: connectedTime ?? this.connectedTime,
    );
  }
}
