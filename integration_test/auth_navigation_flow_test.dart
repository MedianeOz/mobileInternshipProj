import 'package:cybershield_app/app/controllers/auth_controller.dart';
import 'package:cybershield_app/app/services/auth_service.dart';
import 'package:cybershield_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import '../test/helpers/mocks.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();

    final authService = MockAuthService();
    when(authService.currentUser).thenReturn(null);
    when(authService.authStateChanges).thenAnswer((_) => Stream.value(null));
    Get.put<AuthService>(authService);
    Get.put<AuthController>(AuthController());
  });

  tearDown(Get.reset);

  testWidgets('auth screens navigate on an emulator', (tester) async {
    await tester.pumpWidget(const CyberShieldApp());
    await tester.pumpAndSettle();

    expect(find.text('CYBERSHIELD'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);

    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);

    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });
}
