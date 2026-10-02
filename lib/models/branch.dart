import 'package:latlong2/latlong.dart';

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

/// What the admin fills in to add or edit a branch.
class BranchDraft {
  final String name;
  final String address;
  final String city;
  final LatLng position;
  final String phone; // optional, empty if none
  final String openingTime; // HH:mm
  final String closingTime;

  const BranchDraft({
    required this.name,
    required this.address,
    required this.city,
    required this.position,
    required this.phone,
    required this.openingTime,
    required this.closingTime,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'address': address.trim(),
        'city': city.trim(),
        // 6 decimals is about 10 cm, plenty for a map pin.
        'latitude': double.parse(position.latitude.toStringAsFixed(6)),
        'longitude': double.parse(position.longitude.toStringAsFixed(6)),
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
        'openingTime': openingTime,
        'closingTime': closingTime,
      };
}
