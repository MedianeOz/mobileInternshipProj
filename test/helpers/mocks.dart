import 'package:cybershield_app/app/controllers/profile_controller.dart';
import 'package:cybershield_app/app/services/api_service.dart';
import 'package:cybershield_app/app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<AuthService>(),
  MockSpec<FirebaseAuth>(),
  MockSpec<FlutterSecureStorage>(),
  MockSpec<GoogleSignIn>(),
  MockSpec<ProfileController>(),
  MockSpec<User>(),
  MockSpec<UserCredential>(),
])
void main() {}
