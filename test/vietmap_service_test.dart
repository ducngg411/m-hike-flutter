import 'package:flutter_test/flutter_test.dart';
import 'package:m_hike_flutter/services/vietmap_service.dart';

void main() {
  group('VietMap Service Tests', () {
    test('Test Autocomplete API with "Hanoi" query', () async {
      print('\n=== Testing Autocomplete with "Hanoi" ===');

      final results = await VietMapService.searchPlaces('Hanoi');

      print('Number of results: ${results.length}');

      expect(results, isNotEmpty, reason: 'Should return at least one result');

      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        print('\nResult ${i + 1}:');
        print('  Display Name: ${result.displayName}');
        print('  Address: ${result.address}');
        print('  Latitude: ${result.lat}');
        print('  Longitude: ${result.lng}');
        print('  Place ID: ${result.placeId}');

        expect(result.lat, isNot(equals(0.0)), reason: 'Latitude should not be 0');
        expect(result.lng, isNot(equals(0.0)), reason: 'Longitude should not be 0');
        expect(result.displayName, isNotEmpty, reason: 'Display name should not be empty');
      }
    });

    test('Test Autocomplete API with "Ho Chi Minh City" query', () async {
      print('\n=== Testing Autocomplete with "Ho Chi Minh City" ===');

      final results = await VietMapService.searchPlaces('Ho Chi Minh City');

      print('Number of results: ${results.length}');

      expect(results, isNotEmpty, reason: 'Should return at least one result');

      if (results.isNotEmpty) {
        final firstResult = results[0];
        print('\nFirst Result:');
        print('  Display Name: ${firstResult.displayName}');
        print('  Address: ${firstResult.address}');
        print('  Latitude: ${firstResult.lat}');
        print('  Longitude: ${firstResult.lng}');

        expect(firstResult.lat, isNot(equals(0.0)));
        expect(firstResult.lng, isNot(equals(0.0)));
      }
    });

    test('Test Autocomplete API with Vietnamese characters "Đà Nẵng"', () async {
      print('\n=== Testing Autocomplete with "Đà Nẵng" ===');

      final results = await VietMapService.searchPlaces('Đà Nẵng');

      print('Number of results: ${results.length}');

      if (results.isNotEmpty) {
        final firstResult = results[0];
        print('\nFirst Result:');
        print('  Display Name: ${firstResult.displayName}');
        print('  Address: ${firstResult.address}');
        print('  Latitude: ${firstResult.lat}');
        print('  Longitude: ${firstResult.lng}');

        expect(firstResult.lat, isNot(equals(0.0)));
        expect(firstResult.lng, isNot(equals(0.0)));
      }
    });

    test('Test Route API between two points', () async {
      print('\n=== Testing Route API ===');

      // Test route between two points in Hanoi
      final route = await VietMapService.calculateRoute(
        startLat: 21.0285,
        startLng: 105.8542,
        endLat: 21.0245,
        endLng: 105.8412,
      );

      if (route != null) {
        print('Distance: ${route.distanceKm.toStringAsFixed(2)} km');
        print('Duration: ${route.durationMinutes} minutes');
        print('Number of coordinate points: ${route.coordinates.length}');

        expect(route.distanceKm, greaterThan(0));
        expect(route.durationMinutes, greaterThan(0));
        expect(route.coordinates, isNotEmpty);
      } else {
        print('Route calculation returned null');
      }
    });

    test('Test with empty query', () async {
      print('\n=== Testing with empty query ===');

      final results = await VietMapService.searchPlaces('');

      print('Number of results: ${results.length}');
      expect(results, isEmpty, reason: 'Empty query should return empty results');
    });
  });
}

