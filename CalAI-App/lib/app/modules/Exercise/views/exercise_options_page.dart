import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'run_exercise_page.dart';
import 'weight_lifting_exercise_page.dart';
import 'describe_exercise_page.dart';
import 'manual_exercise_page.dart';

class ExerciseOptionsPage extends StatelessWidget {
  const ExerciseOptionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Exercise',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Exercise',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 32),
            _buildExerciseCard(
              icon: Icons.directions_run_outlined,
              title: 'Run',
              description: 'Running, jogging, sprinting, etc.',
              onTap: () => Get.to(() => RunExercisePage()),
            ),
            SizedBox(height: 16),
            _buildExerciseCard(
              icon: Icons.fitness_center_outlined,
              title: 'Weight lifting',
              description: 'Machines, free weights, etc.',
              onTap: () => Get.to(() => WeightLiftingExercisePage()),
            ),
            SizedBox(height: 16),
            _buildExerciseCard(
              icon: Icons.edit_outlined,
              title: 'Describe',
              description: 'Write your workout in text',
              onTap: () => Get.to(() => DescribeExercisePage()),
            ),
            SizedBox(height: 16),
            _buildExerciseCard(
              icon: Icons.local_fire_department_outlined,
              title: 'Manual',
              description: 'Enter exactly how many calories you burned',
              onTap: () => Get.to(() => ManualExercisePage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5), // Very light grey
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: Icon(
                icon,
                color: Colors.black,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}