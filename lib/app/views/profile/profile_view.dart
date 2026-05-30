// lib/app/views/profile/profile_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 28),
            Obx(() {
              final profile = controller.userProfile.value;
              return _ProfileHeader(
                initials: controller.displayInitials,
                displayName: profile.displayName,
                email: profile.email.isEmpty ? 'Signed in user' : profile.email,
              );
            }),
            const SizedBox(height: 24),
            const _SectionLabel(
              label: 'My watchlist',
              subtitle:
                  'Use specific products like OpenSSL or Apache Tomcat for better CVE matches',
            ),
            const SizedBox(height: 10),
            Obx(() {
              final items = controller.watchlist.toList();
              return _WatchlistWrap(
                items: items,
                onRemove: controller.removeTechnology,
                onAdd: () => _showAddTechnologyDialog(controller),
              );
            }),
            const SizedBox(height: 26),
            const _SectionLabel(label: 'Notifications'),
            const SizedBox(height: 10),
            Obx(
              () {
                final allEnabled = controller.allNotificationsEnabled.value;
                return _NotificationCard(
                  title: 'Critical alerts',
                  subtitle: 'On: Critical & High only. Off: all alerts',
                  value: controller.criticalAlertsEnabled.value,
                  onChanged: allEnabled ? controller.setCriticalAlerts : null,
                );
              },
            ),
            const SizedBox(height: 10),
            Obx(
              () {
                final allEnabled = controller.allNotificationsEnabled.value;
                return _NotificationCard(
                  title: 'Quiet hours',
                  subtitle: 'Suppress alerts 10 PM - 7 AM',
                  value: controller.quietHoursEnabled.value,
                  onChanged: allEnabled ? controller.setQuietHours : null,
                );
              },
            ),
            const SizedBox(height: 10),
            Obx(
              () => _NotificationCard(
                title: 'All notifications',
                subtitle: 'Master switch for all alerts',
                value: controller.allNotificationsEnabled.value,
                onChanged: controller.setAllNotifications,
              ),
            ),
            const SizedBox(height: 26),
            const _SectionLabel(label: 'App'),
            const SizedBox(height: 10),
            Obx(
              () => _InfoCard(
                title: 'Last synced',
                right: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${controller.timeAgo} - ',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.syncNow,
                      child: const Text(
                        'Sync now',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _InfoCard(
              title: 'App version',
              right: Text(
                '1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),
            _SignOutButton(onTap: () => _showSignOutDialog(controller)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddTechnologyDialog(ProfileController controller) {
    Get.dialog<void>(
      _AddTechnologyDialog(
        onAdd: controller.addTechnology,
      ),
    );
  }

  void _showSignOutDialog(ProfileController controller) {
    Get.dialog<void>(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: Get.width - 48,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign out?',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Are you sure you want to sign out of your account?',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: Get.back,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller.authController.logout();
                            Get.offAllNamed(AppRoutes.LOGIN);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Sign out'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTechnologyDialog extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _AddTechnologyDialog({required this.onAdd});

  @override
  State<_AddTechnologyDialog> createState() => _AddTechnologyDialogState();
}

class _AddTechnologyDialogState extends State<_AddTechnologyDialog> {
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: Get.width - 48,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add technology',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: _submit,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. React Native',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _submit(textController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(String value) {
    final technology = value.trim();
    if (technology.isEmpty) {
      return;
    }
    widget.onAdd(technology);
    Get.back<void>();
  }
}

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;

  const _ProfileHeader({
    required this.initials,
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? subtitle;

  const _SectionLabel({
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _WatchlistWrap extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  const _WatchlistWrap({
    required this.items,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          _WatchChip(
            label: item,
            onRemove: () => onRemove(item),
          ),
        _AddChip(onTap: onAdd),
      ],
    );
  }
}

class _WatchChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _WatchChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: onRemove,
            child:
                const Icon(Icons.close, color: AppColors.textMuted, size: 14),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Text(
          '+ Add tech',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary.withValues(alpha: 0.35);
                }
                return AppColors.border;
              }),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget right;

  const _InfoCard({
    required this.title,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          right,
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: AppColors.background,
        ),
        child: const Text(
          'Sign out',
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
