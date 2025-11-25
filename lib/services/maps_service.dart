import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for opening Google Maps with directions
class MapsService {
  /// Opens Google Maps with directions from start to end location.
  /// Uses place names for accuracy instead of coordinates.
  static Future<void> openDirections({
    required BuildContext context,
    required String startPlaceName,
    required String endPlaceName,
  }) async {
    // URL encode the place names for safety
    final origin = Uri.encodeComponent(startPlaceName);
    final destination = Uri.encodeComponent(endPlaceName);

    // Build Google Maps directions URL
    final mapsUrl = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';

    final Uri uri = Uri.parse(mapsUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
