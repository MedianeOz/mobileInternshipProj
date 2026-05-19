// lib/app/models/threat_advisory.dart
//
// Represents one vulnerability advisory returned by the NVD CVE API and
// normalizes the nested response into UI-friendly fields.

import 'package:flutter/material.dart';

import '../utils/constants.dart';

class ThreatAdvisory {
  final String id;
  final String description;
  final double baseScore;
  final String severity;
  final DateTime publishedDate;
  final DateTime lastModifiedDate;
  final List<String> referenceUrls;

  const ThreatAdvisory({
    required this.id,
    required this.description,
    required this.baseScore,
    required this.severity,
    required this.publishedDate,
    required this.lastModifiedDate,
    required this.referenceUrls,
  });

  factory ThreatAdvisory.fromJson(Map<String, dynamic> json) {
    final descriptions = _asList(json['descriptions']);
    final englishDescription = descriptions.cast<Map?>().firstWhere(
          (item) => item?['lang'] == 'en',
          orElse: () => descriptions.isNotEmpty ? descriptions.first : null,
        );

    final metric = _extractMetric(json['metrics']);
    final references = _asList(json['references'])
        .map((item) => item is Map ? item['url']?.toString() : null)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();

    return ThreatAdvisory(
      id: json['id']?.toString() ?? 'Unknown CVE',
      description: englishDescription?['value']?.toString() ??
          'No description is available for this advisory.',
      baseScore: metric.score,
      severity: metric.severity,
      publishedDate: _parseDate(json['published']),
      lastModifiedDate: _parseDate(json['lastModified']),
      referenceUrls: references,
    );
  }

  factory ThreatAdvisory.fromCache(Map<dynamic, dynamic> json) {
    return ThreatAdvisory(
      id: json['id']?.toString() ?? 'Unknown CVE',
      description: json['description']?.toString() ??
          'No description is available for this advisory.',
      baseScore: (json['baseScore'] as num?)?.toDouble() ?? 0,
      severity: _normalizeSeverity(json['severity']?.toString()),
      publishedDate: _parseDate(json['publishedDate']),
      lastModifiedDate: _parseDate(json['lastModifiedDate']),
      referenceUrls: _asList(json['referenceUrls'])
          .map((item) => item.toString())
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'description': description,
      'baseScore': baseScore,
      'severity': severity,
      'publishedDate': publishedDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
      'referenceUrls': referenceUrls,
    };
  }

  Color get severityColor {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.danger;
      case 'HIGH':
        return AppColors.warning;
      case 'MEDIUM':
        return AppColors.primary;
      case 'LOW':
        return AppColors.textMuted;
      default:
        return AppColors.textHint;
    }
  }

  static List<dynamic> _asList(dynamic value) {
    return value is List ? value : <dynamic>[];
  }

  static DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static _MetricSummary _extractMetric(dynamic metrics) {
    if (metrics is! Map) {
      return const _MetricSummary(score: 0, severity: 'UNKNOWN');
    }

    final metricGroups = [
      metrics['cvssMetricV31'],
      metrics['cvssMetricV30'],
      metrics['cvssMetricV2'],
    ];

    for (final group in metricGroups) {
      final entries = _asList(group);
      if (entries.isEmpty || entries.first is! Map) continue;

      final entry = entries.first as Map;
      final data = entry['cvssData'];
      if (data is! Map) continue;

      final score = (data['baseScore'] as num?)?.toDouble() ?? 0;
      final severity = data['baseSeverity']?.toString() ??
          entry['baseSeverity']?.toString() ??
          'UNKNOWN';

      return _MetricSummary(
        score: score,
        severity: _normalizeSeverity(severity),
      );
    }

    return const _MetricSummary(score: 0, severity: 'UNKNOWN');
  }

  static String _normalizeSeverity(String? value) {
    final severity = (value ?? 'UNKNOWN').toUpperCase();
    const supported = {'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'};
    return supported.contains(severity) ? severity : 'UNKNOWN';
  }
}

class _MetricSummary {
  final double score;
  final String severity;

  const _MetricSummary({
    required this.score,
    required this.severity,
  });
}
