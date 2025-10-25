import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/modules/Scanner/views/scan_view.dart';
import 'exercise_options_sheet.dart';
import 'scan_options_sheet.dart';
import 'package:CalAI/app/modules/FoodDatabase/views/food_database_page.dart';
import 'package:CalAI/app/modules/FoodDatabase/views/saved_foods_page.dart';
import 'package:CalAI/app/modules/Scanner/views/enhanced_scan_view.dart';
import 'package:CalAI/app/modules/Chat/Views/chat_view.dart';  


class ActionMenuBottomSheet extends StatelessWidget {
  const ActionMenuBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          
          // Title
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 16),
          
          // 2x2 Grid of options
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildActionBox(
                context: context,
                icon: Icons.fitness_center,
                title: 'Log Exercise',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _showExerciseOptions(context);
                },
              ),
              _buildActionBox(
                context: context,
                icon: Icons.bookmark,
                title: 'Saved Foods',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => const FoodDatabasePage(initialTabIndex: 3));
                },
              ),
              _buildActionBox(
                context: context,
                icon: Icons.restaurant_menu,
                title: 'Food Database',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => const FoodDatabasePage());
                },
              ),
              _buildActionBox(
                context: context,
                icon: Icons.camera_alt,
                title: 'Scan Food',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  // Navigate directly to camera screen
                  Get.to(() => EnhancedScanView(scanType: ScanType.scanFood));
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          
          // Full-width AI Chatbot button
          _buildFullWidthActionBox(
            context: context,
            icon: Icons.chat_bubble_outline,
            title: 'AI Nutrition Assistant',
            color: Colors.teal,
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const CalAIAgentView());
            },
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionBox({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.textColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: context.textColor,
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full-width button for AI Chatbot
  Widget _buildFullWidthActionBox({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.textColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: context.textColor,
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseOptionsSheet(),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ScanOptionsSheet(),
    );
  }
}