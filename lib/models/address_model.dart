class UserAddress {
  final String id;
  final String userId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final String label;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.userId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    required this.label,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'],
      userId: json['user_id'],
      addressLine1: json['address_line_1'],
      addressLine2: json['address_line_2'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      label: json['label'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'is_default': isDefault,
    };
  }

  String get fullAddress {
    String address = addressLine1;
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      address += ', $addressLine2';
    }
    address += ', $city';
    if (state != null && state!.isNotEmpty) {
      address += ', $state';
    }
    if (zipCode != null && zipCode!.isNotEmpty) {
      address += ' $zipCode';
    }
    return address;
  }
}

class DeliveryLocation {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}