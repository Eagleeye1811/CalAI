import 'dart:io';

import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/modules/Home/views/nutrition_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/constants/enums.dart';
import 'package:CalAI/app/models/AI/nutrition_output.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/utility/date_utility.dart';
import 'package:CalAI/app/models/AI/exercise_record.dart';
import 'package:CalAI/app/modules/Exercise/views/run_exercise_page.dart';
import 'package:CalAI/app/modules/Exercise/views/weight_lifting_exercise_page.dart';
import 'package:CalAI/app/modules/Exercise/views/describe_exercise_page.dart';
import 'package:CalAI/app/modules/Exercise/views/manual_exercise_page.dart';

class NutritionCard extends StatelessWidget {
  final NutritionRecord nutritionRecord;
  final UserModel userModel;
  // final void Function() onTap;

  const NutritionCard({
    Key? key,
    required this.nutritionRecord,
    required this.userModel,
    // required this.onTap,
  }) : super(key: key);

  Map<String, int> get _totalNutrition {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;

    if (nutritionRecord.nutritionOutput != null &&
        nutritionRecord.processingStatus != ProcessingStatus.PROCESSING) {
      final nutritionData =
          nutritionRecord.nutritionOutput!.response?.ingredients;
      for (Ingredient item in nutritionData ?? []) {
        totalCalories += item.calories!;
        totalProtein += item.protein!;
        totalCarbs += item.carbs!;
        totalFat += item.fat!;
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is an exercise record
    if (nutritionRecord.isExercise && nutritionRecord.exerciseRecord != null) {
      return _buildExerciseCard(context);
    }
    
    // Otherwise, show normal food card
    final totals = _totalNutrition;
    final isProcessing =
        nutritionRecord.processingStatus == ProcessingStatus.PROCESSING;

    return Bounceable(
      onTap: () {
        if (isProcessing) return;
        Get.to(() => NutritionView(
              nutritionRecord: nutritionRecord,
              userModel: userModel,
            ));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: EdgeInsets.all(16), // Added padding here
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5), // Light grey background to match exercise cards
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: isProcessing
            ? _buildProcessingCard(context)
            : _buildCompletedCard(context, totals),
      ),
    );
  }

  Widget _buildProcessingCard(BuildContext context) {
    return Container(
      height: 12.h,
      child: Row(
        children: [
          _buildFoodImage(context, 25.w, 12.h),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0), // Removed all padding since parent has it
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black), // Changed to black
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Analyzing your food...",
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "We're calculating the nutritional value",
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, Map<String, int> totals) {
  final foodName = nutritionRecord.nutritionOutput?.response!.foodName != null
      ? nutritionRecord.nutritionOutput?.response!.foodName
      : "Unknown Food";
  
  // Check if food has an actual image (not placeholder)
  final hasImage = (nutritionRecord.nutritionInputQuery?.imageFilePath != null) ||
      (nutritionRecord.nutritionInputQuery?.imageUrl != null &&
          nutritionRecord.nutritionInputQuery!.imageUrl!.isNotEmpty);

  // Build the content section (same for both layouts)
  Widget contentSection = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Food name and time
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              foodName ?? "Unknown Food",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600, // Changed from bold to w600
                color: Colors.black,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Text(
            DateUtility.getTimeFromDateTime(
              nutritionRecord.recordTime!.toLocal(),
            ),
            style: TextStyle(
              fontSize: 14, // Increased from 13
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      SizedBox(height: 12), // Increased from 8
      
      // Calories
      Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.black,
            size: 18,
          ),
          SizedBox(width: 6), // Increased from 4
          Text(
            "${totals['calories']} calories",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500, // Changed from w600
              color: Colors.black,
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      
      // Macros row with icons (consistent format)
      Row(
        children: [
          _buildSimpleMacroBadge(
            Icons.fitness_center,
            "${totals['protein']}g",
            Color(0xFFE57373),
          ),
          SizedBox(width: 12),
          _buildSimpleMacroBadge(
            Icons.grain,
            "${totals['carbs']}g",
            Color(0xFFFFB74D),
          ),
          SizedBox(width: 12),
          _buildSimpleMacroBadge(
            Icons.water_drop,
            "${totals['fat']}g",
            Color(0xFF64B5F6),
          ),
        ],
      ),
    ],
  );

  // If no image, show clean card without image section
  if (!hasImage) {
    return Container(
      child: contentSection,
    );
  }
  
  // If image exists, show card with image on left + same content
  return Container(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildFoodImage(context, 35.w, 140), // Adjusted size
        SizedBox(width: 16),
        Expanded(
          child: contentSection,
        ),
      ],
    ),
  );
}

