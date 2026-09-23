import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Global location notifier accessible throughout the app
final ValueNotifier<Position?> currentPositionNotifier = ValueNotifier<Position?>(null);

class LocationService {
  static Future<void> startListening() async {
    // Avoid WinRT C++ background thread locks during Android Studio Windows debugging
    if (!kIsWeb && Platform.isWindows) {
      currentPositionNotifier.value = Position(
        longitude: 121.5654,
        latitude: 25.0330,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 25.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );
      return;
    }

    // Android / iOS real GPS stream
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      currentPositionNotifier.value = position;
    });
  }
}