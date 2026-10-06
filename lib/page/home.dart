import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:twgeo/page/map.dart';
import 'package:twgeo/service/location.dart';

import 'package:twgeo/service/coordinate.dart';

class GeoHomeScreen extends StatefulWidget {
  const GeoHomeScreen({super.key});

  @override
  State<GeoHomeScreen> createState() => _GeoHomeScreenState();
}

class _GeoHomeScreenState extends State<GeoHomeScreen> {
  String _currentAreaName = '...';
  String _currentEpochName = '...';
  String _currentRockName = '...';
  String _currentRockType = '...';
  LatLng _lastPosition = LatLng(0, 0);
  int _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
  final distance = Distance();

  Map<String, String> _buildGeologyInfo(String tooltipText) {
    final lines = tooltipText.split('\n');
    final info = <String, String>{};
    for (final line in lines) {
      final parts = line.split('：');
      if (parts.length > 1) {
        info[parts.first] = parts.sublist(1).join('：');
      }
    }
    return info;
  }

  Future<void> _fetchCurrentArea(LatLng location) async {
    Map<String, dynamic>? nameData;
    Map<String, dynamic>? geoData;
    Map<String, String>? parsedGeoData;
    final nameUrl = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?zoom=10&lat=${location.latitude.toStringAsFixed(6)}&lon=${location.longitude.toStringAsFixed(6)}&format=json",
    );
    final convertedPoint = TaiwanGeoConverter.wgs84ToTwd97(point: location);
    final geoUrl = Uri.parse(
      "https://geomap.gsmma.gov.tw/api/Tile/v1/getTooltip.cfm?layer=TYPE3&srs=EPSG%3A3857&z=17&x=${convertedPoint.x.toStringAsFixed(0)}&y=${convertedPoint.y.toStringAsFixed(0)}",
    );
    final nameResponse = await http
        .get(
          nameUrl,
          headers: {
            'User-Agent':
                'GeoTWApp/1.0 (com.ks.geotw;)',
            'Accept-Language': 'zh-TW,zh;q=0.9,en;q=0.8',
          },
        )
        .timeout(const Duration(seconds: 10));
    final geoResponse = await http
        .get(geoUrl)
        .timeout(const Duration(seconds: 10));
    print(nameResponse.statusCode);
    if (nameResponse.statusCode == 200) {
      final decodedString = utf8.decode(nameResponse.bodyBytes);
      final cleanedString = decodedString.replaceAll(RegExp(r' {2,}'), ' ');
      nameData = json.decode(cleanedString);
    }
    if (geoResponse.statusCode == 200) {
      final decodedString = utf8.decode(geoResponse.bodyBytes);
      final cleanedString = decodedString.replaceAll(RegExp(r' {2,}'), ' ');
      geoData = json.decode(cleanedString);
      parsedGeoData = _buildGeologyInfo(geoData?['tooltip']);
    }
    setState(() {
      print(nameData);
      _currentAreaName = nameData?['name'] ?? '未知';
      _currentEpochName = parsedGeoData?['地質年代']?.split("(").first ?? '未知';
      _currentRockName = parsedGeoData?['地層名稱']?.split("(").first ?? '未知';
      _currentRockType = parsedGeoData?['地層組成']?.split("(").first ?? '未知';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Geo TW',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF8E44AD),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Location
              _buildCard(
                child: Column(
                  children: [
                    Text(
                      _currentAreaName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5DADE2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '地質區域',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                fillColor: const Color(0xff040f4d),
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              const SizedBox(height: 16),

              // Geological Epoch & Rock Type
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      child: Column(
                        children: [
                          Text(
                            _currentEpochName,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 25, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '地質年代',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      fillColor: const Color(0xff040f4d),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      child: Column(
                        children: [
                          Text(
                            _currentRockName,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 25, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '地層名稱',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      fillColor: const Color(0xff040f4d),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rock Composition
              _buildCard(
                child: Column(
                  children: [
                    Text(
                      _currentRockType,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '岩石種類',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                fillColor: const Color(0xff040f4d),

                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              const SizedBox(height: 16),

              // Coordinates & Elevation
              ValueListenableBuilder<Position?>(
                valueListenable: currentPositionNotifier,
                builder: (context, position, child) {
                  final lat = position != null
                      ? '${position.latitude.toStringAsFixed(6)}N'
                      : '...';
                  final lng = position != null
                      ? '${position.longitude.toStringAsFixed(6)}E'
                      : '...';
                  final alt = position != null
                      ? '${position.altitude.toStringAsFixed(0)}m'
                      : '...';
                  final currentPos = LatLng(
                    position!.latitude,
                    position.longitude,
                  );
                  int timeNow = DateTime.now().millisecondsSinceEpoch;
                  if (distance.as(LengthUnit.Meter, currentPos, _lastPosition) >
                      50 && timeNow - _lastUpdateTime > 1000) {
                    _lastUpdateTime = timeNow;
                    _fetchCurrentArea(
                      LatLng(position.latitude, position.longitude),
                    );
                    _lastPosition = currentPos;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          fillColor: const Color(0xff040f4d),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                lat,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lng,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'GPS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCard(
                          fillColor: const Color(0xff040f4d),
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                alt,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '海拔',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Action Buttons / Tools
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MapPage(),
                          ),
                        );
                      },
                      fillColor: const Color(0xff808080),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.map, color: Colors.white),
                          ),
                          Text(
                            '地質圖',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      onTap: () {
                        //TODO: add clino
                      },
                      fillColor: const Color(0xff808080),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.map, color: Colors.white),
                          ),
                          Text(
                            '傾斜儀',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    VoidCallback? onTap,
    Color fillColor = const Color(0xFF7F8C8D),
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
