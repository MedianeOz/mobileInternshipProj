// lib/app/utils/constants.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background   = Color(0xFF0D0F14);
  static const surface      = Color(0xFF1A1D26);
  static const border       = Color(0xFF2A2D3A);
  static const textMuted    = Color(0xFF8A8F9E);
  static const textHint     = Color(0xFF4A5568);
  static const primary      = Color(0xFF00E5A0);
  static const primaryDark  = Color(0xFF00C853);
  static const danger       = Color(0xFFFF4444);
  static const warning      = Color(0xFFE5A000);
}

class AppStrings {
  AppStrings._();

  static const appName     = 'CYBERSHIELD';
  static const nvdBaseUrl  = 'https://services.nvd.nist.gov/rest/json/cves/2.0';
  static const hibpApiUrl  = 'https://api.pwnedpasswords.com/range';
}
