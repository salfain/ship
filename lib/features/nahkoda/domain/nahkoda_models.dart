import 'package:file_selector/file_selector.dart';

import '../../../core/utils/public_file_url.dart';

class Captain {
  const Captain({required this.id, required this.name, required this.username});

  final String id;
  final String name;
  final String username;

  factory Captain.fromJson(Map<String, dynamic> json) {
    return Captain(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? '-'}',
      username: '${json['username'] ?? ''}',
    );
  }
}

class ShipLocationPoint {
  const ShipLocationPoint({
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  final double latitude;
  final double longitude;
  final String? createdAt;

  factory ShipLocationPoint.fromJson(Map<String, dynamic> json) {
    return ShipLocationPoint(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      createdAt: (json['updatedAt'] ?? json['createdAt']) as String?,
    );
  }
}

class ShipSummary {
  const ShipSummary({
    required this.id,
    required this.shipNumber,
    required this.name,
    this.captain,
    this.latestLocation,
    this.latestSubmission,
  });

  final String id;
  final String shipNumber;
  final String name;
  final Captain? captain;
  final ShipLocationPoint? latestLocation;
  final Submission? latestSubmission;

  factory ShipSummary.fromJson(Map<String, dynamic> json) {
    final captain = json['captain'];
    final latestLocation = json['latestLocation'];
    final latestSubmission = json['latestSubmission'];
    return ShipSummary(
      id: '${json['id'] ?? ''}',
      shipNumber: '${json['shipNumber'] ?? '-'}',
      name: '${json['name'] ?? '-'}',
      captain: captain is Map<String, dynamic>
          ? Captain.fromJson(captain)
          : null,
      latestLocation: latestLocation is Map<String, dynamic>
          ? ShipLocationPoint.fromJson(latestLocation)
          : null,
      latestSubmission: latestSubmission is Map<String, dynamic>
          ? Submission.fromJson(latestSubmission)
          : null,
    );
  }

  ShipSummary copyWith({ShipLocationPoint? latestLocation}) {
    return ShipSummary(
      id: id,
      shipNumber: shipNumber,
      name: name,
      captain: captain,
      latestLocation: latestLocation ?? this.latestLocation,
      latestSubmission: latestSubmission,
    );
  }
}

class ShipInfo {
  const ShipInfo({
    required this.id,
    required this.shipNumber,
    required this.name,
    this.captain,
  });

  final String id;
  final String shipNumber;
  final String name;
  final Captain? captain;

  factory ShipInfo.fromJson(Map<String, dynamic> json) {
    final captain = json['captain'];
    return ShipInfo(
      id: '${json['id'] ?? ''}',
      shipNumber: '${json['shipNumber'] ?? '-'}',
      name: '${json['name'] ?? '-'}',
      captain: captain is Map<String, dynamic>
          ? Captain.fromJson(captain)
          : null,
    );
  }
}

class Submission {
  const Submission({
    required this.id,
    required this.captainName,
    required this.employeeCount,
    required this.cargo,
    required this.cargoAmount,
    required this.status,
    required this.submittedAt,
    this.ship,
    this.reviewNote,
    this.sailingPermitUrl,
    this.callSignCertificateUrl,
    this.safetyCertificateUrl,
    this.radioStationPermitUrl,
    this.reviewedAt,
  });

  final String id;
  final ShipInfo? ship;
  final String captainName;
  final int employeeCount;
  final String cargo;
  final String cargoAmount;
  final String status;
  final String submittedAt;
  final String? reviewNote;
  final String? sailingPermitUrl;
  final String? callSignCertificateUrl;
  final String? safetyCertificateUrl;
  final String? radioStationPermitUrl;
  final String? reviewedAt;

  String get shortCode {
    final tail = id.length >= 5
        ? id.substring(id.length - 5).toUpperCase()
        : id;
    return 'PBH-$tail';
  }

  List<SubmissionDocument> get documents {
    return [
      SubmissionDocument('Surat Izin Berlayar', sailingPermitUrl),
      SubmissionDocument('Surat Tanda Panggilan', callSignCertificateUrl),
      SubmissionDocument('Sertifikat Keselamatan', safetyCertificateUrl),
      SubmissionDocument('Izin Stasiun Radio', radioStationPermitUrl),
    ];
  }

  factory Submission.fromJson(Map<String, dynamic> json) {
    final ship = json['ship'];
    return Submission(
      id: '${json['id'] ?? ''}',
      ship: ship is Map<String, dynamic> ? ShipInfo.fromJson(ship) : null,
      captainName: '${json['captainName'] ?? '-'}',
      employeeCount: _toInt(json['employeeCount']),
      cargo: '${json['cargo'] ?? '-'}',
      cargoAmount: '${json['cargoAmount'] ?? '-'}',
      status: '${json['status'] ?? ''}',
      submittedAt: '${json['submittedAt'] ?? json['createdAt'] ?? ''}',
      reviewNote: json['reviewNote'] as String?,
      sailingPermitUrl: PublicFileUrl.resolve(json['sailingPermitUrl']),
      callSignCertificateUrl: PublicFileUrl.resolve(
        json['callSignCertificateUrl'],
      ),
      safetyCertificateUrl: PublicFileUrl.resolve(json['safetyCertificateUrl']),
      radioStationPermitUrl: PublicFileUrl.resolve(
        json['radioStationPermitUrl'],
      ),
      reviewedAt: json['reviewedAt'] as String?,
    );
  }
}

class SubmissionDocument {
  const SubmissionDocument(this.label, this.url);

  final String label;
  final String? url;
}

class CreateSubmissionPayload {
  const CreateSubmissionPayload({
    required this.captainName,
    required this.employeeCount,
    required this.cargo,
    required this.cargoAmount,
    required this.sailingPermit,
    required this.callSignCertificate,
    required this.safetyCertificate,
    required this.radioStationPermit,
  });

  final String captainName;
  final int employeeCount;
  final String cargo;
  final String cargoAmount;
  final XFile sailingPermit;
  final XFile callSignCertificate;
  final XFile safetyCertificate;
  final XFile radioStationPermit;
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
