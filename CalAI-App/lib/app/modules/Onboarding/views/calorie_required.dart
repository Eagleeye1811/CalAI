import 'dart:async';

import 'package:flutter/material.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/modules/Auth/views/sign_in_screen.dart';
import 'package:CalAI/app/utility/user_utility.dart';

import 'package:get/get.dart';
class DailyCalorieRequired extends StatefulWidget {
  final UserBasicInfo userBasicInfo;

  const DailyCalorieRequired({
    super.key,
    required this.userBasicInfo,
  });

  @override
  State<DailyCalorieRequired> createState() => _DailyCalorieRequiredState();
}

class _DailyCalorieRequiredState extends State<DailyCalorieRequired>
    with SingleTickerProviderStateMixin {
  bool _isCalculating = true;
  double _progress = 0.0;
  late Timer _timer;
  UserMacros? _userMacros;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _startCalculation();
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startCalculation() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.01;
        } else {
          _timer.cancel();
          _isCalculating = false;
          _animationController.forward();
        }
      });
    });

    _calculateNutrition();
  }

  void _calculateNutrition() {
    final user = widget.userBasicInfo;
    double height = user.currentHeight!;
    double weight = user.currentWeight!;
    double targetWeight = user.desiredWeight!;

    _userMacros = EnhancedUserNutrition.calculateNutritionWithoutActivityLevel(
      user.selectedGender,
      user.birthDate,
      height,
      weight,
      user.selectedPace,
      targetWeight,
      user.selectedGoal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: _isCalculating ? _buildCalculatingView() : _buildResultsView(),
      ),
    );
  }

  Widget _buildCalculatingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Creating your plan",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: context.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 10),
                Text(
                  "${(_progress * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _getProgressMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textColor.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressMessage() {
    if (_progress < 0.3) {
      return "Analyzing your metrics...";
    } else if (_progress < 0.6) {
      return "Calculating nutritional needs...";
    } else if (_progress < 0.9) {
      return "Finalizing your plan...";
    } else {
      return "Almost ready!";
    }
  }

  Widget _buildResultsView() {
    final macros = _userMacros!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Your Nutrition Plan",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getHealthModeText(),
              style: TextStyle(
                fontSize: 16,
                color: context.textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              title: "Daily Calories",
              value: "${macros.calories}",
              unit: "kcal",
            ),
            const SizedBox(height: 30),
            Text(
              "Macronutrients",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMacroCard(
                    "Protein",
                    macros.protein,
                    "g",
                    _calculatePercentage(macros.protein * 4, macros.calories),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildMacroCard(
                    "Carbs",
                    macros.carbs,
                    "g",
                    _calculatePercentage(macros.carbs * 4, macros.calories),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildMacroCard(
                    "Fat",
                    macros.fat,
                    "g",
                    _calculatePercentage(macros.fat * 9, macros.calories),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Recommendations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildRecommendationCard(
                    "Water",
                    macros.water,
                    "ml",
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildRecommendationCard(
                    "Fiber",
                    macros.fiber,
                    "g",
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  UserBasicInfo updatedUserBasicInfo =
                      widget.userBasicInfo.copyWith(
                    userMacros: _userMacros,
                  );

                  Get.to(() => SignInScreen(user: updatedUserBasicInfo));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getHealthModeText() {
    switch (widget.userBasicInfo.selectedGoal) {
      case HealthMode.weightLoss:
        return "Weight Loss Plan";
      case HealthMode.muscleGain:
        return "Muscle Gain Plan";
      case HealthMode.maintainWeight:
        return "Weight Maintenance Plan";
      default:
        return "Personalized Plan";
    }
  }

  double _calculatePercentage(int macroCalories, int totalCalories) {
    return macroCalories / totalCalories;
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    String title,
    int value,
    String unit,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
              Text(
                "${(percentage * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: CircularProgressIndicator(
                  value: percentage,
                  backgroundColor: context.borderColor,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  strokeWidth: 8,
                ),
              ),
              Column(
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    String title,
    int value,
    String unit,
  ) {
    IconData icon = title == "Water" ? Icons.water_drop : Icons.grass;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: context.textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
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
        ],
      ),
    );
  }
}