import '../../nahkoda/domain/nahkoda_models.dart';

class CreateShipPayload {
  const CreateShipPayload({required this.shipNumber, required this.name});

  final String shipNumber;
  final String name;

  Map<String, dynamic> toJson() {
    return {'shipNumber': shipNumber, 'name': name};
  }
}

class CreateUserPayload {
  const CreateUserPayload({
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.shipId,
  });

  final String name;
  final String username;
  final String password;
  final String role;
  final String? shipId;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      if (shipId != null && shipId!.isNotEmpty) 'shipId': shipId,
    };
  }
}

class UpdateUserPayload {
  const UpdateUserPayload({
    required this.name,
    required this.username,
    required this.role,
    this.password,
    this.shipId,
  });

  final String name;
  final String username;
  final String role;
  final String? password;
  final String? shipId;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'role': role,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (shipId != null && shipId!.isNotEmpty) 'shipId': shipId,
    };
  }
}

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.shipId,
    this.ship,
  });

  final String id;
  final String name;
  final String username;
  final String role;
  final String? shipId;
  final ShipInfo? ship;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final ship = json['ship'];
    return ManagedUser(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? '-'}',
      username: '${json['username'] ?? ''}',
      role: '${json['role'] ?? ''}'.toUpperCase(),
      shipId: json['shipId'] as String?,
      ship: ship is Map<String, dynamic> ? ShipInfo.fromJson(ship) : null,
    );
  }
}

class ShipLiveLocation {
  const ShipLiveLocation({
    required this.shipId,
    required this.shipNumber,
    required this.shipName,
    required this.latitude,
    required this.longitude,
    this.captain,
    this.updatedAt,
    this.latestSubmission,
  });

  final String shipId;
  final String shipNumber;
  final String shipName;
  final double latitude;
  final double longitude;
  final Captain? captain;
  final String? updatedAt;
  final Submission? latestSubmission;

  bool get isActive {
    final updated = DateTime.tryParse(updatedAt ?? '');
    if (updated == null) return false;
    return DateTime.now().difference(updated.toLocal()).inMinutes <= 30;
  }

  factory ShipLiveLocation.fromJson(Map<String, dynamic> json) {
    final captain = json['captain'];
    final latestSubmission = json['latestSubmission'];
    return ShipLiveLocation(
      shipId: '${json['shipId'] ?? ''}',
      shipNumber: '${json['shipNumber'] ?? '-'}',
      shipName: '${json['shipName'] ?? '-'}',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      captain: captain is Map<String, dynamic>
          ? Captain.fromJson(captain)
          : null,
      updatedAt: json['updatedAt'] as String?,
      latestSubmission: latestSubmission is Map<String, dynamic>
          ? Submission.fromJson(latestSubmission)
          : null,
    );
  }
}

class ChecklistQuestion {
  const ChecklistQuestion({required this.itemNo, required this.question});

  final int itemNo;
  final String question;

  factory ChecklistQuestion.fromJson(Map<String, dynamic> json) {
    return ChecklistQuestion(
      itemNo: _toInt(json['itemNo']),
      question: '${json['question'] ?? '-'}',
    );
  }
}

class InspectionItemPayload {
  const InspectionItemPayload({
    required this.itemNo,
    required this.condition,
    this.note,
  });

  final int itemNo;
  final String condition;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'itemNo': itemNo,
      'condition': condition,
      if (note != null && note!.trim().isNotEmpty) 'note': note,
    };
  }
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

double _toDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
