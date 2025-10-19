import 'package:get/get.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/models/Auth/user_repo.dart';

class UserController extends GetxController {
  // ====================
  // REACTIVE STATE
  // ====================
  
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  
  // ====================
  // GETTERS
  // ====================
  
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get hasUser => _userModel.value != null;
  
  // ====================
  // DEPENDENCIES
  // ====================
  
  final UserRepository userRepository;
  
  UserController({required this.userRepository});
  
  // ====================
  // PUBLIC METHODS
  // ====================
  
  /// Load user data from repository
  Future<void> loadUser(String userId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      
      final user = await userRepository.getUserById(userId);
      _userModel.value = user;
      
      _isLoading.value = false;
    } catch (e) {
      _errorMessage.value = 'Failed to load user: $e';
      _isLoading.value = false;
      print('Error loading user: $e');
    }
  }
  
  /// Set user data directly
  void setUser(UserModel user) {
    _userModel.value = user;
  }
  
  /// Update user data in repository
  Future<void> updateUser(UserModel user) async {
    try {
      await userRepository.setUserData(user);
      _userModel.value = user;
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }
  
  /// Clear user data
  void clearUser() {
    _userModel.value = null;
  }
}