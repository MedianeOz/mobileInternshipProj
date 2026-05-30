// lib/app/services/api_service.dart
//
// Dio-powered integration layer for NVD threat intelligence and Have I Been
// Pwned password range checks. Network errors are normalized for controllers.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/password_check_result.dart';
import '../models/threat_advisory.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  final Map<String, List<String>> _cpeNameCache = <String, List<String>>{};

  String errorMessage = '';
  bool hasMoreThreatPages = false;
  int lastThreatTotalResults = 0;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 18),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('[API] ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final shouldRetry = error.type == DioExceptionType.connectionError &&
              error.requestOptions.extra['retried'] != true;

          if (!shouldRetry) {
            handler.next(error);
            return;
          }

          try {
            final retryOptions = error.requestOptions;
            retryOptions.extra['retried'] = true;
            final response = await _dio.fetch<dynamic>(retryOptions);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  // -- NVD threat feed --
  Future<List<ThreatAdvisory>> fetchThreats({
    int page = 0,
    String? keyword,
    String? cpeName,
    String? severity,
  }) async {
    errorMessage = '';
    hasMoreThreatPages = false;
    lastThreatTotalResults = 0;

    final publishWindow = _recentPublishWindow();
    final baseQueryParameters = <String, dynamic>{
      'pubStartDate': _formatNvdDate(publishWindow.start),
      'pubEndDate': _formatNvdDate(publishWindow.end),
    };

    final trimmedCpeName = cpeName?.trim();
    final trimmedKeyword = keyword?.trim();
    if (trimmedCpeName != null && trimmedCpeName.isNotEmpty) {
      baseQueryParameters['cpeName'] = trimmedCpeName;
    } else if (trimmedKeyword != null && trimmedKeyword.isNotEmpty) {
      baseQueryParameters['keywordSearch'] = trimmedKeyword;
    }

    final normalizedSeverity = severity?.trim().toUpperCase();
    if (normalizedSeverity != null && normalizedSeverity.isNotEmpty) {
      baseQueryParameters['cvssV3Severity'] = normalizedSeverity;
    }

    try {
      final totalResults = await _fetchThreatCount(baseQueryParameters);
      lastThreatTotalResults = totalResults;

      if (totalResults == 0) {
        return <ThreatAdvisory>[];
      }

      final pageBounds = _newestPageBounds(
        page: page,
        totalResults: totalResults,
      );

      if (pageBounds.count <= 0) {
        return <ThreatAdvisory>[];
      }

      final queryParameters = <String, dynamic>{
        ...baseQueryParameters,
        'resultsPerPage': pageBounds.count,
        'startIndex': pageBounds.startIndex,
      };

      final response = await _dio.get<Map<String, dynamic>>(
        AppStrings.nvdBaseUrl,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'apiKey': AppStrings.nvdApiKey,
          },
        ),
      );

      final vulnerabilities =
          response.data?['vulnerabilities'] as List<dynamic>? ?? <dynamic>[];

      final threats = vulnerabilities
          .map((item) => item is Map<String, dynamic> ? item['cve'] : null)
          .whereType<Map<String, dynamic>>()
          .map(ThreatAdvisory.fromJson)
          .toList()
        ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

      final pageThreats = threats.take(AppStrings.nvdResultsPerPage).toList();

      hasMoreThreatPages = pageBounds.hasMore;

      await _cacheThreats(
        page: page,
        keyword: trimmedKeyword ?? '',
        cpeName: trimmedCpeName ?? '',
        severity: normalizedSeverity ?? '',
        publishStartDate: baseQueryParameters['pubStartDate'].toString(),
        publishEndDate: baseQueryParameters['pubEndDate'].toString(),
        threats: pageThreats,
      );

      return pageThreats;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404 &&
          ((trimmedKeyword != null && trimmedKeyword.isNotEmpty) ||
              (trimmedCpeName != null && trimmedCpeName.isNotEmpty))) {
        return <ThreatAdvisory>[];
      }

      errorMessage = _mapNvdError(error);
      return <ThreatAdvisory>[];
    } catch (_) {
      errorMessage = 'Could not load threat intelligence. Please try again.';
      return <ThreatAdvisory>[];
    }
  }

  List<ThreatAdvisory> getCachedThreats(String cacheKey) {
    final cached = Get.find<StorageService>().getCachedThreatPage(cacheKey);
    return cached.map(ThreatAdvisory.fromCache).toList();
  }

  String buildThreatCacheKey({
    required int page,
    String? keyword,
    String? cpeName,
    String? severity,
  }) {
    final publishWindow = _recentPublishWindow();
    final trimmedKeyword = keyword?.trim() ?? '';
    final trimmedCpeName = cpeName?.trim() ?? '';
    final normalizedSeverity = severity?.trim().toUpperCase() ?? '';

    return _cacheKey(
      page: page,
      keyword: trimmedKeyword,
      cpeName: trimmedCpeName,
      severity: normalizedSeverity,
      publishStartDate: _formatNvdDate(publishWindow.start),
      publishEndDate: _formatNvdDate(publishWindow.end),
    );
  }

  Future<List<String>> resolveCpeNames(
    String keyword, {
    int limit = 1,
  }) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty || limit <= 0) return <String>[];
    final cacheKey = trimmedKeyword.toLowerCase();
    final cached = _cpeNameCache[cacheKey];
    if (cached != null) return cached.take(limit).toList();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppStrings.nvdCpeBaseUrl,
        queryParameters: {
          'keywordSearch': trimmedKeyword,
          'resultsPerPage': 20,
          'startIndex': 0,
        },
        options: Options(
          headers: {
            'apiKey': AppStrings.nvdApiKey,
          },
        ),
      );

      final products =
          response.data?['products'] as List<dynamic>? ?? <dynamic>[];
      final matches = rankedCpeNamesForKeyword(products, trimmedKeyword);
      _cpeNameCache[cacheKey] = matches;
      return matches.take(limit).toList();
    } on DioException catch (_) {
      return <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  @visibleForTesting
  static List<String> rankedCpeNamesForKeyword(
    List<dynamic> products,
    String keyword,
  ) {
    final normalizedKeyword = _normalizeSearchText(keyword);
    if (normalizedKeyword.isEmpty) return <String>[];

    final scored = <_ScoredCpeName>[];
    final seen = <String>{};

    for (final product in products) {
      if (product is! Map<String, dynamic>) continue;
      final cpe = product['cpe'];
      if (cpe is! Map<String, dynamic>) continue;
      if (cpe['deprecated'] == true) continue;

      final cpeName = cpe['cpeName']?.toString().trim() ?? '';
      if (cpeName.isEmpty || !seen.add(cpeName)) continue;

      final titles = cpe['titles'] as List<dynamic>? ?? <dynamic>[];
      final titleText = titles
          .map((title) {
            if (title is! Map<String, dynamic>) return '';
            return title['title']?.toString() ?? '';
          })
          .where((title) => title.trim().isNotEmpty)
          .join(' ');

      final normalizedTitle = _normalizeSearchText(titleText);
      final normalizedCpe = _normalizeSearchText(cpeName);
      var score = 0;

      if (normalizedTitle == normalizedKeyword) score += 80;
      if (normalizedTitle.contains(normalizedKeyword)) score += 45;
      if (normalizedCpe.contains(normalizedKeyword)) score += 25;

      if (score > 0) {
        if (cpeName.startsWith('cpe:2.3:a:')) score += 8;
        if (cpeName.startsWith('cpe:2.3:o:')) score += 6;
        scored.add(_ScoredCpeName(cpeName: cpeName, score: score));
      }
    }

    scored.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      return a.cpeName.length.compareTo(b.cpeName.length);
    });

    return scored.map((item) => item.cpeName).toList();
  }

  // -- HIBP password range check --
  Future<PasswordCheckResult> checkPassword(String password) async {
    errorMessage = '';

    try {
      final digest = sha1.convert(utf8.encode(password));
      final hash = digest.toString().toUpperCase();
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);

      final response = await _dio.get<String>(
        '${AppStrings.hibpBaseUrl}/$prefix',
        options: Options(responseType: ResponseType.plain),
      );

      final lines = (response.data ?? '').split('\n');
      for (final line in lines) {
        final parts = line.trim().split(':');
        if (parts.length != 2) continue;

        if (parts.first.toUpperCase() == suffix) {
          final count = int.tryParse(parts.last) ?? 0;
          return PasswordCheckResult(
            isPwned: true,
            breachCount: count,
          );
        }
      }

      return PasswordCheckResult(
        isPwned: false,
        breachCount: 0,
      );
    } on DioException catch (_) {
      errorMessage = 'Could not connect to breach database. Please try again.';
      return PasswordCheckResult(
        isPwned: false,
        breachCount: 0,
      );
    } catch (_) {
      errorMessage = 'Could not connect to breach database. Please try again.';
      return PasswordCheckResult(
        isPwned: false,
        breachCount: 0,
      );
    }
  }

  // -- Error mapping --
  String _mapNvdError(DioException error) {
    switch (error.response?.statusCode) {
      case 403:
        return 'Invalid API key. Please check your NVD API key in settings.';
      case 429:
        return 'NVD rate limit reached. Please wait a moment.';
      case 503:
        return 'NVD service is unavailable. Please try again soon.';
      default:
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return 'Network error. Please check your connection.';
        }
        return 'Could not load threat intelligence. Please try again.';
    }
  }

  // -- Local cache --
  Future<void> _cacheThreats({
    required int page,
    required String keyword,
    required String cpeName,
    required String severity,
    required String publishStartDate,
    required String publishEndDate,
    required List<ThreatAdvisory> threats,
  }) async {
    try {
      final key = _cacheKey(
        page: page,
        keyword: keyword,
        cpeName: cpeName,
        severity: severity,
        publishStartDate: publishStartDate,
        publishEndDate: publishEndDate,
      );
      await Get.find<StorageService>().saveThreatPage(
        cacheKey: key,
        serialized: threats.map((threat) => threat.toCacheJson()).toList(),
      );
    } catch (_) {
      // Cache writes should never block the live API experience.
    }
  }

  String _cacheKey({
    required int page,
    required String keyword,
    required String cpeName,
    required String severity,
    required String publishStartDate,
    required String publishEndDate,
  }) {
    final severitySegment = severity.trim().isEmpty ? 'ALL' : severity.trim();
    final cpeSegment = cpeName.trim().isEmpty
        ? ''
        : '_cpe${_safeCacheSegment(cpeName.trim())}';
    final keywordSegment =
        keyword.trim().isEmpty ? '' : '_k${_safeCacheSegment(keyword.trim())}';
    return 'threats_p${page}_s$severitySegment$cpeSegment$keywordSegment';
  }

  String _safeCacheSegment(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  }

  Future<int> _fetchThreatCount(Map<String, dynamic> queryParameters) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppStrings.nvdBaseUrl,
      queryParameters: {
        ...queryParameters,
        'resultsPerPage': 1,
        'startIndex': 0,
      },
      options: Options(
        headers: {
          'apiKey': AppStrings.nvdApiKey,
        },
      ),
    );

    final rawTotal = response.data?['totalResults'];
    if (rawTotal is int) {
      return rawTotal;
    }
    return int.tryParse(rawTotal.toString()) ?? 0;
  }

  _ThreatPageBounds _newestPageBounds({
    required int page,
    required int totalResults,
  }) {
    final safePage = page < 0 ? 0 : page;
    final pageSize = AppStrings.nvdResultsPerPage;
    final endExclusive = totalResults - (safePage * pageSize);
    if (endExclusive <= 0) {
      return const _ThreatPageBounds(
        startIndex: 0,
        count: 0,
        hasMore: false,
      );
    }

    final startIndex = endExclusive > pageSize ? endExclusive - pageSize : 0;
    return _ThreatPageBounds(
      startIndex: startIndex,
      count: endExclusive - startIndex,
      hasMore: endExclusive > pageSize,
    );
  }

  ({DateTime start, DateTime end}) _recentPublishWindow() {
    final end = DateTime.now().toUtc();
    final start = end.subtract(
      const Duration(days: AppStrings.nvdRecentWindowDays),
    );
    return (start: start, end: end);
  }

  String _formatNvdDate(DateTime date) {
    final utc = date.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    return '$year-$month-${day}T$hour:$minute:$second.000+00:00';
  }

  static String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}

class _ThreatPageBounds {
  final int startIndex;
  final int count;
  final bool hasMore;

  const _ThreatPageBounds({
    required this.startIndex,
    required this.count,
    required this.hasMore,
  });
}

class _ScoredCpeName {
  final String cpeName;
  final int score;

  const _ScoredCpeName({
    required this.cpeName,
    required this.score,
  });
}
