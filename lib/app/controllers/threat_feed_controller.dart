// lib/app/controllers/threat_feed_controller.dart
//
// Coordinates NVD threat feed loading, filters, search, pagination, and
// user-facing error state for the dashboard screen.

import 'package:get/get.dart';

import '../models/threat_advisory.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

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

  @override
  void onInit() {
    super.onInit();
    fetchThreats(refresh: true);
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
      final results = await _apiService.fetchThreats(
        page: 0,
        keyword: searchKeyword.value,
        severity: selectedSeverity.value,
      );

      threats.assignAll(results);
      currentPage.value = 0;
      hasMorePages.value = results.length == AppStrings.nvdResultsPerPage;

      if (_apiService.errorMessage.isNotEmpty) {
        errorMessage.value = _apiService.errorMessage;
      }
    } catch (_) {
      errorMessage.value =
          'Could not load threat intelligence. Please try again.';
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
      currentPage.value = nextPage;
      hasMorePages.value = results.length == AppStrings.nvdResultsPerPage;
    } catch (_) {
      errorMessage.value = 'Could not load more threats. Please try again.';
    } finally {
      isLoadingMore.value = false;
    }
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
}
