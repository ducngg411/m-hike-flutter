import 'dart:convert';
import 'package:http/http.dart' as http;

class VietMapService {
  // Replace with your actual VietMap API key
  static const String apiKey = '70791b5e522854f73ccb831a7f015bde93dfc4b58bd2d444';
  static const String autocompleteUrl = 'https://maps.vietmap.vn/api/autocomplete/v3';
  static const String placeUrl = 'https://maps.vietmap.vn/api/place/v3';
  static const String routeUrl = 'https://maps.vietmap.vn/api/route/v3';
  static const String reverseUrl = 'https://maps.vietmap.vn/api/reverse/v3';

  /// Search for places using Autocomplete API v3
  /// Returns list with ref_id for later use with Place API
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse('$autocompleteUrl?apikey=$apiKey&text=$query');
      final response = await http.get(url);

      print('Autocomplete v3 API Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Autocomplete API v3 returns {data: [...]} format
        List results = [];
        if (data is Map && data['data'] != null && data['data'] is List) {
          results = data['data'] as List;
        } else if (data is List) {
          results = data;
        }

        // Convert to PlaceSearchResult list (includes ref_id)
        return results.map((item) => PlaceSearchResult.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  /// Get place details (exact coordinates) using Place API v3
  /// Uses ref_id from autocomplete result
  static Future<PlaceDetails?> getPlaceDetails(String refId) async {
    if (refId.isEmpty) return null;

    try {
      final url = Uri.parse('$placeUrl?apikey=$apiKey&refid=$refId');
      final response = await http.get(url);

      print('Place v3 API Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceDetails.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }


  /// Calculate route and distance between two points using Route API v3
  /// point format: latitude,longitude
  static Future<RouteResult?> calculateRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String vehicle = 'car', // car, motorcycle, truck
    bool pointsEncoded = false, // false for simple [lon,lat] pairs
  }) async {
    try {
      // VietMap Route API v3 format: point=lat,lng&point=lat,lng
      final url = Uri.parse(
        '$routeUrl?apikey=$apiKey'
        '&point=$startLat,$startLng'
        '&point=$endLat,$endLng'
        '&vehicle=$vehicle'
        '&points_encoded=$pointsEncoded'
      );

      print('Route API URL: $url'); // Debug log

      final response = await http.get(url);

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RouteResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error calculating route: $e');
      return null;
    }
  }

  /// Reverse Geocoding - Get address from GPS coordinates using Reverse API v3.0
  /// Returns address information from latitude and longitude
  static Future<ReverseGeocodeResult?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$reverseUrl?apikey=$apiKey&lat=$latitude&lng=$longitude'
      );

      print('Reverse Geocoding API URL: $url'); // Debug log

      final response = await http.get(url);

      print('Reverse API Response status: ${response.statusCode}'); // Debug log
      print('Reverse API Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // VietMap Reverse API v3.0 returns an ARRAY of results
        // We need to take the first element
        if (data is List && data.isNotEmpty) {
          return ReverseGeocodeResult.fromJson(data[0] as Map<String, dynamic>);
        }

        // Fallback if response format is different
        if (data is Map) {
          return ReverseGeocodeResult.fromJson(data as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Get formatted address string from GPS coordinates
  /// Returns a readable address or coordinates if no address found
  static Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final result = await reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      if (result != null && result.display.isNotEmpty) {
        return result.display;
      }

      // Fallback to coordinates if no address found
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      print('Error getting address: $e');
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }
}

/// Model for place search result from Autocomplete API
class PlaceSearchResult {
  final String displayName;
  final String address;
  final double lat;
  final double lng;
  final String? placeId;

  PlaceSearchResult({
    required this.displayName,
    required this.address,
    required this.lat,
    required this.lng,
    this.placeId,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    // Autocomplete API v3 returns ref_id, display, address
    // We store ref_id to fetch exact coordinates later using Place API v3
    return PlaceSearchResult(
      displayName: json['display'] ?? json['name'] ?? json['address'] ?? '',
      address: json['address'] ?? json['display'] ?? '',
      lat: 0.0, // Will be filled by Place API v3
      lng: 0.0, // Will be filled by Place API v3
      placeId: json['ref_id']?.toString(),
    );
  }

  @override
  String toString() => displayName;
}

/// Model for place details from Place API v3
class PlaceDetails {
  final String display;
  final String name;
  final String? hsNum;
  final String? street;
  final String address;
  final int? cityId;
  final String? city;
  final int? districtId;
  final String? district;
  final int? wardId;
  final String? ward;
  final double lat;
  final double lng;

  PlaceDetails({
    required this.display,
    required this.name,
    this.hsNum,
    this.street,
    required this.address,
    this.cityId,
    this.city,
    this.districtId,
    this.district,
    this.wardId,
    this.ward,
    required this.lat,
    required this.lng,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      display: json['display'] ?? '',
      name: json['name'] ?? '',
      hsNum: json['hs_num']?.toString(),
      street: json['street']?.toString(),
      address: json['address'] ?? '',
      cityId: json['city_id'] as int?,
      city: json['city']?.toString(),
      districtId: json['district_id'] as int?,
      district: json['district']?.toString(),
      wardId: json['ward_id'] as int?,
      ward: json['ward']?.toString(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model for route calculation result
class RouteResult {
  final double distanceKm;
  final int durationMinutes;
  final List<List<double>> coordinates;
  final List<RouteInstruction> instructions;

  RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.coordinates,
    required this.instructions,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    double distance = 0;
    int duration = 0;
    List<List<double>> coords = [];
    List<RouteInstruction> instructions = [];

    try {
      // Parse based on VietMap Route API v3 response structure
      if (json['paths'] != null && json['paths'].isNotEmpty) {
        final path = json['paths'][0];
        distance = (path['distance'] ?? 0.0).toDouble() / 1000; // Convert to km
        duration = ((path['time'] ?? 0) / 60000).round(); // Convert to minutes

        if (path['points'] != null && path['points']['coordinates'] != null) {
          coords = (path['points']['coordinates'] as List)
              .map((coord) => [
                    (coord[0] as num).toDouble(),
                    (coord[1] as num).toDouble(),
                  ])
              .toList();
        }

        // Parse instructions (turn-by-turn directions)
        if (path['instructions'] != null) {
          instructions = (path['instructions'] as List)
              .map((inst) => RouteInstruction.fromJson(inst as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('Error parsing route result: $e');
    }

    return RouteResult(
      distanceKm: distance,
      durationMinutes: duration,
      coordinates: coords,
      instructions: instructions,
    );
  }
}

/// Model for route instruction (turn-by-turn direction)
class RouteInstruction {
  final double distance;
  final int sign;
  final String text;
  final int time;
  final String? streetName;

  RouteInstruction({
    required this.distance,
    required this.sign,
    required this.text,
    required this.time,
    this.streetName,
  });

  factory RouteInstruction.fromJson(Map<String, dynamic> json) {
    return RouteInstruction(
      distance: (json['distance'] ?? 0.0).toDouble(),
      sign: json['sign'] ?? 0,
      text: json['text'] ?? '',
      time: json['time'] ?? 0,
      streetName: json['street_name']?.toString(),
    );
  }
}

/// Model for reverse geocoding result from Reverse API v3.0
class ReverseGeocodeResult {
  final String display;
  final String name;
  final String? hsNum;
  final String? street;
  final String address;
  final int? cityId;
  final String? city;
  final int? districtId;
  final String? district;
  final int? wardId;
  final String? ward;
  final double lat;
  final double lng;
  final double distance;

  ReverseGeocodeResult({
    required this.display,
    required this.name,
    this.hsNum,
    this.street,
    required this.address,
    this.cityId,
    this.city,
    this.districtId,
    this.district,
    this.wardId,
    this.ward,
    required this.lat,
    required this.lng,
    required this.distance,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      display: json['display'] ?? json['address'] ?? '',
      name: json['name'] ?? '',
      hsNum: json['hs_num']?.toString(),
      street: json['street']?.toString(),
      address: json['address'] ?? '',
      cityId: json['city_id'] as int?,
      city: json['city']?.toString(),
      districtId: json['district_id'] as int?,
      district: json['district']?.toString(),
      wardId: json['ward_id'] as int?,
      ward: json['ward']?.toString(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get a short address description
  String get shortAddress {
    List<String> parts = [];

    if (street != null && street!.isNotEmpty) {
      parts.add(street!);
    }
    if (ward != null && ward!.isNotEmpty) {
      parts.add(ward!);
    }
    if (district != null && district!.isNotEmpty) {
      parts.add(district!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }

    return parts.isNotEmpty ? parts.join(', ') : display;
  }
}

