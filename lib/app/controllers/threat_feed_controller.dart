// lib/app/controllers/threat_feed_controller.dart
//
// Coordinates NVD threat feed loading, filters, search, pagination, and
// user-facing error state for the dashboard screen.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../models/threat_advisory.dart';
import '../services/api_service.dart';

class ThreatFeedController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final List<ThreatAdvisory> _allThreats = <ThreatAdvisory>[];
  int _fetchGeneration = 0;

  RxList<ThreatAdvisory> threats = <ThreatAdvisory>[].obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxString errorMessage = ''.obs;
  RxString selectedSeverity = ''.obs;
  RxString searchKeyword = ''.obs;
  RxInt currentPage = 0.obs;
  RxBool hasMorePages = true.obs;
  RxBool isOffline = false.obs;
  RxBool isShowingCachedData = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await _watchConnectivity();
    await fetchThreats(refresh: true);
  }

  // -- Initial and refreshed loading --
  Future<void> fetchThreats({
    bool refresh = false,
    bool useRemoteSeverity = false,
  }) async {
    final generation = ++_fetchGeneration;
    final shouldUseRemoteSeverity =
        useRemoteSeverity || selectedSeverity.value.isNotEmpty;
    errorMessage.value = '';
    isLoading.value = true;

    if (refresh) {
      currentPage.value = 0;
      hasMorePages.value = true;
    }

    try {
      final cachedThreats = _cachedThreatsForCurrentState(
        useRemoteSeverity: shouldUseRemoteSeverity,
      );
      if (isOffline.value) {
        if (cachedThreats.isNotEmpty) {
          _showCachedThreats(cachedThreats);
        } else {
          _allThreats.clear();
          threats.clear();
          hasMorePages.value = false;
          errorMessage.value = '';
          isShowingCachedData.value = false;
        }
        return;
      }

      final results = await _apiService.fetchThreats(
        page: 0,
        severity: shouldUseRemoteSeverity ? selectedSeverity.value : null,
      );

      if (generation != _fetchGeneration) return;

      if (_apiService.errorMessage.isNotEmpty) {
        if (cachedThreats.isNotEmpty) {
          _showCachedThreats(cachedThreats);
          return;
        }

        errorMessage.value = _apiService.errorMessage;
        isShowingCachedData.value = false;
        return;
      }

      _allThreats
        ..clear()
        ..addAll(_newestFirst(results));
      _applyFiltersToLoadedThreats();
      currentPage.value = 0;
      hasMorePages.value = _apiService.hasMoreThreatPages;
      isShowingCachedData.value = false;
    } catch (_) {
      final cachedThreats = _cachedThreatsForCurrentState(
        useRemoteSeverity: shouldUseRemoteSeverity,
      );
      if (cachedThreats.isNotEmpty) {
        _showCachedThreats(cachedThreats);
      } else {
        errorMessage.value =
            'Could not load threat intelligence. Please try again.';
        isShowingCachedData.value = false;
      }
    } finally {
      if (generation == _fetchGeneration) {
        isLoading.value = false;
      }
    }
  }

  // -- Infinite scrolling --
  Future<void> loadMoreThreats() async {
    errorMessage.value = '';

    if (isLoading.value || isLoadingMore.value || !hasMorePages.value) {
      return;
    }

    if (isOffline.value || isShowingCachedData.value) {
      return;
    }

    isLoadingMore.value = true;

    try {
      final nextPage = currentPage.value + 1;
      final results = await _apiService.fetchThreats(
        page: nextPage,
        severity:
            selectedSeverity.value.isEmpty ? null : selectedSeverity.value,
      );

      if (_apiService.errorMessage.isNotEmpty) {
        errorMessage.value = _apiService.errorMessage;
        return;
      }

      _allThreats
        ..addAll(results)
        ..replaceRange(0, _allThreats.length, _dedupeNewestFirst(_allThreats));
      _applyFiltersToLoadedThreats();
      currentPage.value = nextPage;
      hasMorePages.value = _apiService.hasMoreThreatPages;
    } catch (_) {
      errorMessage.value = 'Could not load more threats. Please try again.';
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _watchConnectivity() async {
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    _updateOfflineState(initial);
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(_updateOfflineState);
  }

  void _updateOfflineState(List<ConnectivityResult> results) {
    isOffline.value = results.contains(ConnectivityResult.none);
  }

  void _showCachedThreats(List<ThreatAdvisory> cachedThreats) {
    _allThreats
      ..clear()
      ..addAll(_newestFirst(cachedThreats));
    _applyFiltersToLoadedThreats();
    currentPage.value = 0;
    hasMorePages.value = false;
    errorMessage.value = '';
    isShowingCachedData.value = true;
  }

  List<ThreatAdvisory> _cachedThreatsForCurrentState({
    required bool useRemoteSeverity,
  }) {
    if (useRemoteSeverity && selectedSeverity.value.isNotEmpty) {
      final severityCacheKey = _apiService.buildThreatCacheKey(
        page: 0,
        severity: selectedSeverity.value,
      );
      final severityCache = _apiService.getCachedThreats(severityCacheKey);
      if (severityCache.isNotEmpty) return severityCache;
    }

    final baseCacheKey = _apiService.buildThreatCacheKey(page: 0);
    return _apiService.getCachedThreats(baseCacheKey);
  }

  void _applyFiltersToLoadedThreats() {
    threats.assignAll(_filteredThreats(_allThreats));
  }

  List<ThreatAdvisory> _filteredThreats(List<ThreatAdvisory> source) {
    Iterable<ThreatAdvisory> results = source;

    final severity = selectedSeverity.value.trim().toUpperCase();
    if (severity.isNotEmpty) {
      results = results.where(
        (threat) => threat.severity.toUpperCase() == severity,
      );
    }

    final keyword = searchKeyword.value.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      results = results.where((threat) {
        return threat.id.toLowerCase().contains(keyword) ||
            threat.description.toLowerCase().contains(keyword) ||
            threat.severity.toLowerCase().contains(keyword);
      });
    }

    return _newestFirst(results);
  }

  // -- Filtering and search --
  Future<void> filterBySeverity(String severity) async {
    errorMessage.value = '';
    selectedSeverity.value = severity.toUpperCase() == 'ALL' ? '' : severity;
    _applyFiltersToLoadedThreats();
    await fetchThreats(
      refresh: true,
      useRemoteSeverity: selectedSeverity.value.isNotEmpty,
    );
  }

  Future<void> search(String keyword) async {
    errorMessage.value = '';
    searchKeyword.value = keyword.trim();
    _applyFiltersToLoadedThreats();
  }

  Future<void> clearFilters() async {
    errorMessage.value = '';
    selectedSeverity.value = '';
    searchKeyword.value = '';
    _applyFiltersToLoadedThreats();
    await fetchThreats(refresh: true);
  }

  List<ThreatAdvisory> _newestFirst(Iterable<ThreatAdvisory> items) {
    return items.toList()
      ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
  }

  List<ThreatAdvisory> _dedupeNewestFirst(Iterable<ThreatAdvisory> items) {
    final byId = <String, ThreatAdvisory>{};
    for (final item in _newestFirst(items)) {
      byId.putIfAbsent(item.id, () => item);
    }
    return byId.values.toList();
  }
}
