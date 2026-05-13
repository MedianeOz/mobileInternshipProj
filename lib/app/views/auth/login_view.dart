// lib/app/views/auth/login_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/validators.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late RxBool obscurePassword;

  @override
  void initState() {
    super.initState();
    emailController    = TextEditingController();
    passwordController = TextEditingController();
    obscurePassword    = true.obs;

    // Clear any stale error arriving from a previous auth screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AuthController>().clearError();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Validation (uses Validators util) ────────────────────────
  bool _validateFields() {
    final emailError    = Validators.email(emailController.text);
    final passwordError = Validators.password(passwordController.text);
    final firstError    = emailError ?? passwordError;

    if (firstError != null) {
      Get.snackbar(
        'Invalid input',
        firstError,
        backgroundColor: const Color(0xFF1A1D26),
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Navigation side-effect ─────────────────────────
            Obx(() {
              if (controller.currentUser.value != null) {
                Future.microtask(() => Get.offAllNamed(AppRoutes.HOME));
              }
              return const SizedBox.shrink();
            }),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                children: [
                  const SizedBox(height: 64),

                  // ── Brand ──────────────────────────────────────
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
                      'Sign in',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Error Banner ───────────────────────────────
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

                  // ── Email Field ────────────────────────────────
                  _CyberLabel(label: 'Email'),
                  const SizedBox(height: 8),
                  _CyberTextField(
                    controller: emailController,
                    hintText: 'mediane@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  // ── Password Field ─────────────────────────────
                  _CyberLabel(label: 'Password'),
                  const SizedBox(height: 8),
                  Obx(() => _CyberTextField(
                    controller: passwordController,
                    hintText: '••••••••',
                    obscureText: obscurePassword.value,
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

                  // ── Forgot Password ────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        controller.clearError();
                        Get.toNamed(AppRoutes.FORGOT_PASSWORD);
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF00E5A0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Sign In Button ─────────────────────────────
                  Obx(() => _CyberPrimaryButton(
                    label: 'Sign in',
                    isLoading: controller.isLoading.value,
                    onPressed: () {
                      if (!_validateFields()) return; // ← Validators guard
                      controller.login(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                    },
                  )),

                  const SizedBox(height: 24),

                  // ── Divider ────────────────────────────────────
                  Row(
                    children: const [
                      Expanded(
                          child: Divider(
                              color: Color(0xFF2A2D3A), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: TextStyle(
                                color: Color(0xFF8A8F9E), fontSize: 13)),
                      ),
                      Expanded(
                          child: Divider(
                              color: Color(0xFF2A2D3A), thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Google Button ──────────────────────────────
                  Obx(() => _CyberSecondaryButton(
                    label: 'Sign in with Google',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.loginWithGoogle,
                    showGoogleIcon: true,
                  )),

                  const SizedBox(height: 36),

                  // ── Footer ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                            color: Color(0xFF8A8F9E), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.clearError();
                          Get.toNamed(AppRoutes.REGISTER);
                        },
                        child: const Text(
                          'Sign up',
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

// ─────────────────────────────────────────────────────────────
// Shared Design Components (scoped to auth screens)
// ─────────────────────────────────────────────────────────────

class _CyberLabel extends StatelessWidget {
  final String label;
  const _CyberLabel({required this.label});

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

class _CyberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final Color? borderColor;

  const _CyberTextField({
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
          borderSide: BorderSide(
              color: borderColor ?? const Color(0xFF2A2D3A), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: borderColor ?? const Color(0xFF2A2D3A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: borderColor ?? const Color(0xFF00E5A0), width: 1.5),
        ),
      ),
    );
  }
}

class _CyberPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _CyberPrimaryButton({
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

class _CyberSecondaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool showGoogleIcon;

  const _CyberSecondaryButton({
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
