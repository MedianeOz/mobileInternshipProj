// lib/app/views/alerts/alerts_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/notification_controller.dart';
import '../../models/app_notification.dart';
import '../../utils/constants.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> with WidgetsBindingObserver {
  late final NotificationController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
    controller.refreshFromStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.refreshFromStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Alerts',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (controller.unreadCount.value == 0) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: controller.markAllRead,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
              _SeverityFilterBar(controller: controller),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  if (controller.notifications.isEmpty) {
                    return const _EmptyAlertsState();
                  }

                  final notifications = controller.filteredNotifications
                      .where(_hasVisibleNotificationContent)
                      .toList();
                  if (notifications.isEmpty) {
                    return const _EmptyAlertsState();
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async => controller.refreshFromStorage(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationTile(
                          key: ValueKey(notification.id),
                          notification: notification,
                          controller: controller,
                        );
                      },
                    ),
                  );
                }),
              ),
              Obx(() {
                if (controller.notifications.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: controller.clearAll,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityFilterBar extends StatelessWidget {
  final NotificationController controller;

  const _SeverityFilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    const filters = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

    return SizedBox(
      height: 36,
      child: Obx(() {
        final selectedFilter = controller.selectedSeverityFilter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final selected = selectedFilter.isEmpty
                ? filter == 'ALL'
                : selectedFilter == filter;
            return GestureDetector(
              onTap: () => controller.filterBySeverity(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color:
                        selected ? AppColors.background : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _EmptyAlertsState extends StatelessWidget {
  const _EmptyAlertsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No alerts yet.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final NotificationController controller;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(notification.severity);
    final severityLabel = _severityLabel(notification.severity) ?? 'ALERT';
    final cveId = _cleanText(notification.cveId);
    final hasCve = cveId != null && cveId.isNotEmpty;
    final isUnread = !notification.isRead;
    final title = _displayText(notification.title, 'CyberShield Alert');
    final body = _displayText(
      notification.body,
      'Open this alert to review the available security details.',
    );

    return GestureDetector(
      onTap: () => controller.openNotification(notification),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? severityColor.withValues(alpha: 0.07)
              : AppColors.surface,
          border: isUnread
              ? Border(
                  left: BorderSide(color: severityColor, width: 3),
                  top: BorderSide(
                    color: severityColor.withValues(alpha: 0.65),
                    width: 1,
                  ),
                  right: BorderSide(
                    color: severityColor.withValues(alpha: 0.65),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: severityColor.withValues(alpha: 0.65),
                    width: 1,
                  ),
                )
              : Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SeverityChip(
                      label: severityLabel,
                      color: severityColor,
                    ),
                  ),
                ),
                Text(
                  _timeAgo(notification.timestamp),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (hasCve) ...[
              const SizedBox(height: 8),
              Text(
                cveId,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnread ? AppColors.white : AppColors.textMuted,
                fontSize: 14,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnread ? AppColors.textMuted : AppColors.textHint,
                fontSize: 13,
              ),
            ),
            if (hasCve) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(
                    Icons.open_in_new,
                    color: AppColors.textHint,
                    size: 12,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tap to view CVE details',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _severityColor(String? severity) {
  switch (severity?.toUpperCase()) {
    case 'CRITICAL':
      return AppColors.danger;
    case 'HIGH':
      return AppColors.warning;
    case 'MEDIUM':
      return AppColors.primary;
    case 'LOW':
      return AppColors.primaryDark;
    default:
      return AppColors.primary;
  }
}

String? _severityLabel(String? severity) {
  const supported = {'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'};
  final value = severity?.toUpperCase();
  return supported.contains(value) ? value : null;
}

String? _cleanText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _displayText(String? value, String fallback) {
  return _cleanText(value) ?? fallback;
}

bool _hasVisibleNotificationContent(AppNotification notification) {
  final title = _cleanText(notification.title);
  final hasOnlyDefaultTitle = title == null || title == 'CyberShield Alert';
  return !hasOnlyDefaultTitle ||
      _cleanText(notification.body) != null ||
      _cleanText(notification.severity) != null ||
      _cleanText(notification.cveId) != null ||
      notification.baseScore != null;
}

String _timeAgo(DateTime timestamp) {
  final difference = DateTime.now().difference(timestamp);
  if (difference.inDays > 0) return '${difference.inDays}d ago';
  if (difference.inHours > 0) return '${difference.inHours}h ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
  return 'Just now';
}
