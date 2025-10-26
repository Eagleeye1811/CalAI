import 'package:calai/app/repo/meal_ai_repo.dart';
import 'package:calai/app/repo/nutrition_record_repo.dart';
import 'package:calai/app/repo/storage_service.dart';
import 'package:calai/app/repo/agent_service.dart';
import 'package:calai/app/repo/firebase_user_repo.dart';
import 'package:calai/app/models/Auth/user_repo.dart';
import 'package:calai/app/controllers/auth_controller.dart';
import 'package:calai/app/controllers/user_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get/get.dart';

final serviceLocator = GetIt.instance;

Future<void> setupRegistry() async {
  // ====================
  // 1. REPOSITORIES (GetIt - Singleton Pattern)
  // ====================
  
  serviceLocator.registerLazySingleton<UserRepository>(() => FirebaseUserRepo());
  serviceLocator.registerLazySingleton<AiRepository>(() => AiRepository());
  serviceLocator.registerLazySingleton<NutritionRecordRepo>(() => NutritionRecordRepo());
  serviceLocator.registerLazySingleton<StorageService>(() => StorageService());
  serviceLocator.registerLazySingleton<AgentService>(() => AgentService());
  
  // ====================
  // 2. GLOBAL CONTROLLERS (GetX - Permanent Controllers)
  // ====================
  
  // AuthController - Global, survives all navigation
  Get.put(
    AuthController(userRepository: serviceLocator<UserRepository>()),
    permanent: true,
  );
  
  // UserController - Global, survives all navigation
  Get.put(
    UserController(userRepository: serviceLocator<UserRepository>()),
    permanent: true,
  );
}