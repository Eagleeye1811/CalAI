import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MealAIColors {
  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF000000); // #000000
  static const Color lightPrimaryVariant = Color(0xFFB0BEC5); // #B0BEC5
  static const Color darkPrimaryVariant = Color(0xFF383838); // #383838
  static const Color darkSecondary = Color(0xFF434343); // #434343
  static const Color darkSecondaryVariant = Color(0xFF757575); // #757575
  static const Color darkSuccess = Color(0xFF00C853); // #00C853
  static const Color darkSuccessVariant = Color(0xFF66BB6A); // #66BB6A
  static const Color darkInfo = Color(0xFF2979FF); // #2979FF 
  static const Color darkInfoVariant = Color(0xFF80D8FF); // #80D8FF
  static const Color darkWarning = Color(0xFFFFB300); // #FFB300
  static const Color darkWarningVariant = Color(0xFFFFCC80); // #FFCC80
  static const Color darkError = Color(0xFFD32F2F); // #D32F2F
  static const Color darkErrorVariant = Color(0xFFEF9A9A); // #EF9A9A
  static const Color darkSurface = Color(0xFF121212); // #121212
  static const Color darkBackground = Color(0xFF1E1E1E); // #1E1E1E
  static const Color darkOnPrimary = Color(0xFFFFFFFF); // #FFFFFF
  static const Color darkOnSecondary = Color(0xFFFFFFFF); // #FFFFFF
  static const Color darkOnSuccess = Color(0xFF000000); // #000000
  static const Color darkOnInfo = Color(0xFF000000); // #000000
  static const Color darkOnWarning = Color(0xFF000000); // #000000
  static const Color darkOnError = Color(0xFFFFFFFF); // #FFFFFF
  static const Color darkOnSurface = Color(0xFFFFFFFF); // #FFFFFF
  static const Color darkOnBackground = Color(0xFFFFFFFF); // #FFFFFF

  // Light Theme Colors
  static const Color lightPrimary = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightSecondary = Color(0xFF000000); // #000000
  static const Color lightSecondaryVariant = Color(0xFF757575); // #757575
  static const Color lightSuccess = Color(0xFF4CAF50); // #4CAF50
  static const Color lightSuccessVariant = Color(0xFF81C784); // #81C784
  static const Color lightInfo = Color(0xFF0288D1); // #0288D1
  static const Color lightInfoVariant = Color(0xFF40C4FF); // #40C4FF
  static const Color lightWarning = Color(0xFFFFB300); // #FFB300
  static const Color lightWarningVariant = Color(0xFFFFCC80); // #FFCC80
  static const Color lightError = Color(0xFFD32F2F); // #D32F2F
  static const Color lightErrorVariant = Color(0xFFEF9A9A); // #EF9A9A
  static const Color lightSurface = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightBackground = Color(0xFFF5F5F5); // #F5F5F5
  static const Color lightOnPrimary = Color(0xFF000000); // #000000
  static const Color lightOnSecondary = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightOnSuccess = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightOnInfo = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightOnWarning = Color(0xFF000000); // #000000
  static const Color lightOnError = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightOnSurface = Color(0xFF000000); // #000000
  static const Color lightOnBackground = Color(0xFF000000); // #000000

  // Legacy/Utility Colors (kept for backwards compatibility)
  static Color lightGreyTile = "#F9F8FD".toColor();
  static Color grey = Colors.grey;
  static const Color selectedTile = Color(0xFF212121);
  static const Color switchWhiteColor = Color(0xFFFFFFFF);
  static const Color switchBlackColor = Color(0xFF000000);
  static const Color black = Color(0xFF000000);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color blackText = Color(0xFF000000);
  static const Color red = Color(0xFFFF0000);
  static Color blueGrey = "#514f62".toColor();
  static const Color stepperColor = Color(0xFFE0E0E0);
  static const Color greyLight = Color.fromRGBO(235, 235, 235, 1);

  // Functional Colors (these stay the same in both themes)
  static Color gaugeColor = Colors.grey.withOpacity(0.2);
  static Color proteinColor = "#E91E63".toColor(); // Pink for protein/strength
  static Color carbsColor = "#558B2F".toColor();
  static Color fatColor = Colors.blue;
  static Color waterColor = "#0288D1".toColor(); // Richer blue for water/hydration
  
  // Dark theme specific colors for tiles and cards
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkTile = Color(0xFF2C2C2C);
  static const Color darkBorder = Color(0xFF3A3A3A);
  
  // Light theme specific colors for tiles and cards
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTile = Color(0xFFF5F5F5);
  static const Color lightBorder = Color(0xFFE8E8E8);
}

// Extension for hex color conversion
extension HexColorExtension on String {
  Color toColor() {
    String hex = replaceAll("#", "").toUpperCase();
    if (hex.length == 6) {
      hex = "FF$hex"; // Add full opacity if not specified
    }
    return Color(int.parse("0x$hex"));
  }
}

// Theme-aware color extension for BuildContext
extension ThemeAwareColors on BuildContext {
  /// Returns the primary text color based on current theme
  Color get textColor => Theme.of(this).colorScheme.onSurface;
  
  /// Returns the surface/background color
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  
  /// Returns the primary color
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  
  /// Returns the secondary color
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  
  /// Returns the card background color
  Color get cardColor => Theme.of(this).cardTheme.color ?? surfaceColor;
  
  /// Returns the appropriate border color for current theme
  Color get borderColor => Theme.of(this).brightness == Brightness.dark
      ? MealAIColors.darkBorder 
      : MealAIColors.lightBorder;
  
  /// Returns the appropriate tile color for current theme
  Color get tileColor => Theme.of(this).brightness == Brightness.dark
      ? MealAIColors.darkTile 
      : MealAIColors.lightTile;
  
  /// Backwards compatible: returns black text in light mode, white in dark mode
  Color get blackText => Theme.of(this).brightness == Brightness.dark
      ? MealAIColors.whiteText 
      : MealAIColors.blackText;
      
  /// Backwards compatible: returns white text in light mode, black in dark mode
  Color get whiteText => Theme.of(this).brightness == Brightness.dark
      ? MealAIColors.blackText 
      : MealAIColors.whiteText;
  
  // Remove the isDarkMode getter - use GetX's instead
  
  /// Returns the appropriate background gradient colors
  List<Color> get backgroundGradient => Theme.of(this).brightness == Brightness.dark
      ? [MealAIColors.darkSurface, MealAIColors.darkBackground]
      : [const Color(0xFFF5F5F5), Colors.white];
}

// GetX-based theme-aware color extension (for use without BuildContext)
extension GetXThemeAwareColors on GetInterface {
  /// Returns the primary text color based on current theme
  Color get textColor => Get.theme.colorScheme.onSurface;
  
  /// Returns the surface/background color
  Color get surfaceColor => Get.theme.colorScheme.surface;
  
  /// Returns the primary color
  Color get primaryColor => Get.theme.colorScheme.primary;
  
  /// Returns the card background color
  Color get cardColor => Get.theme.cardTheme.color ?? surfaceColor;
  
  /// Returns the appropriate border color for current theme
  Color get borderColor => Get.theme.brightness == Brightness.dark
      ? MealAIColors.darkBorder 
      : MealAIColors.lightBorder;
  
  // Remove the isDarkMode getter - use GetX's instead
}