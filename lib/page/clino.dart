import 'package:flutter/material.dart';
import 'package:twgeo/service/location.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;

class Clino extends StatefulWidget {
  const Clino({super.key});

  @override
  State<Clino> createState() => _ClinoState();
}

class _ClinoState extends State<Clino> {
  double _smoothedX = 0.0;
  double _smoothedY = 0.0;
  double _smoothedZ = 9.8;
  final double _alpha = 0.2;
  double _compassAngle = 0.0;
  double _angle = 0.0;
  double _dipAngle = 0.0;
  bool _isUpSideDown = false;
  bool _isAbsolute = false;
  double? _accuracy;
  StreamSubscription<CompassEvent?>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

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

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _smoothedX = _alpha * event.x + (1 - _alpha) * _smoothedX;
      _smoothedY = _alpha * event.y + (1 - _alpha) * _smoothedY;
      _smoothedZ = _alpha * event.z + (1 - _alpha) * _smoothedZ;
      final double dipAzimuth = math.atan2(-_smoothedY, -_smoothedX);

      setState(() {
        final double g = math.sqrt(
          _smoothedX * _smoothedX +
              _smoothedY * _smoothedY +
              _smoothedZ * _smoothedZ,
        );
        if (g > 0) {
          final double angleRad = math.acos((_smoothedZ / g).clamp(-1.0, 1.0));
          _dipAngle = 90 - ((90 - angleRad * (180.0 / math.pi)).abs());
          _angle = dipAzimuth;
          _isUpSideDown = _smoothedZ < 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strikeValue = (-(_angle * 180 / math.pi) + _compassAngle + 360) % 360;
    final type = _dipAngle < 2 ? 0 : (!_isUpSideDown ? 1 : 2);
    final accuracyText = (_accuracy == null)
        ? "不可用"
        : (_accuracy == 45)
        ? "低"
        : (_accuracy == 30)
        ? "中"
        : "高";
    final accuracyTextColor = (_accuracy == null)
        ? Colors.redAccent
        : (_accuracy == 45)
        ? Colors.redAccent
        : (_accuracy == 30)
        ? Colors.orange
        : Colors.green;
    return Scaffold(
      appBar: AppBar(
        title: const Text('傾斜儀'),
        backgroundColor: const Color(0xff040f4d),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<Position?>(
        valueListenable: currentPositionNotifier,
        builder: (context, position, child) {
          final currentLatLng = position != null
              ? LatLng(position.latitude, position.longitude)
              : const LatLng(0.0, 0.0); // Default to 0,0
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff040f4d),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '緯度: ${currentLatLng.latitude.toStringAsFixed(6)}${currentLatLng.latitude >= 0 ? "N" : "S"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '經度: ${currentLatLng.longitude.toStringAsFixed(6)}${currentLatLng.longitude >= 0 ? "E" : "W"}',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '指北針準確度: $accuracyText',
                            style: TextStyle(
                              color: accuracyTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[900],
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 4,
                          ),
                        ),
                      ),
                      ...List.generate(72, (index) {
                        final angle = index * math.pi / 36;
                        return Transform.rotate(
                          angle: angle,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 2 + (index % 9 == 0 ? 2 : 0),
                              height: 12 + (index % 9 == 0 ? 5 : 0) - (index % 2 == 1 ? 3 : 0),
                              color: Colors.white70,
                            ),
                          ),
                        );
                      }),
                      if (_isAbsolute)
                        ...List.generate(4, (index) {
                          final angle = index * math.pi / 2;
                          const List<String> directions = ["N", "E", "S", "W"];
                          return Transform.rotate(
                            angle: angle,
                            child: Align(
                              alignment: Alignment(0.0, -0.9),
                              child: Transform.rotate(
                                angle: -angle,
                                child: Text(
                                  directions[index],
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                      Transform.rotate(
                        angle: _dipAngle >= 2
                            ? (_isAbsolute
                                  ? strikeValue / (180 / math.pi)
                                  : -_angle)
                            : 0,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: TSymbolPainter(type: type),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Colors.purple[600]!,
                    ),
                  ),
                  onPressed: () => {
                    setState(() {
                      _isAbsolute = !_isAbsolute;
                    }),
                  }, // TODO: toggle relative & absolute
                  child: Text('切換成${_isAbsolute ? "相對傾角圖" : "絕對傾角圖"}'),
                ),
                const Spacer(),
                if (_accuracy == null || _accuracy! > 30.0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.redAccent,
                    child: const Text(
                      '指北針不精準，請橫向8字形旋轉手機來校準。',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_accuracy == null || _accuracy! > 30.0) const Spacer(),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Strike (RHR): ${strikeValue.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Dip: ${_dipAngle.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TSymbolPainter extends CustomPainter {
  final int type; // 0 for slanted, 1 for flat

  TSymbolPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy - 110),
      Offset(center.dx, center.dy + 110),
      paint,
    );

    if (type == 1) {
      canvas.drawLine(
        Offset(center.dx, center.dy - 110),
        Offset(center.dx - 5, center.dy - 100),
        paint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 110),
        Offset(center.dx + 5, center.dy - 100),
        paint,
      );
      canvas.drawLine(center, Offset(center.dx + 45, center.dy), paint);
    } else if (type == 2) {
      canvas.drawLine(
        Offset(center.dx, center.dy + 110),
        Offset(center.dx - 5, center.dy + 100),
        paint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy + 110),
        Offset(center.dx + 5, center.dy + 100),
        paint,
      );
      canvas.drawLine(center, Offset(center.dx + 45, center.dy), paint);
    } else {
      canvas.drawLine(
        Offset(center.dx - 110, center.dy),
        Offset(center.dx + 110, center.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TSymbolPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
