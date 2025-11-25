class HikeLocation {
  final String name;
  final String address;
  final double lat;
  final double lng;

  HikeLocation({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }

  factory HikeLocation.fromMap(Map<String, dynamic> map) {
    return HikeLocation(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() => name;
}

