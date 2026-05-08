import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthController is already registered by AuthBinding on the auth routes.
    // We use Get.find to access it here without re-creating it.
    final AuthController auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 48),

              // ── Brand ────────────────────────────────────────────
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

              const SizedBox(height: 32),

              // ── Welcome card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2A2D3A),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication successful',
                      style: TextStyle(
                        color: Color(0xFF00E5A0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You are now signed in.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Show logged-in email ────────────────────────
                    Obx(() {
                      final email =
                          auth.currentUser.value?.email ?? 'Unknown';
                      return Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF8A8F9E),
                          fontSize: 13,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Info banner ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5A0).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00E5A0).withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: const Text(
                  '✓  Deliverable 4 — Authentication Flow complete.\n'
                  'This screen is a temporary placeholder.\n'
                  'The full home screen (Threat Feed) will replace it in Deliverable 6.',
                  style: TextStyle(
                    color: Color(0xFF00E5A0),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(),

              // ── Sign Out Button ──────────────────────────────────
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: auth.isLoading.value
                          ? null
                          : () async {
                              await auth.logout();
                              Get.offAllNamed(AppRoutes.LOGIN);
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4444),
                        side: const BorderSide(
                            color: Color(0xFFFF4444), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: const Color(0xFFFF4444)
                            .withOpacity(0.07),
                      ),
                      child: auth.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF4444),
                              ),
                            )
                          : const Text(
                              'Sign out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF4444),
                              ),
                            ),
                    ),
                  )),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
