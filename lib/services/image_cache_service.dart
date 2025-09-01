import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ImageCacheService handles in-memory + persistent caching of images with LRU eviction.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // In-memory cache
  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _timestamps = {};
  final Map<String, int> _sizes = {};

  // Limits (tweakable)
  static const int _maxEntries = 50;
  static const int _maxBytes = 20 * 1024 * 1024; // 20 MB
  int _currentBytes = 0;

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistent();
    _initialized = true;
  }

  Future<void> _loadPersistent() async {
    if (_prefs == null) return;
    try {
      final dataRaw = _prefs!.getString('image_cache_data');
      final metaRaw = _prefs!.getString('image_cache_meta');
      if (dataRaw == null || metaRaw == null) return;

      final Map<String, String> encoded = Map<String, String>.from(json.decode(dataRaw));
      final Map<String, dynamic> meta = json.decode(metaRaw);

      encoded.forEach((key, b64) {
        final bytes = base64Decode(b64);
        _memoryCache[key] = bytes;
        _sizes[key] = bytes.length;
      });
      meta.forEach((key, value) {
        _timestamps[key] = DateTime.parse(value as String);
      });
      _currentBytes = _sizes.values.fold(0, (p, c) => p + c);
      _enforceLimits();
      debugPrint('ImageCacheService: loaded ${_memoryCache.length} images');
    } catch (e) {
      debugPrint('ImageCacheService: load error $e');
    }
  }

  Future<void> _savePersistent() async {
    if (_prefs == null) return;
    try {
      final encoded = _memoryCache.map((k, v) => MapEntry(k, base64Encode(v)));
      final meta = _timestamps.map((k, v) => MapEntry(k, v.toIso8601String()));
      await _prefs!.setString('image_cache_data', json.encode(encoded));
      await _prefs!.setString('image_cache_meta', json.encode(meta));
    } catch (e) {
      debugPrint('ImageCacheService: save error $e');
    }
  }

  Future<ImageProvider?> getImage(String url) async {
    await initialize();
    if (_memoryCache.containsKey(url)) {
      _timestamps[url] = DateTime.now();
      return MemoryImage(_memoryCache[url]!);
    }
    return null;
  }

  Future<void> cacheImage(String url, Uint8List bytes) async {
    await initialize();
    final size = bytes.length;
    if (size > _maxBytes) return; // skip huge images

    _memoryCache[url] = bytes;
    _sizes[url] = size;
    _timestamps[url] = DateTime.now();
    _currentBytes += size;

    await _enforceLimits();
    await _savePersistent();
  }

  Future<void> _enforceLimits() async {
    // by count
    while (_memoryCache.length > _maxEntries) {
      final lru = _leastRecentlyUsed();
      if (lru == null) break;
      _remove(lru);
    }
    // by bytes
    while (_currentBytes > _maxBytes) {
      final lru = _leastRecentlyUsed();
      if (lru == null) break;
      _remove(lru);
    }
  }

  String? _leastRecentlyUsed() {
    if (_timestamps.isEmpty) return null;
    return _timestamps.entries.reduce((a, b) => a.value.isBefore(b.value) ? a : b).key;
  }

  void _remove(String key) {
    _currentBytes -= _sizes[key] ?? 0;
    _memoryCache.remove(key);
    _sizes.remove(key);
    _timestamps.remove(key);
  }

  Future<void> clearCache() async {
    _memoryCache.clear();
    _sizes.clear();
    _timestamps.clear();
    _currentBytes = 0;
    await _savePersistent();
  }

  // For debugging
  Map<String, dynamic> stats() => {
        'entries': _memoryCache.length,
        'bytes': _currentBytes,
        'maxBytes': _maxBytes,
        'maxEntries': _maxEntries,
      };

  /// Helper widget that fetches & caches image transparently.
  static Widget cachedNetworkImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    double? width,
    double? height,
  }) {
    return _CachedImage(
      imageUrl: url,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      width: width,
      height: height,
    );
  }
}

class _CachedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  const _CachedImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  State<_CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<_CachedImage> {
  ImageProvider? _provider;
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ImageCacheService();
    final cached = await svc.getImage(widget.imageUrl);
    if (cached != null) {
      setState(() => _provider = cached);
      return;
    }
    try {
      final bytes = await NetworkAssetBundle(Uri.parse(widget.imageUrl)).load(widget.imageUrl);
      await svc.cacheImage(widget.imageUrl, bytes.buffer.asUint8List());
      setState(() => _provider = MemoryImage(bytes.buffer.asUint8List()));
    } catch (e) {
      debugPrint('CachedImage error: $e');
      setState(() => _errored = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_provider != null) {
      return Image(
        image: _provider!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
      );
    }
    if (_errored) {
      return widget.errorWidget ?? const Icon(Icons.broken_image);
    }
    return widget.placeholder ?? const Center(child: CircularProgressIndicator());
  }
}
