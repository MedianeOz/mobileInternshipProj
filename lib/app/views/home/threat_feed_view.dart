// lib/app/views/home/threat_feed_view.dart
//
// Dashboard tab for CyberShield. Displays NVD CVEs with search, severity
// filtering, pull-to-refresh, pagination, and resilient empty/error states.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/threat_feed_controller.dart';
import '../../models/threat_advisory.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';

class ThreatFeedView extends StatefulWidget {
  const ThreatFeedView({super.key});

  @override
  State<ThreatFeedView> createState() => _ThreatFeedViewState();
}

class _ThreatFeedViewState extends State<ThreatFeedView> {
  late final TextEditingController searchController;
  late final ScrollController scrollController;
  late final ThreatFeedController threatController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    scrollController = ScrollController();
    threatController = Get.isRegistered<ThreatFeedController>()
        ? Get.find<ThreatFeedController>()
        : Get.put(ThreatFeedController());
    scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!scrollController.hasClients) return;

    final threshold = scrollController.position.maxScrollExtent - 220;
    if (scrollController.position.pixels >= threshold) {
      threatController.loadMoreThreats();
    }
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      threatController.search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = threatController;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              const _BrandLabel(),
              const SizedBox(height: 28),
              const Text(
                'Threat Intelligence',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Latest CVEs from NVD',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Obx(
                () => _SearchBar(
                  controller: searchController,
                  enabled: !controller.isLoading.value &&
                      !controller.isLoadingMore.value,
                  onChanged: _handleSearchChanged,
                  onSubmitted: controller.search,
                ),
              ),
              const SizedBox(height: 14),
              Obx(() {
                if (!controller.isOffline.value &&
                    !controller.isShowingCachedData.value) {
                  return const SizedBox.shrink();
                }

                final message = controller.isOffline.value
                    ? 'Offline · showing cached results'
                    : 'Network error · showing cached results';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CachedDataBanner(text: message),
                );
              }),
              Obx(
                () => _SeverityFilters(
                  selectedSeverity: controller.selectedSeverity.value,
                  isDisabled: controller.isLoading.value ||
                      controller.isLoadingMore.value,
                  onSelected: controller.filterBySeverity,
                ),
              ),
              const SizedBox(height: 14),
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _ErrorBanner(
                  message: controller.errorMessage.value,
                  isRetrying: controller.isLoading.value,
                  onRetry: () => controller.fetchThreats(refresh: true),
                );
              }),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.threats.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => controller.fetchThreats(refresh: true),
                    child: controller.threats.isEmpty
                        ? controller.isOffline.value
                            ? const _OfflineEmptyState()
                            : const _EmptyThreatState()
                        : ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: controller.threats.length +
                                (controller.isLoadingMore.value ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= controller.threats.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ThreatCard(
                                  threat: controller.threats[index],
                                  onTap: () => Get.toNamed(
                                    AppRoutes.THREAT_DETAIL,
                                    arguments: controller.threats[index],
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Header --
class _BrandLabel extends StatelessWidget {
  const _BrandLabel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        AppStrings.appName,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}

// -- Search and filters --
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _SearchBar({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search CVEs...',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textMuted,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SeverityFilters extends StatelessWidget {
  final String selectedSeverity;
  final bool isDisabled;
  final ValueChanged<String> onSelected;

  const _SeverityFilters({
    required this.selectedSeverity,
    required this.isDisabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const filters = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedSeverity.isEmpty
              ? filter == 'ALL'
              : filter == selectedSeverity;

          return GestureDetector(
            onTap: isDisabled ? null : () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.background
                      : AppColors.textMuted.withValues(
                          alpha: isDisabled ? 0.5 : 1,
                        ),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -- States --
class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: isRetrying ? null : onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CachedDataBanner extends StatelessWidget {
  final String text;

  const _CachedDataBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThreatState extends StatelessWidget {
  const _EmptyThreatState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.shield_outlined,
          color: AppColors.textMuted,
          size: 52,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No threats found',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'Try another search or severity filter.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _OfflineEmptyState extends StatelessWidget {
  const _OfflineEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.wifi_off_outlined,
          color: AppColors.textMuted,
          size: 52,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            "You're offline",
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'No cached threats available. Connect to load the latest CVEs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// -- Threat card --
class _ThreatCard extends StatelessWidget {
  final ThreatAdvisory threat;
  final VoidCallback onTap;

  const _ThreatCard({
    required this.threat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    threat.id,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _SeverityChip(threat: threat),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              threat.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Published ${_formatDate(threat.publishedDate)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                _ScoreBadge(threat: threat),
              ],
            ),
          ],
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

class _SeverityChip extends StatelessWidget {
  final ThreatAdvisory threat;

  const _SeverityChip({required this.threat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: threat.severityColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: threat.severityColor.withValues(alpha: 0.8),
        ),
      ),
      child: Text(
        threat.severity,
        style: TextStyle(
          color: threat.severityColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final ThreatAdvisory threat;

  const _ScoreBadge({required this.threat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: threat.severityColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        threat.baseScore.toStringAsFixed(1),
        style: TextStyle(
          color: threat.severityColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
