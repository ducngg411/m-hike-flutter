class Hike {
  final int? id;
  final String name;
  final String location;
  final String date;
  final bool parkingAvailable;
  final double length;
  final String difficulty;
  final String? description;
  final String? estimatedDuration;
  final String? equipment;
  final String? imagePath; // added
  final double? latitude; // added
  final double? longitude; // added
  final String? startPlaceName; // Place name for directions
  final String? endPlaceName; // Place name for directions

  Hike({
    this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.parkingAvailable,
    required this.length,
    required this.difficulty,
    this.description,
    this.estimatedDuration,
    this.equipment,
    this.imagePath, // added
    this.latitude, // added
    this.longitude, // added
    this.startPlaceName,
    this.endPlaceName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'date': date,
      'parkingAvailable': parkingAvailable ? 1 : 0,
      'length': length,
      'difficulty': difficulty,
      'description': description,
      'estimatedDuration': estimatedDuration,
      'equipment': equipment,
      'imagePath': imagePath,  // added
      'latitude': latitude,  // added
      'longitude': longitude,  // added
      'startPlaceName': startPlaceName,
      'endPlaceName': endPlaceName,
    };
  }

  factory Hike.fromMap(Map<String, dynamic> map) {
    return Hike(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      date: map['date'],
      parkingAvailable: map['parkingAvailable'] == 1,
      length: map['length'],
      difficulty: map['difficulty'],
      description: map['description'],
      estimatedDuration: map['estimatedDuration'],
      equipment: map['equipment'],
      imagePath: map['imagePath'], // added
      latitude: map['latitude'], // added
      longitude: map['longitude'], // added
      startPlaceName: map['startPlaceName'],
      endPlaceName: map['endPlaceName'],
    );
  }

  Hike copyWith({
    int? id,
    String? name,
    String? location,
    String? date,
    bool? parkingAvailable,
    double? length,
    String? difficulty,
    String? description,
    String? estimatedDuration,
    String? equipment,
    String? imagePath, // added
    double? latitude, // added
    double? longitude, // added
    String? startPlaceName,
    String? endPlaceName,
  }) {
    return Hike(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      date: date ?? this.date,
      parkingAvailable: parkingAvailable ?? this.parkingAvailable,
      length: length ?? this.length,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      equipment: equipment ?? this.equipment,
      imagePath: imagePath ?? this.imagePath, // added
      latitude: latitude ?? this.latitude, // added
      longitude: longitude ?? this.longitude, // added
      startPlaceName: startPlaceName ?? this.startPlaceName,
      endPlaceName: endPlaceName ?? this.endPlaceName,
    );
  }

  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  /// Check if hike has route information for directions
  bool get hasRouteInfo {
    return startPlaceName != null && startPlaceName!.isNotEmpty &&
           endPlaceName != null && endPlaceName!.isNotEmpty;
  }

  String get coordinatesString => hasCoordinates
      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)})'
      : 'No coordinates available';
}