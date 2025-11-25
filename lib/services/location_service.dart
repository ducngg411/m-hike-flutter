import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  static Future<Position?> getCurrentPosition({
    required BuildContext context,
  }) async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          _showLocationServiceDialog(context);
        }
        return null;
      }

      // Check permission
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          _showPermissionDeniedDialog(context);
        }
        return null;
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return null;
    }
  }

  // Get address from coordinates (Reverse Geocoding)
  static Future<String?> getAddressFromCoordinates(
      double latitude,
      double longitude,
      ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build address string
        List<String> addressParts = [];

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        return addressParts.join(', ');
      }

      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  // Get coordinates from address (Forward Geocoding)
  static Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  // Format coordinates for display
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Calculate distance between two points (in kilometers)
  static double calculateDistance(
      double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,
      ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }

  // Show dialog when location service is disabled
  static void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Service Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Show dialog when permission is permanently denied
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Get location with loading dialog
  static Future<Position?> getCurrentPositionWithDialog(
      BuildContext context,
      ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Getting your location...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Get position
    final position = await getCurrentPosition(context: context);

    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    return position;
  }

  // Get location with address
  static Future<Map<String, dynamic>?> getLocationWithAddress(
      BuildContext context,
      ) async {
    final position = await getCurrentPositionWithDialog(context);

    if (position == null) return null;

    // Get address
    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return {
      'position': position,
      'address': address ?? 'Unknown location',
      'coordinates': formatCoordinates(position.latitude, position.longitude),
    };
  }
}