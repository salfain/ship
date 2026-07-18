enum UserRole {
  nahkoda,
  admin,
  manager,
  unknown;

  String get label {
    switch (this) {
      case UserRole.nahkoda:
        return 'Nakhoda';
      case UserRole.admin:
        return 'Admin KSOP';
      case UserRole.manager:
        return 'Kepala KSOP';
      case UserRole.unknown:
        return 'Pengguna';
    }
  }

  String get homePath {
    switch (this) {
      case UserRole.nahkoda:
        return '/nahkoda';
      case UserRole.admin:
        return '/admin';
      case UserRole.manager:
        return '/manager';
      case UserRole.unknown:
        return '/login';
    }
  }

  static UserRole fromBackend(String? value) {
    switch (value?.toUpperCase()) {
      case 'NAHKODA':
        return UserRole.nahkoda;
      case 'ADMIN':
        return UserRole.admin;
      case 'MANAGER':
      case 'KEPALA_KSOP':
        return UserRole.manager;
      default:
        return UserRole.unknown;
    }
  }
}

class UserSession {
  const UserSession({
    required this.id,
    required this.name,
    required this.role,
    required this.token,
    this.username,
    this.shipId,
    this.shipNumber,
    this.shipName,
  });

  final String id;
  final String name;
  final UserRole role;
  final String token;
  final String? username;
  final String? shipId;
  final String? shipNumber;
  final String? shipName;

  UserSession copyWith({String? name, String? username}) {
    return UserSession(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role,
      token: token,
      shipId: shipId,
      shipNumber: shipNumber,
      shipName: shipName,
    );
  }

  factory UserSession.fromLogin({
    required String token,
    required Map<String, dynamic> data,
    required String fallbackUsername,
  }) {
    final ship = data['ship'];
    final shipMap = ship is Map<String, dynamic> ? ship : null;

    return UserSession(
      id: '${data['id'] ?? ''}',
      name: '${data['name'] ?? fallbackUsername}',
      username: data['username'] as String? ?? fallbackUsername,
      role: UserRole.fromBackend(data['role'] as String?),
      token: token,
      shipId: data['shipId'] as String? ?? shipMap?['id'] as String?,
      shipNumber:
          data['shipNumber'] as String? ?? shipMap?['shipNumber'] as String?,
      shipName: data['shipName'] as String? ?? shipMap?['name'] as String?,
    );
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Pengguna',
      username: json['username'] as String?,
      role: UserRole.fromBackend(json['role'] as String?),
      token: json['token'] as String? ?? '',
      shipId: json['shipId'] as String?,
      shipNumber: json['shipNumber'] as String?,
      shipName: json['shipName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role.name.toUpperCase(),
      'token': token,
      'shipId': shipId,
      'shipNumber': shipNumber,
      'shipName': shipName,
    };
  }
}
