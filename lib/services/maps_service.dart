import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class MapsService {
  /// Open Google Maps with directions from the starting point to the destination
  /// Use place names for 100% accuracy
  /// Default is walking - suitable for hiking management app
  static Future<void> openDirections({
    required BuildContext context,
    required String startPlaceName,
    required String endPlaceName,
  }) async {
    try {
      // Encode place names to ensure valid URL
      final origin = Uri.encodeComponent(startPlaceName);
      final destination = Uri.encodeComponent(endPlaceName);

      // Create URL for Google Maps with directions from start to end
      // Default is walking mode for hiking
      final mapsUrl = 'https://www.google.com/maps/dir/?api=1'
          '&origin=$origin'
          '&destination=$destination'
          '&travelmode=walking';

      final Uri uri = Uri.parse(mapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Open in Google Maps app
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
