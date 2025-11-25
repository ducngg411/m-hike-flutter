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
  final String? startPlaceName; // Tên điểm bắt đầu
  final String? endPlaceName; // Tên điểm kết thúc

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
    this.startPlaceName, // added
    this.endPlaceName, // added
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
      'startPlaceName': startPlaceName,  // added
      'endPlaceName': endPlaceName,  // added
      'equipment': equipment,
      'imagePath': imagePath,  // added
      'latitude': latitude,  // added
      'longitude': longitude,  // added
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
      startPlaceName: map['startPlaceName'], // added
      endPlaceName: map['endPlaceName'], // added
      description: map['description'],
      estimatedDuration: map['estimatedDuration'],
      equipment: map['equipment'],
      imagePath: map['imagePath'], // added
      latitude: map['latitude'], // added
      longitude: map['longitude'], // added
    );
  }

  Hike copyWith({
    int? id,
    String? name,
    String? location,
    String? date,
    bool? parkingAvailable,
    String? startPlaceName, // added
    String? endPlaceName, // added
    double? length,
    String? difficulty,
    String? description,
    String? estimatedDuration,
    String? equipment,
    String? imagePath, // added
    double? latitude, // added
    double? longitude, // added
  }) {
    return Hike(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      date: date ?? this.date,
      parkingAvailable: parkingAvailable ?? this.parkingAvailable,
      startPlaceName: startPlaceName ?? this.startPlaceName, // added
      endPlaceName: endPlaceName ?? this.endPlaceName, // added
      length: length ?? this.length,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      equipment: equipment ?? this.equipment,
      imagePath: imagePath ?? this.imagePath, // added
      latitude: latitude ?? this.latitude, // added
      longitude: longitude ?? this.longitude, // added
    );
  }

  // Kiểm tra xem có thông tin route không (có cả start và end place names)
  bool get hasRouteInfo {
    return startPlaceName != null && startPlaceName!.isNotEmpty &&
           endPlaceName != null && endPlaceName!.isNotEmpty;
  }

  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  String get coordinatesString => hasCoordinates
      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
      : 'No coordinates available';
}