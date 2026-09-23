import 'package:flutter/material.dart';

class GeoHomeScreen extends StatelessWidget {
  const GeoHomeScreen({super.key});

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
                    const Text(
                      '台北',
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
                          const Text(
                            '古新世',
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
                          const Text(
                            '沉積岩',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 25, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '岩性',
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
                    const Text(
                      '砂岩、頁岩',
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
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '25.143287N',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '121.328479E',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'GPS',
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '25m',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '海拔',
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
                      padding: const EdgeInsets.symmetric(vertical: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons / Tools
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      onTap: () {
                        print("tap");
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
                        print("tap");
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
            color: Colors.black.withOpacity(0.12),
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
