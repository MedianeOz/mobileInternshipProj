import 'package:cybershield_app/app/models/threat_advisory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void setupGetX() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
}

ThreatAdvisory makeThreat({
  String id = 'CVE-2024-0001',
  String severity = 'CRITICAL',
  double baseScore = 9.8,
  String description = 'Test advisory',
  DateTime? publishedDate,
}) {
  return ThreatAdvisory(
    id: id,
    severity: severity,
    baseScore: baseScore,
    description: description,
    publishedDate: publishedDate ?? DateTime(2024, 3, 15),
    lastModifiedDate: DateTime(2024, 3, 16),
    referenceUrls: const [],
  );
}
