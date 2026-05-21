import 'package:get/get.dart';

import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/knowledge_binding.dart';
import '../bindings/password_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/shell_binding.dart';
import '../bindings/threat_binding.dart';
import '../views/alerts/alerts_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/home/home_view.dart';
import '../views/home/threat_detail_view.dart';
import '../views/knowledge_base/article_list_view.dart';
import '../views/knowledge_base/article_reader_view.dart';
import '../views/knowledge_base/library_view.dart';
import '../views/password/password_checker_view.dart';
import '../views/profile/profile_view.dart';
import '../views/shell/main_shell_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    // -- Auth screens --
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

    // -- Authenticated app shell --
    GetPage(
      name: AppRoutes.SHELL,
      page: () => const MainShellView(),
      binding: ShellBinding(),
    ),

    // -- Feature routes --
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeView(),
      bindings: [
        AuthBinding(),
        HomeBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.THREAT_DETAIL,
      page: () => const ThreatDetailView(),
      binding: ThreatBinding(),
    ),
    GetPage(
      name: AppRoutes.PASSWORD_CHECKER,
      page: () => const PasswordCheckerView(),
      binding: PasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.LIBRARY,
      page: () => const LibraryView(),
      binding: KnowledgeBinding(),
    ),
    GetPage(
      name: AppRoutes.LIBRARY_CATEGORY,
      page: () => const ArticleListView(),
      binding: KnowledgeBinding(),
    ),
    GetPage(
      name: AppRoutes.LIBRARY_ARTICLE,
      page: () => const ArticleReaderView(),
      binding: KnowledgeBinding(),
    ),
    GetPage(
      name: AppRoutes.ALERTS,
      page: () => const AlertsView(),
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),

    // -- Initial route --
    GetPage(
      name: AppRoutes.INITIAL,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
  ];
}
