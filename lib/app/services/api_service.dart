// lib/app/services/api_service.dart
//
// Dio-powered integration layer for NVD threat intelligence and Have I Been
// Pwned password range checks. Network errors are normalized for controllers.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/password_check_result.dart';
import '../models/threat_advisory.dart';
import '../utils/constants.dart';

class ApiService {
  late final Dio _dio;

  String errorMessage = '';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
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
    String? severity,
  }) async {
    errorMessage = '';

    final queryParameters = <String, dynamic>{
      'resultsPerPage': AppStrings.nvdResultsPerPage,
      'startIndex': page * AppStrings.nvdResultsPerPage,
    };

    final trimmedKeyword = keyword?.trim();
    if (trimmedKeyword != null && trimmedKeyword.isNotEmpty) {
      queryParameters['keywordSearch'] = trimmedKeyword;
    }

    final normalizedSeverity = severity?.trim().toUpperCase();
    if (normalizedSeverity != null && normalizedSeverity.isNotEmpty) {
      queryParameters['cvssV3Severity'] = normalizedSeverity;
    }

    try {
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
          .toList();

      await _cacheThreats(
        page: page,
        keyword: trimmedKeyword ?? '',
        severity: normalizedSeverity ?? '',
        threats: threats,
      );

      return threats;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404 &&
          trimmedKeyword != null &&
          trimmedKeyword.isNotEmpty) {
        return <ThreatAdvisory>[];
      }

      errorMessage = _mapNvdError(error);
      return <ThreatAdvisory>[];
    } catch (_) {
      errorMessage = 'Could not load threat intelligence. Please try again.';
      return <ThreatAdvisory>[];
    }
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
            password: password,
          );
        }
      }

      return PasswordCheckResult(
        isPwned: false,
        breachCount: 0,
        password: password,
      );
    } on DioException catch (_) {
      errorMessage = 'Could not connect to breach database. Please try again.';
      return PasswordCheckResult(
        isPwned: false,
        breachCount: 0,
        password: password,
      );
    } catch (_) {
      errorMessage = 'Could not connect to breach database. Please try again.';
      return PasswordCheckResult(
        isPwned: false,
        breachCount: 0,
        password: password,
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
    required String severity,
    required List<ThreatAdvisory> threats,
  }) async {
    try {
      final box = await Hive.openBox<dynamic>(AppHiveBoxes.threatCache);
      final key = _cacheKey(page: page, keyword: keyword, severity: severity);
      await box.put(
        key,
        threats.map((threat) => threat.toCacheJson()).toList(),
      );
    } catch (_) {
      // Cache writes should never block the live API experience.
    }
  }

  String _cacheKey({
    required int page,
    required String keyword,
    required String severity,
  }) {
    return 'page=$page|keyword=$keyword|severity=$severity';
  }
}
