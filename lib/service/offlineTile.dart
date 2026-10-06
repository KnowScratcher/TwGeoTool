import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class OfflineTileProvider extends TileProvider {
  final http.Client _client = http.Client();
  Directory? _cacheDir;

  OfflineTileProvider() {
    _initCacheDir();
  }

  Future<void> _initCacheDir() async {
    final docs = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(p.join(docs.path, 'map_tile_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final String url = getTileUrl(coordinates, options);
    return CustomOfflineTileImage(
      url: url,
      client: _client,
      cacheDirGetter: () async {
        if (_cacheDir == null) await _initCacheDir();
        return _cacheDir!;
      },
    );
  }
}

class CustomOfflineTileImage extends ImageProvider<CustomOfflineTileImage> {
  final String url;
  final http.Client client;
  final Future<Directory> Function() cacheDirGetter;

  CustomOfflineTileImage({
    required this.url,
    required this.client,
    required this.cacheDirGetter,
  });

  @override
  Future<CustomOfflineTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CustomOfflineTileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      CustomOfflineTileImage key,
      ImageDecoderCallback decode,
      ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadTileBytes(decode),
      scale: 1.0,
      debugLabel: url,
    );
  }

  Future<Codec> _loadTileBytes(ImageDecoderCallback decode) async {
    final Directory cacheDir = await cacheDirGetter();

    // Create a unique local file path for this tile URL
    final String fileName = '${url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png';
    final File cachedFile = File(p.join(cacheDir.path, fileName));

    // 1. Check if tile already exists in local disk cache (Offline Mode)
    if (await cachedFile.exists()) {
      final bytes = await cachedFile.readAsBytes();
      final buffer = await ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    }

    // 2. Download from network if not cached
    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        // Save tile directly to disk for offline access
        await cachedFile.writeAsBytes(bytes);

        final buffer = await ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // If network fails (Device is Offline) and no cache exists
      throw Exception('Tile offline error: $e');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CustomOfflineTileImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}