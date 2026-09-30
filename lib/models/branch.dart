import 'package:latlong2/latlong.dart';

/// The Dart version of the Java `BranchResponse` record.
///
/// { "id": 1, "name": "Abdoun Branch", "address": "...", "city": "Amman",
///   "latitude": 31.9454, "longitude": 35.8818, "phone": "+96265000001",
///   "openingTime": "06:00", "closingTime": "23:00" }
class Branch {
  final int id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String? phone;
  final String openingTime;
  final String closingTime;

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.openingTime,
    required this.closingTime,
  });

  /// Where the pin goes on the map.
  LatLng get position => LatLng(latitude, longitude);

  String get hours => '$openingTime – $closingTime';

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      openingTime: json['openingTime'] as String,
      closingTime: json['closingTime'] as String,
    );
  }
}
