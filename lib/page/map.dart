import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:twgeo/service/location.dart';
import 'package:twgeo/service/coordinate.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Map<String, dynamic>? _geologyData;
  bool _isLoading = false;
  double _sheetExtent = 0.0;

  @override
  void initState() {
    super.initState();
    // Track panel extent to fade in/out top controls and trigger full-screen UI
    _sheetController.addListener(() {
      setState(() {
        _sheetExtent = _sheetController.size;
      });
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// Send request to backend tile/data server on map tap
  Future<void> _fetchGeologyData(LatLng point) async {
    setState(() {
      _isLoading = true;
      _geologyData = null;
    });

    // Open panel to partial height while loading
    _sheetController.animateTo(
      0.35,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    try {
      // Replace with your server URL
      final convertedPoint = TaiwanGeoConverter.wgs84ToTwd97(point: point);
      final url = Uri.parse(
        "https://geomap.gsmma.gov.tw/api/Tile/v1/getTooltip.cfm?layer=TYPE3&srs=EPSG%3A3857&z=12&x=${convertedPoint.x.toStringAsFixed(0)}&y=${convertedPoint.y.toStringAsFixed(0)}",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedString = utf8.decode(response.bodyBytes);
        final cleanedString = decodedString.replaceAll(RegExp(r' {2,}'), ' ');
        final Map<String, dynamic> data = json.decode(cleanedString);
        setState(() {
          _geologyData = data;
        });
      }
    } catch (e) {
      // error handling
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFullScreen = _sheetExtent > 0.92;
    return Scaffold(
      body: ValueListenableBuilder<Position?>(
        valueListenable: currentPositionNotifier,
        builder: (context, position, child) {
          final currentLatLng = position != null
              ? LatLng(position.latitude, position.longitude)
              : const LatLng(25.0330, 121.5654); // Default to Taipei
          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: (position != null
                      ? currentLatLng
                      : const LatLng(25.0330, 121.5654)),
                  initialZoom: 13.0,
                  maxZoom: 17.0,
                  minZoom: 7.0,
                  onTap: (tapPosition, point) => _fetchGeologyData(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ks.geotw',
                  ),
                  Opacity(
                    opacity: 0.6,
                    child: TileLayer(
                      urlTemplate:
                          'https://geomap.gsmma.gov.tw/api/Tile/v1/getTile.cfm?layer=CGS_CGS_MAP&z={z}&x={x}&y={y}',
                      tileProvider: NetworkTileProvider(
                        cachingProvider:
                            BuiltInMapCachingProvider.getOrCreateInstance(
                              overrideFreshAge: const Duration(
                                days: 7,
                              ), // Forces a valid cache age
                            ),
                      ),
                      userAgentPackageName: 'com.ks.geotw',
                    ),
                  ),
                  if (position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 40,
                          height: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.blueAccent[100],
                                size: 35,
                              ),
                              Icon(Icons.circle, color: Colors.white, size: 20),
                              Icon(
                                Icons.circle,
                                color: Colors.blueAccent,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Floating Action Button (Recenter GPS)
              Positioned(
                bottom: 24,
                right: 24,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _sheetExtent > 0.1 ? 0.0 : 1.0,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF8E44AD),
                    onPressed: () {
                      if (position != null) {
                        _mapController.move(
                          LatLng(position.latitude, position.longitude),
                          16.0,
                        );
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ),

              // Top Left Circular Back Button
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isFullScreen ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: isFullScreen,
                        child: Material(
                          color: const Color(0xFF8E44AD),
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable Bottom Sheet
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.0,
                minChildSize: 0.0,
                maxChildSize: 1.0,
                snap: true,
                snapSizes: const [0.35, 1.0],
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF252526),
                      borderRadius: isFullScreen
                          ? BorderRadius.zero
                          : const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          children: [
                            // Drag Handle Indicator
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF8E44AD),
                                  ),
                                ),
                              )
                            else if (_geologyData != null)
                              ..._buildGeologyContent(_geologyData!["tooltip"])
                            else
                              const Text(
                                '點擊地圖以查詢地質資料',
                                style: TextStyle(color: Colors.white70),
                              ),
                          ],
                        ),

                        // Full Screen Mode: Fade-in Collapse Button
                        if (isFullScreen)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isFullScreen ? 1.0 : 0.0,
                                  child: Material(
                                    color: const Color(0xFF8E44AD),
                                    shape: const CircleBorder(),
                                    elevation: 4,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () {
                                        // Slide back to initial partial position
                                        _sheetController.animateTo(
                                          0.35,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Helper to format raw tooltip string into structured UI tiles
  List<Widget> _buildGeologyContent(String tooltipText) {
    final lines = tooltipText.split('\n');
    return lines.map((line) {
      final parts = line.split('：');
      final title = parts.first;
      final body = parts.length > 1 ? parts.sublist(1).join('：') : '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF8E44AD),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              body.isNotEmpty ? body : line,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const Divider(color: Color(0xFF3F3F46), height: 16),
          ],
        ),
      );
    }).toList();
  }
}
