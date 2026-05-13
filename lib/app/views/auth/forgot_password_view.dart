// lib/app/views/auth/forgot_password_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class ForgotPasswordView extends StatefulWidget {    // ← was StatelessWidget
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late TextEditingController emailController;
  late RxBool emailSent;                             // ← moved out of build()

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    emailSent       = false.obs;

    // ── Clear any stale error from a previous auth screen ──────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AuthController>().clearError();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Obx(() {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView(
              children: [
                const SizedBox(height: 80),

                // ── Brand ──────────────────────────────────────────
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

                const SizedBox(height: 16),

                const Center(
                  child: Text(
                    'Reset your password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    "Enter your email and we'll send you a reset link.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8A8F9E),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Success State ──────────────────────────────────
                if (emailSent.value) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5A0).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00E5A0).withOpacity(0.3),
                          width: 1),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_outlined,
                            color: Color(0xFF00E5A0), size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Reset link sent!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check your inbox at ${emailController.text.trim()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8A8F9E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Error Banner ───────────────────────────────────
                if (controller.errorMessage.value.isNotEmpty) ...[
                  Container(
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
                  ),
                ],

                // ── Email Field ────────────────────────────────────
                const Text(
                  'Email',
                  style: TextStyle(
                    color: Color(0xFF8A8F9E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'mediane@email.com',
                    hintStyle: const TextStyle(
                        color: Color(0xFF4A5568), fontSize: 15),
                    filled: true,
                    fillColor: const Color(0xFF1A1D26),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF2A2D3A), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF2A2D3A), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF00E5A0), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Send Reset Link Button ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                      if (emailController.text.trim().isEmpty) {
                        Get.snackbar(
                          'Missing email',
                          'Please enter your email address.',
                          backgroundColor: const Color(0xFF1A1D26),
                          colorText: Colors.white,
                        );
                        return;
                      }
                      await controller
                          .resetPassword(emailController.text.trim());
                      if (controller.errorMessage.value.isEmpty) {
                        emailSent.value = true;    // ← safe: stable reference
                      }
                    },
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
                    child: controller.isLoading.value
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0D0F14),
                      ),
                    )
                        : const Text(
                      'Send reset link',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Back to Login ──────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () {
                      controller.clearError();           // ← clear before navigating
                      Get.toNamed(AppRoutes.LOGIN);
                    },
                    child: const Text(
                      'Back to login',
                      style: TextStyle(
                        color: Color(0xFF00E5A0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Center(
                  child: Text(
                    "Check your spam folder if you don't see it.",
                    style: TextStyle(
                      color: Color(0xFF8A8F9E),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        }),
      ),
    );
  }
}
