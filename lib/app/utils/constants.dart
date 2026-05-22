// lib/app/utils/constants.dart
//
// Central design tokens, API endpoints, and fixed app values shared by
// CyberShield views, controllers, and services.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0D0F14);
  static const surface = Color(0xFF1A1D26);
  static const border = Color(0xFF2A2D3A);
  static const primary = Color(0xFF00E5A0);
  static const primaryDark = Color(0xFF00C853);
  static const danger = Color(0xFFFF4444);
  static const warning = Color(0xFFE5A000);
  static const textMuted = Color(0xFF8A8F9E);
  static const textHint = Color(0xFF4A5568);
  static const white = Color(0xFFFFFFFF);
}

class AppStrings {
  AppStrings._();

  static const appName = 'CYBERSHIELD';
  static const nvdBaseUrl = 'https://services.nvd.nist.gov/rest/json/cves/2.0';
  static const hibpBaseUrl = 'https://api.pwnedpasswords.com/range';
  static const nvdApiKey = '22c34afc-c129-4fa6-896f-a4676276fdb6';
  static const nvdResultsPerPage = 20;
  static const nvdRecentWindowDays = 120;
}

class AppHiveBoxes {
  AppHiveBoxes._();

  static const threatCache = 'threat_cache';
  static const profileCache = 'user_profile';
}
