import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calai/app/models/Auth/user_repo.dart';
import 'package:calai/app/models/Auth/user.dart';

enum AuthStatus { authenticated, unauthenticated, unknown }

class AuthController extends GetxController {
  // ====================
  // PRIVATE REACTIVE VARIABLES
  // ====================
  
  final Rx<AuthStatus> _status = AuthStatus.unknown.obs;
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _myUser = Rx<UserModel?>(null);
  
  late final StreamSubscription<User?> _userSubscription;
  
  // ====================
  // PUBLIC GETTERS
  // ====================
  
  AuthStatus get status => _status.value;
  User? get firebaseUser => _firebaseUser.value;
  UserModel? get myUser => _myUser.value;
  bool get isAuthenticated => _status.value == AuthStatus.authenticated;
  String? get userId => _firebaseUser.value?.uid;
  
  // ====================
  // DEPENDENCIES
  // ====================
  
  final UserRepository userRepository;
  
  AuthController({required this.userRepository});
  
  // ====================
  // LIFECYCLE METHODS
  // ====================
  
  @override
  void onInit() {
    super.onInit();
    
    // Listen to Firebase auth state changes
    _userSubscription = userRepository.user.listen((user) {
      _firebaseUser.value = user;
      
      if (user != null) {
        _status.value = AuthStatus.authenticated;
      } else {
        _status.value = AuthStatus.unauthenticated;
        _myUser.value = null;
      }
    });
  }
  
  @override
  void onClose() {
    _userSubscription.cancel();
    super.onClose();
  }
  
  // ====================
  // PUBLIC METHODS
  // ====================
  
  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _myUser.value = null;
      _status.value = AuthStatus.unauthenticated;
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  /// Update the current user model
  void updateMyUser(UserModel user) {
    _myUser.value = user;
  }
  
  /// Get the current user model (alias for myUser)
  UserModel? get userModel => _myUser.value;
}