import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:twgeo/service/location.dart';
import 'package:twgeo/service/coordinate.dart';
import 'package:twgeo/service/offlineTile.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        cancelPreviousAnimations: true,
      );
  late final MapController _mapController =
      _animatedMapController.mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Map<String, dynamic>? _geologyData;
  Map<String, dynamic>? _attitudeData;
  bool _isLoading = false;
  double _sheetExtent = 0.0;
  bool _isSheetVisible = false;
  bool _showInfoPointer = false;
  LatLng _infoPoint = LatLng(0, 0);
  bool _isMapReady = false;
  double _compassAngle = 0.0;
  double? _accuracy;
  StreamSubscription<CompassEvent?>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        _accuracy = event.accuracy;
        final heading = event.heading;
        if (heading != null) {
          _compassAngle = heading;
        }
      });
    });

    // Track panel extent to fade in/out top controls and trigger full-screen UI
    _sheetController.addListener(() {
      final double currentSize = _sheetController.size;
      setState(() {
        _sheetExtent = currentSize;
      });

      if (currentSize <= 0.01 && _isSheetVisible) {
        setState(() {
          _isSheetVisible = false;
          _showInfoPointer = false;
        });
      } else if (currentSize > 0.01 && !_isSheetVisible) {
        setState(() {
          _isSheetVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _animatedMapController.dispose();
    _mapController.dispose();
    _compassSubscription?.cancel();
    super.dispose();
  }

  /// Send request to backend tile/data server on map tap
  Future<void> _fetchGeologyData(LatLng point) async {
    setState(() {
      _isLoading = true;
      _geologyData = null;
      _showInfoPointer = true;
      _infoPoint = point;
    });

    // Open panel to partial height while loading
    _sheetController.animateTo(
      0.35,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    try {
      // Replace with your server URL
      print(point);
      final zoom = _mapController.camera.zoom;
      final convertedPoint = TaiwanGeoConverter.wgs84ToTwd97(point: point);
      print(convertedPoint);
      final url = Uri.parse(
        "https://geomap.gsmma.gov.tw/api/Tile/v1/getTooltip.cfm?layer=TYPE3&srs=EPSG%3A3857&z=${zoom.toStringAsFixed(0)}&x=${convertedPoint.x.toStringAsFixed(0)}&y=${convertedPoint.y.toStringAsFixed(0)}",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final url2 = Uri.parse(
        "https://geomap.gsmma.gov.tw/api/Tile/v1/getTooltip.cfm?layer=CGS_MAP_DIP_STRIKE&srs=EPSG%3A3857&z=${zoom.toStringAsFixed(0)}&x=${convertedPoint.x.toStringAsFixed(0)}&y=${convertedPoint.y.toStringAsFixed(0)}",
      );
      final response2 = await http
          .get(url2)
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic>? geologyResult;
      Map<String, dynamic>? attitudeResult;
      if (response.statusCode == 200) {
        final decodedString = utf8.decode(response.bodyBytes);
        final cleanedString = decodedString.replaceAll(RegExp(r' {2,}'), ' ');
        final Map<String, dynamic> data = json.decode(cleanedString);
        geologyResult = data;
      }
      if (response2.statusCode == 200) {
        final decodedString = utf8.decode(response2.bodyBytes);
        final cleanedString = decodedString
            .replaceAll(RegExp(r' {2,}'), ' ')
            .replaceAll(RegExp(r'\n'), '')
            .replaceAll(RegExp(r'\\\\n'), '\\n')
            .replaceAll(RegExp(r'傾斜:'), '\\n傾斜:')
            .replaceAll(RegExp(r': '), '：');
        final Map<String, dynamic> data = json.decode(cleanedString);
        attitudeResult = data;
      }
      setState(() {
        _geologyData = geologyResult;
        _attitudeData = attitudeResult;
      });
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
    final accuracyText = (_accuracy == null)
        ? "不可用"
        : (_accuracy == 45)
        ? "低"
        : (_accuracy == 30)
        ? "中"
        : "高";
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
                  initialZoom: 12.0,
                  maxZoom: 17.0,
                  minZoom: 7.0,
                  onTap: (tapPosition, point) => _fetchGeologyData(point),
                  onMapReady: () {
                    setState(() {
                      _isMapReady = true;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    tileUpdateTransformer: TileUpdateTransformers.throttle(
                      const Duration(milliseconds: 300),
                    ),
                    userAgentPackageName: 'com.ks.geotw',
                  ),
                  Opacity(
                    opacity: 0.6,
                    child: TileLayer(
                      urlTemplate:
                          'https://geomap.gsmma.gov.tw/api/Tile/v1/getTile.cfm?layer=CGS_CGS_MAP&z={z}&x={x}&y={y}',
                      tileProvider: OfflineTileProvider(),
                      tileUpdateTransformer: TileUpdateTransformers.debounce(
                        const Duration(milliseconds: 500),
                      ),
                      userAgentPackageName: 'com.ks.geotw',
                    ),
                  ),
                  Opacity(
                    opacity: 0.6,
                    child: TileLayer(
                      urlTemplate:
                          'https://geomap.gsmma.gov.tw/api/Tile/v1/getTile.cfm?layer=CGS_MAP_DIP_STRIKE&z={z}&x={x}&y={y}',
                      tileProvider: OfflineTileProvider(),
                      tileUpdateTransformer: TileUpdateTransformers.debounce(
                        const Duration(milliseconds: 500),
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
                  if (_showInfoPointer)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _infoPoint,
                          alignment: Alignment(-0.7, -2),
                          child: Icon(Icons.location_pin, size: 50),
                        ),
                      ],
                    ),
                ],
              ),
              if (_isMapReady && position != null)
                // heading line
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HeadingLinePainter(
                        userLocation: currentLatLng,
                        headingDegrees: _compassAngle,
                        camera: _mapController.camera,
                      ),
                    ),
                  ),
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
                        _animatedMapController.animateTo(
                          dest: LatLng(position.latitude, position.longitude),
                          zoom: 16.0,
                          rotation: 0.0,
                        );
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ),

              if (_isMapReady)
                Positioned(
                  top: 60,
                  right: 24,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _mapController.camera.rotation == 0.0 ? 0.0 : 1.0,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF8E44AD),
                      onPressed: () {
                        if (position != null) {
                          _animatedMapController.animatedRotateTo(0.0);
                        }
                      },
                      child: Transform.rotate(
                        angle: _mapController.camera.rotation * pi / 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.navigation,
                              color: Colors.white,
                            ),
                            Transform.rotate(angle: -_mapController.camera.rotation * pi / 180,child: const Text("N"))
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_accuracy == null || _accuracy! > 15)
                Positioned(
                  top: 60,
                  left: 80,
                  right: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '指北針精準度 $accuracyText，請校準',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

              Positioned(
                bottom: 5,
                left: 5,
                child: SafeArea(
                  child: Text(
                    "© OpenStreetMap contributors\n經濟部地質調查與礦業管理中心",
                    style: TextStyle(color: Colors.black),
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
                              ..._buildGeologyContent(
                                _geologyData!["tooltip"],
                                _attitudeData!["tooltip"],
                              )
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
  List<Widget> _buildGeologyContent(String tooltipText1, String tooltipText2) {
    List<String> lines2 = [];
    if (tooltipText2 != "") {
      lines2 = tooltipText2.split("\n").sublist(1);
    }
    final lines1 = tooltipText1.split('\n');
    Padding _buildTitle(String title) {
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
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      );
    }

    final line1List = lines1.map((line) {
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

    final line2List = <Widget>[];
    for (final line in lines2) {
      final parts = line.split('：');
      final title = parts.first;
      final body = parts.length > 1 ? parts.sublist(1).join('：') : '';
      if (body.isEmpty) continue;
      line2List.add(
        Padding(
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
        ),
      );
    }

    return [
      _buildTitle("地層資訊"),
      ...line1List,
      _buildTitle("位態資訊"),
      ...line2List,
    ];
  }
}

class HeadingLinePainter extends CustomPainter {
  final LatLng userLocation;
  final double headingDegrees;
  final MapCamera camera;

  HeadingLinePainter({
    required this.userLocation,
    required this.headingDegrees,
    required this.camera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final point = camera.latLngToScreenOffset(userLocation);
    final startOffset = Offset(point.dx.toDouble(), point.dy.toDouble());

    final double screenAngleDegrees = headingDegrees + camera.rotation;
    final double radians = (screenAngleDegrees - 90) * (pi / 180.0);
    final double vx = cos(radians);
    final double vy = sin(radians);

    double minT = double.infinity;

    if (vx > 0) {
      final t = (size.width - startOffset.dx) / vx;
      final y = startOffset.dy + t * vy;
      if (t > 0 && y >= 0 && y <= size.height) {
        minT = min(minT, t);
      }
    }
    if (vx < 0) {
      final t = (0 - startOffset.dx) / vx;
      final y = startOffset.dy + t * vy;
      if (t > 0 && y >= 0 && y <= size.height) {
        minT = min(minT, t);
      }
    }
    if (vy > 0) {
      final t = (size.height - startOffset.dy) / vy;
      final x = startOffset.dx + t * vx;
      if (t > 0 && x >= 0 && x <= size.width) {
        minT = min(minT, t);
      }
    }
    if (vy < 0) {
      final t = (0 - startOffset.dy) / vy;
      final x = startOffset.dx + t * vx;
      if (t > 0 && x >= 0 && x <= size.width) {
        minT = min(minT, t);
      }
    }

    if (minT == double.infinity) return;

    final endOffset = Offset(
      startOffset.dx + minT * vx,
      startOffset.dy + minT * vy,
    );

    canvas.drawLine(startOffset, endOffset, paint);
  }

  @override
  bool shouldRepaint(covariant HeadingLinePainter oldDelegate) {
    return oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.userLocation != userLocation ||
        oldDelegate.camera != camera;
  }
}