  // Add this new helper method (add after _buildMacroNutrientBadge around line 374)
  Widget _buildSimpleMacroBadge(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodImage(BuildContext context, double width, double height) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Container(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (nutritionRecord.nutritionInputQuery?.imageFilePath != null)
              Image.file(
                File(nutritionRecord.nutritionInputQuery!.imageFilePath!),
                fit: BoxFit.cover,
              )
            else if (nutritionRecord.nutritionInputQuery?.imageUrl != null &&
                nutritionRecord.nutritionInputQuery!.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl:
                    nutritionRecord.nutritionInputQuery!.imageUrl.toString(),
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
              )
            else
              _buildImagePlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red[300],
          size: 32,
        ),
      ),
    );
  }

  Widget _buildNutritionBadgesRow(
      BuildContext context, Map<String, int> totals) {
    return Row(
      children: [
        Expanded(
            child: _buildMacroNutrientBadge(
          context,
          "PROTEIN",
          "${totals['protein']}g",
          MealAIColors.proteinColor,
          Icons.fitness_center_rounded,
        )),
        SizedBox(width: 2.w),
        Expanded(
            child: _buildMacroNutrientBadge(
          context,
          "CARBS",
          "${totals['carbs']}g",
          MealAIColors.carbsColor,
          Icons.grain_rounded,
        )),
        SizedBox(width: 2.w),
        Expanded(
            child: _buildMacroNutrientBadge(
          context,
          "FAT",
          "${totals['fat']}g",
          MealAIColors.fatColor,
          Icons.opacity_rounded,
        )),
      ],
    );
  }

  Widget _buildMacroNutrientBadge(BuildContext context, String label,
      String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChevron(BuildContext context) {
    return Container(
      width: 8.w,
      decoration: BoxDecoration(
        color: MealAIColors.darkPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.chevron_right_rounded,
          color: MealAIColors.darkPrimary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context) {
    final exercise = nutritionRecord.exerciseRecord!;
    
    // Determine icon based on exercise type
    IconData exerciseIcon = Icons.directions_run_outlined;
    
    if (exercise.exerciseType.toLowerCase().contains('run')) {
      exerciseIcon = Icons.directions_run_outlined;
    } else if (exercise.exerciseType.toLowerCase().contains('weight') || 
              exercise.exerciseType.toLowerCase().contains('lifting')) {
      exerciseIcon = Icons.fitness_center_outlined;
    } else if (exercise.exerciseType.toLowerCase().contains('walk')) {
      exerciseIcon = Icons.directions_walk_outlined;
    } else if (exercise.exerciseType.toLowerCase().contains('cycle') || 
              exercise.exerciseType.toLowerCase().contains('bike')) {
      exerciseIcon = Icons.directions_bike_outlined;
    } else {
      exerciseIcon = Icons.local_fire_department_outlined;
    }
    
    return GestureDetector(
      onTap: () {
        _navigateToExercisePage(exercise);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5), // Very light grey
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise icon on left
            Container(
              padding: EdgeInsets.all(0),
              child: Icon(
                exerciseIcon,
                color: Colors.black,
                size: 40,
              ),
            ),
            SizedBox(width: 16),
            
            // Exercise details (middle section)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    exercise.exerciseType,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Calories row
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.black,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${exercise.caloriesBurned} calories',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Intensity and duration row
                  Row(
                    children: [
                      // Intensity indicator (dash icon)
                      Icon(
                        Icons.remove,
                        color: Colors.grey[700],
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      
                      // Clock icon + duration
                      Icon(
                        Icons.access_time,
                        color: Colors.grey[700],
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${exercise.duration} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Time on the right
            Text(
              DateUtility.getTimeFromDateTime(
                nutritionRecord.recordTime!.toLocal(),
              ),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method to handle exercise navigation
  // Add this new method to handle exercise navigation
  void _navigateToExercisePage(ExerciseRecord exercise) {
    final exerciseType = exercise.exerciseType.toLowerCase();
    
    if (exerciseType.contains('run')) {
      Get.to(() => RunExercisePage(existingRecord: nutritionRecord));
    } else if (exerciseType.contains('weight') || exerciseType.contains('lifting')) {
      Get.to(() => WeightLiftingExercisePage(existingRecord: nutritionRecord));
    } else if (exerciseType.contains('describe')) {
      Get.to(() => DescribeExercisePage(existingRecord: nutritionRecord));
    } else if (exerciseType.contains('manual')) {
      Get.to(() => ManualExercisePage(existingRecord: nutritionRecord));
    } else {
      // For other exercise types, show a simple info dialog
      Get.dialog(
        AlertDialog(
          title: Text(exercise.exerciseType),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '${exercise.caloriesBurned} calories burned',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.speed, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Intensity: ${exercise.intensity}'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Duration: ${exercise.duration} min'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
