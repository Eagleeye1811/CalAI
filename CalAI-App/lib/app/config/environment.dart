import 'package:http/http.dart' as http;

/// Environment configuration for backend URLs
///
/// Usage:
/// - Local development: Change isLocalDevelopment to true
/// - Production: Change isLocalDevelopment to false
class Environment {
  // 🔧 CHANGE THIS BASED ON YOUR SETUP
  static const bool isLocalDevelopment = true;

  // 🖥️ LOCAL DEVELOPMENT URLs
  // UNCOMMENT THE ONE YOU NEED:

  // Option 1: Android emulator (most common)
  static const String _localBackendUrl = 'http://10.0.2.2:8000';

  // Option 2: iOS simulator (comment line 16 above and uncomment below)
  // static const String _localBackendUrl = 'http://localhost:8000';

  // Option 3: Physical device (comment line 16 above and uncomment below)
  // Replace XXX.XXX.XXX.XXX with your computer's IP address
  // static const String _localBackendUrl = 'http://XXX.XXX.XXX.XXX:8000';

  // 🌐 PRODUCTION URL
  static const String _productionBackendUrl =
      'https://CalAI-production.up.railway.app';

  /// Get the appropriate backend URL based on environment
  static String get backendUrl {
    return isLocalDevelopment ? _localBackendUrl : _productionBackendUrl;
  }

  /// Get full nutrition analysis endpoint
  static String get nutritionGetUrl => '$backendUrl/nutrition/get';

  /// Get full nutrition description endpoint
  static String get nutritionDescriptionUrl =>
      '$backendUrl/nutrition/description';

  /// Get full chat messages endpoint
  static String get chatMessagesUrl => '$backendUrl/chat/messages';

  /// Get full health check endpoint
  static String get healthCheckUrl => '$backendUrl/health';

  /// Check if backend is accessible
  static Future<bool> isBackendHealthy() async {
    try {
      final response = await http
          .get(
            Uri.parse(healthCheckUrl),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }

  /// Print current configuration (for debugging)
  static void printConfig() {
    print('=== Environment Configuration ===');
    print('Mode: ${isLocalDevelopment ? "LOCAL DEVELOPMENT" : "PRODUCTION"}');
    print('Backend URL: $backendUrl');
    print('================================');
  }
}
