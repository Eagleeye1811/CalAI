import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/controllers/theme_controller.dart';
import 'package:CalAI/app/modules/DashBoard/view/dashboard.dart';
import 'package:CalAI/app/modules/Onboarding/views/onboarding_home.dart';
import 'package:CalAI/app/providers/remoteconfig.dart';
import 'package:CalAI/app/utility/registry_service.dart';
import 'package:CalAI/firebase_options.dart';
import 'package:CalAI/app/config/environment.dart';
import 'package:CalAI/app/repo/agent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  var remoteConfigService = await RemoteConfigService.getInstance();
  await remoteConfigService!.initialise();
  configLoading();
  
  // Setup GetIt services and GetX controllers
  await setupRegistry();
  
  // Initialize ThemeController
  Get.put(ThemeController());

  Environment.printConfig();

  final isHealthy = await AgentService.healthCheck();
  print('Backend Health Check: ${isHealthy ? "✅ HEALTHY" : "❌ UNAVAILABLE"}');
  if (isHealthy) {
    final info = await AgentService.getBackendInfo();
    if (info != null) {
      print('Backend Info: $info');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyAppView();
  }
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 40.0
    ..radius = 10.0
    ..userInteractions = false;
}

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Obx(() {
          final themeController = Get.find<ThemeController>();
          
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CalAI',
            theme: themeController.lightTheme,
            darkTheme: themeController.darkTheme,
            themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: EasyLoading.init(),
            
            // Use GetX Obx for reactive navigation
            home: Obx(() {
              final authController = Get.find<AuthController>();
              
              switch (authController.status) {
                case AuthStatus.authenticated:
                  return const HomeScreen();
                case AuthStatus.unauthenticated:
                  return const OnboardingHome();
                case AuthStatus.unknown:
                default:
                  return Scaffold(
                    backgroundColor: themeController.surfaceColor,
                    body: Center(
                      child: CircularProgressIndicator(
                        color: themeController.isDarkMode 
                            ? Colors.green 
                            : Colors.black,
                      ),
                    ),
                  );
              }
            }),
          );
        });
      },
    );
  }
}