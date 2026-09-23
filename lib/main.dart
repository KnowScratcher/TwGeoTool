import 'package:flutter/material.dart';
import 'package:twgeo/page/home.dart';
import 'package:twgeo/service/location.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocationService.startListening().catchError((error) {
    debugPrint('Location error: $error');
  });
  runApp(const GeoTwApp());
}

class GeoTwApp extends StatelessWidget {
  const GeoTwApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desktop GIS Workspace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFFEDEDED),
        cardColor: const Color(0xFF252526),
        dividerColor: const Color(0xFF3F3F46),
      ),
      home: const GeoHomeScreen(),
    );
  }
}
