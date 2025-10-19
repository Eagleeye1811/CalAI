import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/modules/Exercise/views/exercise_options_page.dart';

class ExerciseOptionsSheet extends StatelessWidget {
  const ExerciseOptionsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Close the bottom sheet and navigate to the full page
    Future.microtask(() {
      Navigator.pop(context);
      Get.to(() => ExerciseOptionsPage());
    });
    
    return SizedBox.shrink();
  }
}