// lib/app/controllers/knowledge_controller.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../models/knowledge_article.dart';
import '../services/storage_service.dart';

class KnowledgeController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  RxList<KnowledgeArticle> articles = <KnowledgeArticle>[].obs;
  RxList<KnowledgeArticle> filteredArticles = <KnowledgeArticle>[].obs;
  RxString selectedCategory = 'All'.obs;
  RxString searchQuery = ''.obs;
  RxBool isLoading = false.obs;
  RxSet<String> bookmarkedIds = <String>{}.obs;
  RxBool showBookmarksOnly = false.obs;
  RxBool isOffline = false.obs;
  DateTime? lastSyncTime;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  static const categories = [
    'Passwords',
    'Network',
    'Phishing',
    'Mobile',
    'Incident',
  ];

  @override
  void onInit() {
    super.onInit();
    _load();
    _watchConnectivity();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _load() async {
    isLoading.value = true;
    await _storageService.init();

    var cachedArticles = _storageService.getCachedArticles();
    if (cachedArticles.isEmpty) {
      cachedArticles = _storageService.getStaticArticles();
      await _storageService.saveArticles(cachedArticles);
      await _storageService.setLastSyncTime(DateTime.now());
    }

    articles.assignAll(cachedArticles);
    bookmarkedIds.assignAll(_storageService.getBookmarkedIds());
    lastSyncTime = _storageService.getLastSyncTime();
    _applyFilters();
    isLoading.value = false;
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

  void filterByCategory(String category) {
    selectedCategory.value = category;
    showBookmarksOnly.value = false;
    _applyFilters();
  }

  void clearCategory() {
    selectedCategory.value = 'All';
    _applyFilters();
  }

  void search(String query) {
    searchQuery.value = query.trim();
    _applyFilters();
  }

  void toggleBookmarksOnly() {
    showBookmarksOnly.value = !showBookmarksOnly.value;
    if (showBookmarksOnly.value) {
      selectedCategory.value = 'All';
    }
    _applyFilters();
  }

  Future<void> toggleBookmark(String articleId) async {
    await _storageService.toggleBookmark(articleId);
    bookmarkedIds.assignAll(_storageService.getBookmarkedIds());
    _applyFilters();
  }

  int countForCategory(String category) {
    return articles.where((article) => article.category == category).length;
  }

  int get bookmarkCount => bookmarkedIds.length;

  List<KnowledgeArticle> articlesForCategory(String category) {
    return articles.where((article) => article.category == category).toList();
  }

  bool isBookmarked(String articleId) {
    return bookmarkedIds.contains(articleId);
  }

  String get offlineCacheAge {
    final lastSync = lastSyncTime;
    if (lastSync == null) return 'cached just now';
    final hours = DateTime.now().difference(lastSync).inHours;
    if (hours <= 0) return 'cached just now';
    return 'cached ${hours}h ago';
  }

  String get footerSyncAge {
    final lastSync = lastSyncTime;
    if (lastSync == null) return 'Last synced just now';
    final difference = DateTime.now().difference(lastSync);
    if (difference.inHours > 0) {
      return 'Last synced ${difference.inHours}h ago';
    }
    final minutes = difference.inMinutes;
    return 'Last synced ${minutes <= 0 ? 1 : minutes}m ago';
  }

  void _applyFilters() {
    Iterable<KnowledgeArticle> results = articles;

    final category = selectedCategory.value;
    if (category != 'All') {
      results = results.where((article) => article.category == category);
    }

    final query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      results = results.where((article) {
        return article.title.toLowerCase().contains(query) ||
            article.summary.toLowerCase().contains(query) ||
            article.category.toLowerCase().contains(query) ||
            article.content.toLowerCase().contains(query);
      });
    }

    if (showBookmarksOnly.value) {
      results = results.where((article) => bookmarkedIds.contains(article.id));
    }

    filteredArticles.assignAll(results);
  }
}
