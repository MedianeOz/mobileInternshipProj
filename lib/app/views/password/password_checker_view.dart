// lib/app/views/password/password_checker_view.dart
//
// Password Shield tab. Performs local strength analysis in real time and uses
// HIBP k-anonymity for explicit breach checks.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/password_controller.dart';
import '../../models/password_check_result.dart';
import '../../utils/constants.dart';
import '../../utils/password_analyzer.dart';

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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Password Shield',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Nothing is stored',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _FieldLabel(label: 'Enter password to analyze'),
            const SizedBox(height: 8),
            Obx(() {
              final result = controller.strengthResult.value;
              return _PasswordField(
                controller: passwordController,
                obscureText: controller.obscureText.value,
                borderColor:
                    result.hasPassword ? result.borderColor : AppColors.border,
                onToggle: () {
                  controller.obscureText.value = !controller.obscureText.value;
                },
                onChanged: (value) {
                  if (value.isEmpty) {
                    controller.clearAll();
                    return;
                  }
                  controller.analyzePassword(value);
                },
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              final result = controller.strengthResult.value;
              if (!result.hasPassword) return const SizedBox.shrink();
              return _StrengthSection(result: result);
            }),
            Obx(() {
              final result = controller.strengthResult.value;
              if (!result.hasPassword) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: _AnalysisCard(result: result),
              );
            }),
            Obx(() {
              final message = controller.errorMessage.value;
              if (message.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _ErrorBanner(message: message),
              );
            }),
            Obx(() {
              final breachResult = controller.breachResult.value;
              if (!controller.isBreachChecked.value || breachResult == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: _BreachResultCard(result: breachResult),
              );
            }),
            Obx(() {
              if (controller.password.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _PrimaryButton(
                  isLoading: controller.isChecking.value,
                  onPressed: controller.checkBreach,
                ),
              );
            }),
            Obx(() {
              final result = controller.strengthResult.value;
              final tip = result.improvementTip;
              if (!result.hasPassword || tip == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: _ImprovementTipCard(tip: tip),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
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
  final bool obscureText;
  final Color borderColor;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.borderColor,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Enter password',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: GestureDetector(
          onTap: onToggle,
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
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
    );
  }
}

class _StrengthSection extends StatelessWidget {
  final PasswordStrengthResult result;

  const _StrengthSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Strength',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            Text(
              result.label,
              style: TextStyle(
                color: result.labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: result.bars[index],
                  borderRadius: BorderRadius.circular(4),
                  border: result.bars[index] == AppColors.border
                      ? Border.all(color: AppColors.border)
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final PasswordStrengthResult result;

  const _AnalysisCard({required this.result});

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
          const Text(
            'Analysis',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Length',
                  value: '${result.length} chars',
                  valueColor: _lengthColor(result.length),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Entropy',
                  value: '${result.entropyBits.round()} bits',
                  valueColor: _entropyColor(result.entropyBits),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Uppercase',
                  value: result.hasUppercase ? 'Yes' : 'No',
                  valueColor: result.hasUppercase
                      ? AppColors.primary
                      : AppColors.danger,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Numbers',
                  value: result.hasNumbers ? 'Yes' : 'No',
                  valueColor:
                      result.hasNumbers ? AppColors.primary : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Symbols',
                  value: result.hasSymbols ? 'Yes' : 'No',
                  valueColor:
                      result.hasSymbols ? AppColors.primary : AppColors.danger,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Dictionary',
                  value: result.dictionaryLabel,
                  valueColor: result.hasDictionaryWord
                      ? AppColors.danger
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _lengthColor(int length) {
    if (length >= 12) return AppColors.primary;
    if (length >= 8) return AppColors.warning;
    return AppColors.danger;
  }

  static Color _entropyColor(double entropy) {
    if (entropy >= 72) return AppColors.primary;
    if (entropy >= 48) return AppColors.warning;
    return AppColors.danger;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreachResultCard extends StatelessWidget {
  final PasswordCheckResult result;

  const _BreachResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isPwned = result.isPwned;
    final color = isPwned ? AppColors.danger : AppColors.primary;
    final title = isPwned
        ? 'Found in ${_formatCount(result.breachCount)} breaches'
        : 'Not found in breaches';
    final subtitle = isPwned
        ? 'This password is compromised. Change it immediately.'
        : 'Checked via HIBP k-anonymity - your password never left this device';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPwned ? Icons.warning_amber_rounded : Icons.check,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int count) {
    final digits = count.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

class _PrimaryButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
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
            : const Text(
                'Check for breaches',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class _ImprovementTipCard extends StatelessWidget {
  final String tip;

  const _ImprovementTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: AppColors.warning),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tip to reach Very Strong',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
