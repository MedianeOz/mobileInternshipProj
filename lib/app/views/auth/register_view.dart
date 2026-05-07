import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

// ─── Strength Model ────────────────────────────────────────────────────────
class _StrengthResult {
  final List<Color> bars;
  final String label;
  final Color labelColor;

  const _StrengthResult({
    required this.bars,
    required this.label,
    required this.labelColor,
  });
}

// ─── Strength Evaluator ────────────────────────────────────────────────────
_StrengthResult _evaluatePassword(String value) {
  if (value.isEmpty) {
    return _StrengthResult(
      bars: List.generate(4, (_) => const Color(0xFF2A2D3A)),
      label: '',
      labelColor: Colors.transparent,
    );
  }

  final bool hasLower = value.contains(RegExp(r'[a-z]'));
  final bool hasUpper = value.contains(RegExp(r'[A-Z]'));
  final bool hasMultipleDigits = value.contains(RegExp(r'\d{2,}')) ||
      (value.split('').where((c) => RegExp(r'\d').hasMatch(c)).length >= 2);
  final bool hasSymbol =
  value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  final int len = value.length;

  int score = 0;

  // Length scoring
  if (len >= 10) score++;

  // Complexity scoring
  if (hasLower && hasUpper) score++;
  if (hasMultipleDigits) score++;
  if (hasSymbol) score++;

  // Clamp
  // if (score > 4) score = 4;

  // Weak
  if (score <= 1) {
    return _StrengthResult(
      bars: [
        const Color(0xFFFF4444),
        const Color(0xFF2A2D3A),
        const Color(0xFF2A2D3A),
        const Color(0xFF2A2D3A),
      ],
      label: 'Weak',
      labelColor: const Color(0xFFFF4444),
    );
  }

  // Fair
  if (score == 2) {
    return _StrengthResult(
      bars: [
        const Color(0xFFE5A000),
        const Color(0xFFE5A000),
        const Color(0xFF2A2D3A),
        const Color(0xFF2A2D3A),
      ],
      label: 'Fair',
      labelColor: const Color(0xFFE5A000),
    );
  }

  // Strong
  if (score == 3) {
    return _StrengthResult(
      bars: [
        const Color(0xFF00E5A0),
        const Color(0xFF00E5A0),
        const Color(0xFF00E5A0),
        const Color(0xFF2A2D3A),
      ],
      label: 'Strong',
      labelColor: const Color(0xFF00E5A0),
    );
  }

  // Very Strong
  return _StrengthResult(
    bars: List.generate(4, (_) => const Color(0xFF00C853)),
    label: 'Very Strong',
    labelColor: const Color(0xFF00C853),
  );
}



