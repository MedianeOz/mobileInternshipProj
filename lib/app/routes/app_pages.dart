import 'package:get/get.dart';
import '../views/home/home_view.dart';
import '../bindings/home_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.INITIAL,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
  ];
}
