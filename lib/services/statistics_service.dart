import '../database/database_helper.dart';
import '../models/hike.dart';
import '../models/observation.dart';

class StatisticsService {
  // Get all statistics
  static Future<Map<String, dynamic>> getAllStatistics() async {
    final hikes = await DatabaseHelper.instance.getAllHikes();

    if (hikes.isEmpty) {
      return {
        'totalHikes': 0,
        'totalDistance': 0.0,
        'totalObservations': 0,
        'averageDistance': 0.0,
        'longestHike': null,
        'shortestHike': null,
        'favoriteLocation': null,
        'mostCommonDifficulty': null,
        'difficultyDistribution': <String, int>{},
        'locationDistribution': <String, int>{},
        'monthlyHikes': <String, int>{},
        'hikesWithGPS': 0,
        'observationsWithGPS': 0,
        'recentHikes': <Hike>[],
      };
    }

    // Basic statistics
    final totalHikes = hikes.length;
    final totalDistance = hikes.fold<double>(
      0.0,
          (sum, hike) => sum + hike.length,
    );
    final averageDistance = totalDistance / totalHikes;

    // Longest and shortest hike
    hikes.sort((a, b) => b.length.compareTo(a.length));
    final longestHike = hikes.first;
    final shortestHike = hikes.last;

    // Location statistics
    final locationCount = <String, int>{};
    for (final hike in hikes) {
      locationCount[hike.location] = (locationCount[hike.location] ?? 0) + 1;
    }
    final favoriteLocation = locationCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Difficulty statistics
    final difficultyCount = <String, int>{};
    for (final hike in hikes) {
      difficultyCount[hike.difficulty] = (difficultyCount[hike.difficulty] ?? 0) + 1;
    }
    final mostCommonDifficulty = difficultyCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Monthly statistics (last 12 months)
    final now = DateTime.now();
    final monthlyHikes = <String, int>{};
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyHikes[key] = 0;
    }

    for (final hike in hikes) {
      final date = DateTime.parse(hike.date);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (monthlyHikes.containsKey(key)) {
        monthlyHikes[key] = monthlyHikes[key]! + 1;
      }
    }

    // GPS statistics
    final hikesWithGPS = hikes.where((h) => h.hasCoordinates).length;

    // Observations statistics
    int totalObservations = 0;
    int observationsWithGPS = 0;

    for (final hike in hikes) {
      final observations = await DatabaseHelper.instance.getObservationsForHike(hike.id!);
      totalObservations += observations.length;
      observationsWithGPS += observations.where((o) => o.hasCoordinates).length;
    }

    // Recent hikes (last 5)
    final sortedHikes = List<Hike>.from(hikes);
    sortedHikes.sort((a, b) => b.date.compareTo(a.date));
    final recentHikes = sortedHikes.take(5).toList();

    return {
      'totalHikes': totalHikes,
      'totalDistance': totalDistance,
      'totalObservations': totalObservations,
      'averageDistance': averageDistance,
      'longestHike': longestHike,
      'shortestHike': shortestHike,
      'favoriteLocation': favoriteLocation,
      'mostCommonDifficulty': mostCommonDifficulty,
      'difficultyDistribution': difficultyCount,
      'locationDistribution': locationCount,
      'monthlyHikes': monthlyHikes,
      'hikesWithGPS': hikesWithGPS,
      'observationsWithGPS': observationsWithGPS,
      'recentHikes': recentHikes,
    };
  }

  // Get statistics for a specific date range
  static Future<Map<String, dynamic>> getStatisticsForDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    final allHikes = await DatabaseHelper.instance.getAllHikes();

    final hikes = allHikes.where((hike) {
      final hikeDate = DateTime.parse(hike.date);
      return hikeDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          hikeDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    if (hikes.isEmpty) {
      return {
        'totalHikes': 0,
        'totalDistance': 0.0,
        'averageDistance': 0.0,
      };
    }

    final totalDistance = hikes.fold<double>(
      0.0,
          (sum, hike) => sum + hike.length,
    );

    return {
      'totalHikes': hikes.length,
      'totalDistance': totalDistance,
      'averageDistance': totalDistance / hikes.length,
      'hikes': hikes,
    };
  }
}