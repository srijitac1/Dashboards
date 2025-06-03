import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/insight_model.dart';

class CacheService extends ChangeNotifier {
  static const String _cachePrefix = 'cache_';
  static const Duration _defaultExpiry = Duration(hours: 24);
  
  final Map<String, _CacheEntry> _memoryCache = {};
  Timer? _cleanupTimer;

  CacheService() {
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _cleanupExpiredCache();
    });
  }

  Future<void> _cleanupExpiredCache() async {
    final now = DateTime.now();
    _memoryCache.removeWhere((key, entry) => entry.expiry.isBefore(now));
    notifyListeners();
  }

  Future<void> setCache(String key, dynamic value, {Duration? expiry}) async {
    final entry = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(expiry ?? _defaultExpiry),
    );
    
    _memoryCache[key] = entry;
    
    // Also persist to disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_cachePrefix$key',
      jsonEncode({
        'value': value,
        'expiry': entry.expiry.toIso8601String(),
      }),
    );
    
    notifyListeners();
  }

  Future<T?> getCache<T>(String key) async {
    // Check memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null) {
      if (memoryEntry.expiry.isAfter(DateTime.now())) {
        return memoryEntry.value as T;
      } else {
        _memoryCache.remove(key);
      }
    }

    // Check disk cache
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('$_cachePrefix$key');
    
    if (cachedData != null) {
      final decoded = jsonDecode(cachedData);
      final expiry = DateTime.parse(decoded['expiry']);
      
      if (expiry.isAfter(DateTime.now())) {
        final value = decoded['value'];
        // Update memory cache
        _memoryCache[key] = _CacheEntry(
          value: value,
          expiry: expiry,
        );
        return value as T;
      } else {
        // Remove expired cache
        await prefs.remove('$_cachePrefix$key');
      }
    }
    
    return null;
  }

  Future<void> removeCache(String key) async {
    _memoryCache.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
    notifyListeners();
  }

  Future<void> clearCache() async {
    _memoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await prefs.remove(key);
      }
    }
    notifyListeners();
  }

  Future<void> preloadCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final insightsJson = prefs.getStringList('insights_$category') ?? [];
    
    for (final json in insightsJson) {
      final insight = Insight.fromJson(jsonDecode(json));
      await setCache(
        'insight_${insight.id}',
        insight,
        expiry: const Duration(days: 7),
      );
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiry;

  _CacheEntry({
    required this.value,
    required this.expiry,
  });
} 