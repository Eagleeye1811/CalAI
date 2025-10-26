import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:CalAI/app/components/dialogs.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/constants/constants.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/models/Auth/user_repo.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/modules/DashBoard/view/dashboard.dart';
import 'package:CalAI/app/repo/firebase_user_repo.dart';
import 'package:CalAI/app/utility/registry_service.dart';

class SignInScreen extends StatefulWidget {
  final UserBasicInfo? user;
  const SignInScreen({super.key, this.user});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSigningIn = false;
  String? _errorMsg;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMsg = null;
    });

    try {
      // Get the UserRepository from GetX
      final userRepository = serviceLocator<UserRepository>();
      
      // Sign in with Google
      final userModel = await userRepository.signInWithGoogle();
      
      // If we have user info from onboarding, update the user model
      if (widget.user != null) {
        final updatedUser = userModel.copyWith(
          userInfo: widget.user,
          updatedAt: DateTime.now(),
        );
        
        // Save the complete user data to Firebase
        await userRepository.setUserData(updatedUser);
        
        // Update AuthController
        final authController = Get.find<AuthController>();
        authController.updateMyUser(updatedUser);
      }
      
            // Show success message
      AppDialogs.showSuccessSnackbar(
        title: 'Welcome to CalAI!',
        message: 'You have successfully signed in',
      );
      
      // Navigate to HomeScreen
      Get.offAll(() => const HomeScreen());
      
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception:', '').trim();
        _isSigningIn = false;
      });
      
      AppDialogs.showErrorSnackbar(
        title: 'Sign In Failed',
        message: _errorMsg ?? 'An error occurred during sign in',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 60,
                  color: context.textColor,
                ),
              ),

              const SizedBox(height: 40),
              
              // Welcome Text
              Text(
                'Welcome to ${AppConstants.appName}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                widget.user != null 
                    ? 'Almost there! Sign in to save your personalized nutrition plan.'
                    : 'Your AI-powered nutrition companion',
                style: TextStyle(
                  fontSize: 16,
                  color: context.textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Error Message
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Google Sign-In Button
              ElevatedButton(
                onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.white : Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: context.borderColor,
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
                child: _isSigningIn
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            MealAIColors.lightPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/png/google_logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.g_mobiledata, size: 24);
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Privacy Notice
              Text(
                'By continuing, you agree to CalAI\'s Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textColor.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}