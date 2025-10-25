import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/repo/firebase_user_repo.dart';
import 'package:CalAI/app/components/buttons.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sizer/sizer.dart';

class AdjustGoalsView extends StatefulWidget {
  UserBasicInfo? userBasicInfo;
  UserModel? userModel;
  UserMacros? userMacros;
  AdjustGoalsView(
      {super.key, this.userMacros, this.userBasicInfo, this.userModel});

  @override
  State<AdjustGoalsView> createState() => _AdjustGoalsViewState();
}

class _AdjustGoalsViewState extends State<AdjustGoalsView> {
  double _calories = 2000;
  double _protein = 150;
  double _carbs = 250;
  double _fat = 65;
  double _water = 8;
  double _fiber = 25;

  bool _isLoading = false;
  String? _editingNutrient;
  late TextEditingController _editController;
  late FocusNode _editFocusNode;
  String _tempValue = '';

  @override
  void initState() {
    super.initState();

    if (widget.userMacros != null) {
      _calories = widget.userMacros!.calories.toDouble().clamp(1000, 4000);
      _protein = widget.userMacros!.protein.toDouble().clamp(50, 300);
      _carbs = widget.userMacros!.carbs.toDouble().clamp(50, 500);
      _fat = widget.userMacros!.fat.toDouble().clamp(20, 150);
      _water = widget.userMacros!.water.toDouble().clamp(4, 16);
      _fiber = widget.userMacros!.fiber.toDouble().clamp(10, 60);
    }

    _editController = TextEditingController();
    _editFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _startEditing(String nutrient, String currentValue) {
    setState(() {
      _editingNutrient = nutrient;
      _tempValue = currentValue;
      _editController.text = currentValue;
    });
    Future.delayed(Duration(milliseconds: 100), () {
      _editFocusNode.requestFocus();
    });
  }

  void _doneEditing(String nutrient) {
    final newValue = double.tryParse(_editController.text);
    if (newValue != null) {
      setState(() {
        switch (nutrient) {
          case 'Calorie goal':
            _calories = newValue.clamp(1000, 4000);
            break;
          case 'Protein goal':
            _protein = newValue.clamp(50, 300);
            break;
          case 'Carbs goal':
            _carbs = newValue.clamp(50, 500);
            break;
          case 'Fat goal':
            _fat = newValue.clamp(20, 150);
            break;
          case 'Water goal':
            _water = newValue.clamp(4, 16);
            break;
          case 'Fiber goal':
            _fiber = newValue.clamp(10, 60);
            break;
        }
        _editingNutrient = null;
      });
    }
  }

  void _revertEditing() {
    setState(() {
      _editingNutrient = null;
    });
  }

  Widget _buildNutrientCard({
    required String title,
    required String value,
    required String unit,
    required double currentValue,
    required double maxValue,
    required Color color,
  }) {
    double percent = (currentValue / maxValue).clamp(0.0, 1.0);
    bool isEditing = _editingNutrient == title;

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.textColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left side: Circular progress indicator
              CircularPercentIndicator(
                radius: 45,
                lineWidth: 10.0,
                animation: true,
                animationDuration: 800,
                percent: percent,
                backgroundColor: context.borderColor,
                progressColor: color,
                circularStrokeCap: CircularStrokeCap.round,
                center: Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: 5.w),
              // Right side: Title and value in same box
              Expanded(
                child: GestureDetector(
                  onTap: isEditing ? null : () => _startEditing(title, value),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.tileColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textColor.withOpacity(0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        isEditing
                            ? TextField(
                                controller: _editController,
                                focusNode: _editFocusNode,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  suffixText: unit,
                                  suffixStyle: TextStyle(
                                    fontSize: 16,
                                    color: context.textColor.withOpacity(0.6),
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: context.textColor,
                                    ),
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: context.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Done and Revert buttons when editing
          if (isEditing) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _revertEditing,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Revert',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textColor.withOpacity(0.6),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: () => _doneEditing(title),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _saveGoals() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final updatedMacros = UserMacros(
        calories: _calories.toInt(),
        protein: _protein.toInt(),
        carbs: _carbs.toInt(),
        fat: _fat.toInt(),
        water: _water.toInt(),
        fiber: _fiber.toInt(),
      );

      UserBasicInfo updatedUserBasicInfo = widget.userBasicInfo!.copyWith(
        userMacros: updatedMacros,
      );

      FirebaseUserRepo firebaseUserRepo = FirebaseUserRepo();

      UserModel updatedUserModel = widget.userModel!.copyWith(
        userInfo: updatedUserBasicInfo,
      );

      await firebaseUserRepo.updateUserData(
        updatedUserModel,
      );

      ScannerController scannerController = Get.find<ScannerController>();

      scannerController.updateNutritionValues(
        maxCalories: updatedUserModel.userInfo!.userMacros.calories,
        maxFat: updatedUserModel.userInfo!.userMacros.fat,
        maxProtein: updatedUserModel.userInfo!.userMacros.protein,
        maxCarb: updatedUserModel.userInfo!.userMacros.carbs,
      );

      if (mounted) {
        Navigator.pop(context, updatedMacros);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Goals updated successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to update goals. Please try again.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit nutrition goals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.textColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            _buildNutrientCard(
              title: 'Calorie goal',
              value: _calories.toInt().toString(),
              unit: 'kcal',
              currentValue: _calories,
              maxValue: 4000,
              color: MealAIColors.waterColor,
            ),
            _buildNutrientCard(
              title: 'Protein goal',
              value: _protein.toInt().toString(),
              unit: 'g',
              currentValue: _protein,
              maxValue: 300,
              color: MealAIColors.proteinColor,
            ),
            _buildNutrientCard(
              title: 'Carbs goal',
              value: _carbs.toInt().toString(),
              unit: 'g',
              currentValue: _carbs,
              maxValue: 500,
              color: MealAIColors.carbsColor,
            ),
            _buildNutrientCard(
              title: 'Fat goal',
              value: _fat.toInt().toString(),
              unit: 'g',
              currentValue: _fat,
              maxValue: 150,
              color: MealAIColors.fatColor,
            ),
            _buildNutrientCard(
              title: 'Water goal',
              value: _water.toInt().toString(),
              unit: 'cups',
              currentValue: _water,
              maxValue: 16,
              color: MealAIColors.waterColor,
            ),
            _buildNutrientCard(
              title: 'Fiber goal',
              value: _fiber.toInt().toString(),
              unit: 'g',
              currentValue: _fiber,
              maxValue: 60,
              color: Colors.brown,
            ),
            SizedBox(height: 2.h),
            SecondaryButton(
              text: 'Update Goals',
              onPressed: _saveGoals,
              isLoading: _isLoading,
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}