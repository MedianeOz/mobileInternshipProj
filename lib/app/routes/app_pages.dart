import 'package:get/get.dart';
import '../views/home/home_view.dart';
import '../bindings/home_binding.dart';
import '../bindings/auth_binding.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/forgot_password_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [

    // ── Auth screens ─────────────────────────────────────────────
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
    ),

    // ── Home screen ───────────────────────────────────────────────
    // AuthBinding is included here so AuthController is available
    // on the home screen (needed for logout + showing user email).
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeView(),
      bindings: [
        AuthBinding(),
        HomeBinding(),
      ],
    ),

    // ── Initial route (redirects to login) ───────────────────────
    GetPage(
      name: AppRoutes.INITIAL,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
  ];
}
