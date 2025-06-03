import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/network_service.dart';
import '../services/cache_service.dart';
import '../repositories/insight_repository.dart';

class SyncService extends ChangeNotifier {
  final NetworkService _networkService;
  final CacheService _cacheService;
  final InsightRepository _repository;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  SyncService({
    required NetworkService networkService,
    required CacheService cacheService,
    required InsightRepository repository,
  }) : _networkService = networkService,
       _cacheService = cacheService,
       _repository = repository {
    _startSyncTimer();
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (_networkService.isConnected) {
        syncData();
      }
    });
  }

  Future<void> syncData() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      notifyListeners();

      // Get all categories
      final categories = await _repository.getCategories();
      
      // Sync each category
      for (final category in categories) {
        await _syncCategory(category.name);
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Error syncing data: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncCategory(String category) async {
    try {
      // Get insights from repository
      final insights = await _repository.getInsights(category);
      
      // Update cache
      for (final insight in insights) {
        await _cacheService.setCache(
          'insight_${insight.id}',
          insight,
          expiry: const Duration(days: 7),
        );
      }
    } catch (e) {
      debugPrint('Error syncing category $category: $e');
    }
  }

  Future<void> forceSync() async {
    await syncData();
  }

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
} 