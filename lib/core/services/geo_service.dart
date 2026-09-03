// lib/services/geo_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GeoService {
  /// Ensures location services are enabled (GPS, etc.)
  Future<bool> _ensureServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      // Optionally prompt
      await Geolocator.openLocationSettings();
      return await Geolocator.isLocationServiceEnabled();
    }
    return true;
  }

  /// Ensures permission is granted (whileInUse/always).
  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Prompt app settings
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current position with platform-aware settings
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    if (!await _ensureServiceEnabled()) return null;
    if (!await _ensurePermission()) return null;

    LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 10),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.other,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    } else if (kIsWeb) {
      settings = const LocationSettings(accuracy: LocationAccuracy.high);
    } else {
      settings = LocationSettings(accuracy: accuracy);
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: settings,
        timeLimit: timeLimit,
      );
    } on TimeoutException {
      return null;
    }
  }

  // Last known position (may be null if none cached)
  Future<Position?> getLastKnownPosition() => Geolocator.getLastKnownPosition();

  // Stream of service status (enabled/disabled)
  Stream<ServiceStatus> get serviceStatusStream => Geolocator.getServiceStatusStream();

  // Stream of positions (remember to cancel)
  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 0,
  }) {
    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterMeters,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
