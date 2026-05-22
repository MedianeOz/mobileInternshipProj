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
  Future<void> fetchThreats({bool refresh = false}) async {
    errorMessage.value = '';
    isLoading.value = true;

    if (refresh) {
      currentPage.value = 0;
      hasMorePages.value = true;
    }

    try {
      final cachedThreats = _cachedThreatsForCurrentFilters();
      if (isOffline.value) {
        if (cachedThreats.isNotEmpty) {
          _showCachedThreats(cachedThreats);
        } else {
          threats.clear();
          hasMorePages.value = false;
          errorMessage.value = '';
          isShowingCachedData.value = false;
        }
        return;
      }

      final results = await _apiService.fetchThreats(
        page: 0,
        keyword: searchKeyword.value,
        severity: selectedSeverity.value,
      );

      if (_apiService.errorMessage.isNotEmpty) {
        if (cachedThreats.isNotEmpty) {
          _showCachedThreats(cachedThreats);
          return;
        }

        errorMessage.value = _apiService.errorMessage;
        isShowingCachedData.value = false;
        return;
      }

      threats.assignAll(_newestFirst(results));
      currentPage.value = 0;
      hasMorePages.value = _apiService.hasMoreThreatPages;
      isShowingCachedData.value = false;
    } catch (_) {
      final cachedThreats = _cachedThreatsForCurrentFilters();
      if (cachedThreats.isNotEmpty) {
        _showCachedThreats(cachedThreats);
      } else {
        errorMessage.value =
            'Could not load threat intelligence. Please try again.';
        isShowingCachedData.value = false;
      }
    } finally {
      isLoading.value = false;
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
        keyword: searchKeyword.value,
        severity: selectedSeverity.value,
      );

      if (_apiService.errorMessage.isNotEmpty) {
        errorMessage.value = _apiService.errorMessage;
        return;
      }

      threats.addAll(results);
      threats.assignAll(_newestFirst(threats));
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
    threats.assignAll(_newestFirst(cachedThreats));
    currentPage.value = 0;
    hasMorePages.value = false;
    errorMessage.value = '';
    isShowingCachedData.value = true;
  }

  List<ThreatAdvisory> _cachedThreatsForCurrentFilters() {
    final cacheKey = _apiService.buildThreatCacheKey(
      page: 0,
      keyword: searchKeyword.value,
      severity: selectedSeverity.value,
    );
    final filteredCache = _apiService.getCachedThreats(cacheKey);
    if (filteredCache.isNotEmpty) return filteredCache;

    final baseCacheKey = _apiService.buildThreatCacheKey(page: 0);
    final baseCache = _apiService.getCachedThreats(baseCacheKey);
    return _applyLocalFilters(baseCache);
  }

  List<ThreatAdvisory> _applyLocalFilters(List<ThreatAdvisory> cachedThreats) {
    Iterable<ThreatAdvisory> results = cachedThreats;

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

    return results.toList();
  }

  // -- Filtering and search --
  Future<void> filterBySeverity(String severity) async {
    errorMessage.value = '';
    selectedSeverity.value = severity.toUpperCase() == 'ALL' ? '' : severity;
    await fetchThreats(refresh: true);
  }

  Future<void> search(String keyword) async {
    errorMessage.value = '';
    searchKeyword.value = keyword.trim();
    await fetchThreats(refresh: true);
  }

  Future<void> clearFilters() async {
    errorMessage.value = '';
    selectedSeverity.value = '';
    searchKeyword.value = '';
    await fetchThreats(refresh: true);
  }

  List<ThreatAdvisory> _newestFirst(Iterable<ThreatAdvisory> items) {
    return items.toList()
      ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
  }
}
