class Observation {
  final int? id;
  final int hikeId;
  final String observation;
  final String time;
  final String? comments;
  final String? imagePath; // added
  final double? latitude; // added
  final double? longitude; // added

  Observation({
    this.id,
    required this.hikeId,
    required this.observation,
    required this.time,
    this.comments,
    this.imagePath, // added
    this.latitude, // added
    this.longitude, // added
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hikeId': hikeId,
      'observation': observation,
      'time': time,
      'comments': comments,
      'imagePath': imagePath, // added
      'latitude': latitude, // added
      'longitude': longitude, // added
    };
  }

  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      id: map['id'],
      hikeId: map['hikeId'],
      observation: map['observation'],
      time: map['time'],
      comments: map['comments'],
      imagePath: map['imagePath'], // added
      latitude: map['latitude'], // added
      longitude: map['longitude'], // added
    );
  }

  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  String get coordinatesString => hasCoordinates
      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
      : 'No coordinates';
}