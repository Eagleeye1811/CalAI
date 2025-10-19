import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:CalAI/app/components/dialogs.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/constants/constants.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/modules/DashBoard/view/dashboard.dart';
import 'package:CalAI/app/repo/firebase_user_repo.dart';

import 'package:get/get.dart';
class SignInScreen extends StatefulWidget {
  final UserBasicInfo? user;
  const SignInScreen({super.key, this.user});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool signInRequired = false;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Google Sign-In without BLoC
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Sign In - Under Migration'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement Google Sign-In here
                // Use Get.find<AuthController>() for auth operations
              },
              child: Text('Sign In with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
