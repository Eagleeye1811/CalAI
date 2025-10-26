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
import 'package:CalAI/app/modules/FoodDatabase/views/nutrition_detail_page.dart';

class NutritionCard extends StatelessWidget {
  final NutritionRecord nutritionRecord;
  final UserModel userModel;

  const NutritionCard({
    Key? key,
    required this.nutritionRecord,
    required this.userModel,
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
    if (nutritionRecord.isExercise && nutritionRecord.exerciseRecord != null) {
      return _buildExerciseCard(context);
    }
    
    final totals = _totalNutrition;
    final isProcessing =
        nutritionRecord.processingStatus == ProcessingStatus.PROCESSING;

    return Bounceable(
      onTap: () {
        if (isProcessing) return;
        _navigateToDetailPage();
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.tileColor,
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
              padding: const EdgeInsets.only(left: 16.0),
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
                            context.textColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Analyzing your food...",
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "We're calculating the nutritional value",
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textColor.withOpacity(0.6),
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
    
    final hasImage = (nutritionRecord.nutritionInputQuery?.imageFilePath != null) ||
        (nutritionRecord.nutritionInputQuery?.imageUrl != null &&
            nutritionRecord.nutritionInputQuery!.imageUrl!.isNotEmpty);

    Widget contentSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Hero(
                tag: 'food-name-${nutritionRecord.recordTime?.toIso8601String() ?? DateTime.now().toIso8601String()}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    foodName ?? "Unknown Food",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              DateUtility.getTimeFromDateTime(
                nutritionRecord.recordTime!.toLocal(),
              ),
              style: TextStyle(
                fontSize: 14,
                color: context.textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: context.textColor,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              "${totals['calories']} calories",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
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

    if (!hasImage) {
      return Container(
        child: contentSection,
      );
    }
    
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildFoodImage(context, 35.w, 140),
          SizedBox(width: 16),
          Expanded(
            child: contentSection,
          ),
        ],
      ),
    );
  }

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
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodImage(BuildContext context, double width, double height) {
    return Hero(
      tag: 'food-image-${nutritionRecord.recordTime?.toIso8601String() ?? DateTime.now().toIso8601String()}',
      child: ClipRRect(
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
                  imageUrl: nutritionRecord.nutritionInputQuery!.imageUrl.toString(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildImagePlaceholder(context),
                  errorWidget: (context, url, error) => _buildImageError(context),
                )
              else
                _buildImagePlaceholder(context),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      context.textColor.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      color: context.tileColor,
      child: Center(
        child: Icon(
          Icons.restaurant,
          color: context.textColor.withOpacity(0.4),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImageError(BuildContext context) {
    return Container(
      color: context.tileColor,
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red.withOpacity(0.6),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context) {
    final exercise = nutritionRecord.exerciseRecord!;
    
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
          color: context.tileColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(0),
              child: Icon(
                exerciseIcon,
                color: context.textColor,
                size: 40,
              ),
            ),
            SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseType,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: context.textColor,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${exercise.caloriesBurned} calories',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.remove,
                        color: context.textColor.withOpacity(0.7),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      
                      Icon(
                        Icons.access_time,
                        color: context.textColor.withOpacity(0.7),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${exercise.duration} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Text(
              DateUtility.getTimeFromDateTime(
                nutritionRecord.recordTime!.toLocal(),
              ),
              style: TextStyle(
                fontSize: 14,
                color: context.textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      Get.dialog(
        AlertDialog(
          backgroundColor: Get.context!.cardColor,
          title: Text(exercise.exerciseType, style: TextStyle(color: Get.context!.textColor)),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Get.context!.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.speed, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Intensity: ${exercise.intensity}',
                    style: TextStyle(color: Get.context!.textColor),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Duration: ${exercise.duration} min',
                    style: TextStyle(color: Get.context!.textColor),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Close', style: TextStyle(color: Get.context!.textColor)),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToDetailPage() {
    if (nutritionRecord.entrySource == EntrySource.FOOD_DATABASE) {
      final ingredient = nutritionRecord.nutritionOutput?.response?.ingredients?.first;
      if (ingredient != null) {
        final foodMap = {
          'name': ingredient.name ?? 'Unknown Food',
          'calories': ingredient.calories ?? 0,
          'protein': ingredient.protein ?? 0,
          'carbs': ingredient.carbs ?? 0,
          'fat': ingredient.fat ?? 0,
          'fiber': ingredient.fiber ?? 0,
          'sugar': ingredient.sugar ?? 0,
          'sodium': ingredient.sodium ?? 0,
          'serving': nutritionRecord.nutritionOutput?.response?.portion?.split(' x').first ?? '1 serving',
        };
        
        Get.to(() => NutritionDetailPage(
          food: foodMap,
          existingRecord: nutritionRecord,
        ));
      }
    } else {
      Get.to(() => NutritionView(
        nutritionRecord: nutritionRecord,
        userModel: userModel,
      ));
    }
  }
}