// lib/app/views/password/password_checker_view.dart
//
// Password Health tab. Checks a password against HIBP using k-anonymity and
// clearly communicates that the full password never leaves the device.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/password_controller.dart';
import '../../models/password_check_result.dart';
import '../../utils/constants.dart';

class PasswordCheckerView extends StatefulWidget {
  const PasswordCheckerView({super.key});

  @override
  State<PasswordCheckerView> createState() => _PasswordCheckerViewState();
}

class _PasswordCheckerViewState extends State<PasswordCheckerView> {
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PasswordController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [
              const SizedBox(height: 28),
              const _BrandLabel(),
              const SizedBox(height: 28),
              const Text(
                'Password Health',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check if your password has been exposed in known data breaches',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const _PrivacyInfoCard(),
              const SizedBox(height: 24),
              const _FieldLabel(label: 'Password'),
              const SizedBox(height: 8),
              Obx(
                () => _PasswordField(
                  controller: passwordController,
                  enabled: !controller.isChecking.value,
                  obscureText: controller.obscurePassword.value,
                  onToggle: () {
                    controller.obscurePassword.value =
                        !controller.obscurePassword.value;
                  },
                  onChanged: (_) => controller.clearResult(),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _ErrorBanner(message: controller.errorMessage.value);
              }),
              const SizedBox(height: 20),
              Obx(
                () => _PrimaryButton(
                  label: 'Check Password',
                  isLoading: controller.isChecking.value,
                  onPressed: () => controller.checkPassword(
                    passwordController.text,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final result = controller.result.value;
                if (result == null) {
                  return const SizedBox.shrink();
                }
                return _ResultSection(
                  result: result,
                  onClear: () {
                    passwordController.clear();
                    controller.clearResult();
                  },
                );
              }),
              const SizedBox(height: 32),
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

// -- Info and input --
class _PrivacyInfoCard extends StatelessWidget {
  const _PrivacyInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your password never leaves your device. Only a partial hash is sent.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _PasswordField({
    required this.controller,
    required this.enabled,
    required this.obscureText,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Enter a password to check',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: GestureDetector(
          onTap: enabled ? onToggle : null,
          child: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
        ),
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

// -- Feedback --
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.danger, fontSize: 13),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.background,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final PasswordCheckResult result;
  final VoidCallback onClear;

  const _ResultSection({
    required this.result,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isPwned = result.isPwned;
    final color = isPwned ? AppColors.danger : AppColors.primary;
    final icon = isPwned ? Icons.warning_amber_rounded : Icons.verified_user;
    final title = isPwned ? 'Password Exposed' : 'Password Safe';
    final subtitle = isPwned
        ? 'Found in ${result.breachCount} known data breaches'
        : 'Not found in any known breaches';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isPwned ? 0.1 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: isPwned ? 1 : 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: onClear,
          child: const Text(
            'Check another password',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
