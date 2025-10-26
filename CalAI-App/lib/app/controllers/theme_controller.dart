import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:CalAI/app/providers/theme_provider.dart' show textTheme;
import 'package:CalAI/app/constants/colors.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();
  
  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeTheme(currentTheme);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode.value);
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    bool? savedMode = prefs.getBool('isDarkMode');
    
    if (savedMode == null) {
      _isDarkMode.value = false;
    } else {
      _isDarkMode.value = savedMode;
    }
    
    // Apply theme after loading
    Get.changeTheme(currentTheme);
  }
  
  ThemeData get currentTheme => _isDarkMode.value ? darkTheme : lightTheme;
  
  // Theme-aware color getters
  Color get primaryColor => _isDarkMode.value 
      ? MealAIColors.darkPrimary 
      : MealAIColors.lightPrimary;
      
  Color get surfaceColor => _isDarkMode.value 
      ? MealAIColors.darkSurface 
      : MealAIColors.lightSurface;
      
  Color get textColor => _isDarkMode.value 
      ? MealAIColors.darkOnSurface 
      : MealAIColors.lightOnSurface;
      
  Color get secondaryTextColor => _isDarkMode.value 
      ? MealAIColors.darkOnPrimary 
      : MealAIColors.lightOnPrimary;
      
  Color get borderColor => _isDarkMode.value 
      ? MealAIColors.darkSecondaryVariant 
      : const Color(0xFFE8E8E8);
      
  Color get cardColor => _isDarkMode.value 
      ? MealAIColors.darkBackground 
      : Colors.white;
      
  Color get backgroundColor => _isDarkMode.value 
      ? MealAIColors.darkSurface 
      : const Color(0xFFF5F5F5);
  
  // Light Theme
    ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: textTheme,
    colorScheme: const ColorScheme.light(
        primary: MealAIColors.lightPrimary,
        secondary: MealAIColors.lightSecondary,
        onPrimary: MealAIColors.lightOnPrimary,
        surface: MealAIColors.lightSurface,
        onSurface: MealAIColors.lightOnSurface,
        outline: MealAIColors.lightSecondaryVariant,
    ),
    scaffoldBackgroundColor: MealAIColors.lightSurface,
    appBarTheme: const AppBarTheme(
        backgroundColor: MealAIColors.lightSurface,
        foregroundColor: MealAIColors.lightOnSurface,
    ),
    cardTheme: CardThemeData(  // ✅ Changed from CardTheme
        color: Colors.white,
        elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
        hintStyle: textTheme.bodyLarge,
        border: const OutlineInputBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.disabled)
                ? MealAIColors.lightSecondaryVariant
                : MealAIColors.lightPrimary,
        ),
        foregroundColor: WidgetStateProperty.all(MealAIColors.lightSurface),
        ),
    ),
    listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyLarge!.copyWith(
        color: MealAIColors.lightOnPrimary,
        ),
        iconColor: MealAIColors.lightOnPrimary,
    ),
    );

    // Dark Theme
    ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
        primary: MealAIColors.darkPrimary,
        secondary: MealAIColors.darkSecondary,
        onPrimary: MealAIColors.darkOnPrimary,
        surface: MealAIColors.darkSurface,
        onSurface: MealAIColors.darkOnSurface,
        outline: MealAIColors.darkSecondaryVariant,
    ),
    scaffoldBackgroundColor: MealAIColors.darkSurface,
    appBarTheme: const AppBarTheme(
        backgroundColor: MealAIColors.darkSurface,
        foregroundColor: MealAIColors.darkOnSurface,
    ),
    cardTheme: CardThemeData(  // ✅ Changed from CardTheme
        color: MealAIColors.darkBackground,
        elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
        hintStyle: textTheme.bodyLarge,
        border: const OutlineInputBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.disabled)
                ? MealAIColors.darkSecondaryVariant
                : MealAIColors.darkPrimary,
        ),
        foregroundColor: WidgetStateProperty.all(MealAIColors.darkSurface),
        ),
    ),
    listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyLarge!.copyWith(
        color: MealAIColors.darkOnPrimary,
        ),
        iconColor: MealAIColors.darkOnPrimary,
    ),
    );
}