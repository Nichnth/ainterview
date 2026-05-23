import 'package:flutter/material.dart';

class AppSizes {
  AppSizes._();

  // Corner Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusCircular = 100.0;

  // Spacing & Padding Base Values
  static const double pSmall = 8.0;
  static const double pMedium = 16.0;
  static const double pLarge = 24.0;
  static const double pXLarge = 32.0;

  // Spacing Vertikal (SizedBox)
  static const vSpaceSmall = SizedBox(height: pSmall);
  static const vSpaceMedium = SizedBox(height: pMedium);
  static const vSpaceLarge = SizedBox(height: pLarge);
  static const vSpaceXLarge = SizedBox(height: pXLarge);

  // Spacing Horizontal (SizedBox)
  static const hSpaceSmall = SizedBox(width: pSmall);
  static const hSpaceMedium = SizedBox(width: pMedium);
  static const hSpaceLarge = SizedBox(width: pLarge);
}