// lib/app/views/home/threat_detail_view.dart
//
// Lightweight CVE detail route opened from the threat feed. Shows full
// advisory text, CVSS score, dates, and reference URLs.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/threat_advisory.dart';
import '../../utils/constants.dart';

class ThreatDetailView extends StatelessWidget {
  const ThreatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final threat = Get.arguments as ThreatAdvisory?;

    if (threat == null) {
      return const _MissingThreatView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.share_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _SeverityChip(threat: threat),
                  const Spacer(),
                  _ScoreCircle(threat: threat),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                threat.id,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Published ${_formatDate(threat.publishedDate)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              _DetailCard(
                title: 'Description',
                child: Text(
                  threat.description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                title: 'References',
                child: threat.referenceUrls.isEmpty
                    ? const Text(
                        'No reference URLs were provided by NVD.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: threat.referenceUrls
                            .map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  url,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'unknown';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

// -- Detail components --
class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final ThreatAdvisory threat;

  const _SeverityChip({required this.threat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: threat.severityColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: threat.severityColor),
      ),
      child: Text(
        threat.severity,
        style: TextStyle(
          color: threat.severityColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final ThreatAdvisory threat;

  const _ScoreCircle({required this.threat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: threat.severityColor, width: 2),
      ),
      child: Text(
        threat.baseScore.toStringAsFixed(1),
        style: TextStyle(
          color: threat.severityColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MissingThreatView extends StatelessWidget {
  const _MissingThreatView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: TextButton(
            onPressed: Get.back,
            child: const Text(
              'Threat detail unavailable',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}
