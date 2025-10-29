import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class SolarCalculator {
  // Calculate optimal solar panel angle based on location and season
  // Returns optimal tilt angle in radians. If `useDeviceLocation` is true,
  // attempt to get the device GPS coordinates; otherwise use the provided
  // `location` string as a fallback.
  static Future<double> calculateOptimalAngle(
    double compassDirection,
    String location, {
    bool useDeviceLocation = true,
  }) async {
    // Simplified calculation - in reality, you'd use GPS coordinates
    // and more sophisticated algorithms

    // Basic rule: angle = latitude for optimal year-round performance
    double latitude;

    if (useDeviceLocation) {
      try {
        Position pos = await _determinePosition();
        latitude = pos.latitude;
      } catch (e) {
        // If we fail to get device location, fall back to mapping
        latitude = _getLatitudeForLocation(location);
      }
    } else {
      latitude = _getLatitudeForLocation(location);
    }

    // Adjust for season (simplified)
    DateTime now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // Seasonal adjustment (±15 degrees)
    double seasonalAdjustment = 15 * math.sin(2 * math.pi * dayOfYear / 365);

    return (latitude + seasonalAdjustment) * math.pi / 180;
  }

  static double _getLatitudeForLocation(String location) {
    // Simplified location mapping
    switch (location.toLowerCase()) {
      case 'california':
        return 36.7783;
      case 'texas':
        return 31.9686;
      case 'florida':
        return 27.7663;
      case 'new york':
        return 40.7128;
      default:
        return 40.0; // Default to middle latitude
    }
  }

  // Permission and position helper using geolocator
  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  // Calculate solar efficiency based on angle difference
  static double calculateEfficiency(double currentAngle, double optimalAngle) {
    double difference = (currentAngle - optimalAngle).abs();

    // Efficiency decreases with angle difference
    // Simplified model: 100% at 0° difference, ~85% at 15° difference
    return math.max(0, 1 - (difference * 0.01));
  }
}