// ─── Register View ─────────────────────────────────────────────────────────
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmController;
  late RxBool obscurePassword;
  late RxBool obscureConfirm;
  late Rx<_StrengthResult> strength;
  late RxBool confirmMatches;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmController = TextEditingController();
    obscurePassword = true.obs;
    obscureConfirm = true.obs;
    strength = _evaluatePassword('').obs;
    confirmMatches = false.obs;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                children: [
                  const SizedBox(height: 64),

                  // ── Brand ────────────────────────────────────────
                  const Center(
                    child: Text(
                      'CYBERSHIELD',
                      style: TextStyle(
                        color: Color(0xFF00E5A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      'Create account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Error Banner — has its own Obx ────────────────
                  Obx(() {
                    if (controller.errorMessage.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFF4444), width: 1),
                      ),
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                            color: Color(0xFFFF4444), fontSize: 13),
                      ),
                    );
                  }),

                  // ── Full Name ─────────────────────────────────────
                  _AuthLabel(label: 'Full name'),
                  const SizedBox(height: 8),
                  _AuthTextField(
                    controller: nameController,
                    hintText: 'Mediane Ozeir',
                    keyboardType: TextInputType.name,
                  ),

                  const SizedBox(height: 20),

                  // ── Email ─────────────────────────────────────────
                  _AuthLabel(label: 'Email'),
                  const SizedBox(height: 8),
                  _AuthTextField(
                    controller: emailController,
                    hintText: 'mediane@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  // ── Password ──────────────────────────────────────
                  _AuthLabel(label: 'Password'),
                  const SizedBox(height: 8),
                  Obx(() => _AuthTextField(
                    controller: passwordController,
                    hintText: '••••••••••',
                    obscureText: obscurePassword.value,
                    onChanged: (val) {
                      strength.value = _evaluatePassword(val);
                      confirmMatches.value =
                          val == confirmController.text &&
                              val.isNotEmpty;
                    },
                    borderColor: strength.value.label == 'Very Strong'
                        ? const Color(0xFF00C853)
                        : strength.value.label == 'Strong'
                        ? const Color(0xFF00E5A0)
                        : strength.value.label.startsWith('Fair')
                        ? const Color(0xFFE5A000)
                        : null,
                    suffixIcon: GestureDetector(
                      onTap: () =>
                      obscurePassword.value = !obscurePassword.value,
                      child: Icon(
                        obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF8A8F9E),
                        size: 20,
                      ),
                    ),
                  )),

                  const SizedBox(height: 10),

                  // ── Strength Bar ──────────────────────────────────
                  Obx(() {
                    final currentStrength = strength.value;

                    if (currentStrength.label.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(4, (i) {
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(
                                    right: i < 3 ? 4 : 0),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: currentStrength.bars[i],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                        Text(
                            currentStrength.label,
                            style: TextStyle(
                              color: currentStrength.labelColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            )
                        )
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Confirm Password ──────────────────────────────
                  _AuthLabel(label: 'Confirm password'),
                  const SizedBox(height: 8),
                  Obx(() => _AuthTextField(
                    controller: confirmController,
                    hintText: '••••••••••',
                    obscureText: obscureConfirm.value,
                    onChanged: (val) {
                      confirmMatches.value =
                          val == passwordController.text &&
                              val.isNotEmpty;
                    },
                    borderColor: confirmMatches.value
                        ? const Color(0xFF00E5A0)
                        : null,
                    suffixIcon: GestureDetector(
                      onTap: () =>
                      obscureConfirm.value = !obscureConfirm.value,
                      child: Icon(
                        obscureConfirm.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF8A8F9E),
                        size: 20,
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // ── Create Account Button ─────────────────────────
                  Obx(() => _AuthPrimaryButton(
                    label: 'Create account',
                    isLoading: controller.isLoading.value,
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        Get.snackbar(
                          'Missing field',
                          'Please enter your full name',
                          backgroundColor: const Color(0xFF1A1D26),
                          colorText: Colors.white,
                        );
                        return;
                      }
                      if (passwordController.text !=
                          confirmController.text) {
                        Get.snackbar(
                          'Password mismatch',
                          'Passwords do not match',
                          backgroundColor: const Color(0xFF1A1D26),
                          colorText: Colors.white,
                        );
                        return;
                      }
                      controller.register(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                    },
                  )),

                  const SizedBox(height: 16),

                  // ── Google Button ─────────────────────────────────
                  Obx(() => _AuthSecondaryButton(
                    label: 'Continue with Google',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.loginWithGoogle,
                    showGoogleIcon: true,
                  )),

                  const SizedBox(height: 36),

                  // ── Footer ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                            color: Color(0xFF8A8F9E), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.LOGIN),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared auth screen components
// These are intentionally prefixed with _Auth to keep them file-scoped.
// For reuse across auth screens, extract to lib/widgets/auth_widgets.dart.
// ─────────────────────────────────────────────────────────────────────────

class _AuthLabel extends StatelessWidget {
  final String label;
  const _AuthLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF8A8F9E),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final Color? borderColor;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onChanged,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeBorder = borderColor ?? const Color(0xFF2A2D3A);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
        const TextStyle(color: Color(0xFF4A5568), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF1A1D26),
        suffixIcon: suffixIcon != null
            ? Padding(
          padding: const EdgeInsets.only(right: 12),
          child: suffixIcon,
        )
            : null,
        suffixIconConstraints:
        const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: activeBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: activeBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: borderColor ?? const Color(0xFF00E5A0),
              width: 1.5),
        ),
      ),
    );
  }
}

class _AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AuthPrimaryButton({
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
          backgroundColor: const Color(0xFF00E5A0),
          foregroundColor: const Color(0xFF0D0F14),
          disabledBackgroundColor:
          const Color(0xFF00E5A0).withOpacity(0.5),
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
            strokeWidth: 2,
            color: Color(0xFF0D0F14),
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

class _AuthSecondaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool showGoogleIcon;

  const _AuthSecondaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.showGoogleIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF2A2D3A), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: const Color(0xFF1A1D26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showGoogleIcon) ...[
              const Text(
                'G',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
