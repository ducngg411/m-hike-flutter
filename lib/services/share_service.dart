import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../models/hike.dart';
import '../models/observation.dart';

class ShareService {
  // Share hike as text
  static Future<void> shareHikeText(Hike hike, {List<Observation>? observations}) async {
    final StringBuffer buffer = StringBuffer();

    // Hike details
    buffer.writeln('🥾 ${hike.name}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📍 Location: ${hike.location}');
    buffer.writeln('📅 Date: ${hike.date}');
    buffer.writeln('📏 Length: ${hike.length} km');
    buffer.writeln('⚡ Difficulty: ${hike.difficulty}');
    buffer.writeln('🅿️ Parking: ${hike.parkingAvailable ? "Available" : "Not Available"}');

    if (hike.estimatedDuration != null) {
      buffer.writeln('⏱️ Duration: ${hike.estimatedDuration}');
    }

    if (hike.description != null && hike.description!.isNotEmpty) {
      buffer.writeln('\n📝 Description:');
      buffer.writeln(hike.description);
    }

    if (hike.equipment != null && hike.equipment!.isNotEmpty) {
      buffer.writeln('\n🎒 Equipment:');
      buffer.writeln(hike.equipment);
    }

    if (hike.hasCoordinates) {
      buffer.writeln('\n🗺️ GPS: ${hike.coordinatesString}');
      buffer.writeln('Google Maps: https://maps.google.com/?q=${hike.latitude},${hike.longitude}');
    }

    // Observations
    if (observations != null && observations.isNotEmpty) {
      buffer.writeln('\n━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📸 Observations (${observations.length}):');
      buffer.writeln('━━━━━━━━━━━━━━━━━━');

      for (int i = 0; i < observations.length; i++) {
        final obs = observations[i];
        buffer.writeln('\n${i + 1}. ${obs.observation}');
        buffer.writeln('   ⏰ ${_formatDateTime(obs.time)}');

        if (obs.comments != null && obs.comments!.isNotEmpty) {
          buffer.writeln('   💬 ${obs.comments}');
        }

        if (obs.hasCoordinates) {
          buffer.writeln('   📍 ${obs.coordinatesString}');
        }
      }
    }

    buffer.writeln('\n━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Shared from M-Hike App 🏔️');

    await Share.share(
      buffer.toString(),
      subject: '${hike.name} - Hike Details',
    );
  }

  // Share hike with image
  static Future<void> shareHikeWithImage(
      Hike hike,
      String? imagePath, {
        List<Observation>? observations,
      }) async {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('🥾 ${hike.name}');
    buffer.writeln('📍 ${hike.location} • 📏 ${hike.length} km');
    buffer.writeln('⚡ ${hike.difficulty} • 📅 ${hike.date}');

    if (hike.hasCoordinates) {
      buffer.writeln('🗺️ https://maps.google.com/?q=${hike.latitude},${hike.longitude}');
    }

    if (observations != null && observations.isNotEmpty) {
      buffer.writeln('\n📸 ${observations.length} observation${observations.length > 1 ? 's' : ''} recorded');
    }

    buffer.writeln('\nShared from M-Hike App 🏔️');

    // Share with image
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: buffer.toString(),
          subject: '${hike.name} - Hike Details',
        );
        return;
      }
    }

    // Fallback to text only
    await Share.share(
      buffer.toString(),
      subject: '${hike.name} - Hike Details',
    );
  }

  // Share observation
  static Future<void> shareObservation(
      Observation observation,
      String hikeName,
      ) async {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('📸 Observation from ${hikeName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🔍 ${observation.observation}');
    buffer.writeln('⏰ ${_formatDateTime(observation.time)}');

    if (observation.comments != null && observation.comments!.isNotEmpty) {
      buffer.writeln('\n💬 ${observation.comments}');
    }

    if (observation.hasCoordinates) {
      buffer.writeln('\n📍 ${observation.coordinatesString}');
      buffer.writeln('🗺️ https://maps.google.com/?q=${observation.latitude},${observation.longitude}');
    }

    buffer.writeln('\nShared from M-Hike App 🏔️');

    // Share with image if exists
    if (observation.imagePath != null && observation.imagePath!.isNotEmpty) {
      final file = File(observation.imagePath!);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(observation.imagePath!)],
          text: buffer.toString(),
        );
        return;
      }
    }

    // Fallback to text only
    await Share.share(buffer.toString());
  }

  // Share screenshot of widget
  static Future<void> shareScreenshot(
      ScreenshotController screenshotController,
      String text,
      ) async {
    try {
      final Uint8List? image = await screenshotController.capture();

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: text,
        );

        // Clean up
        await imageFile.delete();
      }
    } catch (e) {
      debugPrint('Error sharing screenshot: $e');
    }
  }

  // Share multiple hikes summary
  static Future<void> shareHikesSummary(
      List<Hike> hikes,
      Map<String, dynamic> stats,
      ) async {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('🏔️ My Hiking Summary');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 Statistics:');
    buffer.writeln('• Total Hikes: ${stats['totalHikes']}');
    buffer.writeln('• Total Distance: ${stats['totalDistance']} km');
    buffer.writeln('• Total Observations: ${stats['totalObservations']}');
    buffer.writeln('• Favorite Location: ${stats['favoriteLocation'] ?? 'N/A'}');
    buffer.writeln('• Most Common Difficulty: ${stats['mostCommonDifficulty'] ?? 'N/A'}');

    if (hikes.isNotEmpty) {
      buffer.writeln('\n━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📝 Recent Hikes:');
      buffer.writeln('━━━━━━━━━━━━━━━━━━');

      final recentHikes = hikes.take(5).toList();
      for (int i = 0; i < recentHikes.length; i++) {
        final hike = recentHikes[i];
        buffer.writeln('\n${i + 1}. ${hike.name}');
        buffer.writeln('   📍 ${hike.location}');
        buffer.writeln('   📏 ${hike.length} km • ⚡ ${hike.difficulty}');
        buffer.writeln('   📅 ${hike.date}');
      }
    }

    buffer.writeln('\n━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Shared from M-Hike App 🏔️');

    await Share.share(
      buffer.toString(),
      subject: 'My Hiking Summary',
    );
  }

  static String _formatDateTime(String isoDateTime) {
    final dateTime = DateTime.parse(isoDateTime);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}