import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/models/AI/exercise_record.dart';
import 'package:CalAI/app/constants/enums.dart';

class ManualExercisePage extends StatefulWidget {
  final NutritionRecord? existingRecord;  // ADD THIS
  
  const ManualExercisePage({
    Key? key,
    this.existingRecord,  // ADD THIS
  }) : super(key: key);

  @override
  State<ManualExercisePage> createState() => _ManualExercisePageState();
}

class _ManualExercisePageState extends State<ManualExercisePage> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _exerciseNameController = TextEditingController(text: 'Manual Exercise');
  bool _isLogging = false;
  int _calories = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing existing exercise
    if (widget.existingRecord?.exerciseRecord != null) {
      final exercise = widget.existingRecord!.exerciseRecord!;
      _exerciseNameController.text = exercise.exerciseType;
      _caloriesController.text = exercise.caloriesBurned.toString();
      _calories = exercise.caloriesBurned;
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _exerciseNameController.dispose();
    super.dispose();
  }

  void _onCaloriesChanged(String value) {
    setState(() {
      _calories = int.tryParse(value) ?? 0;
    });
  }

  Future<void> _logExercise() async {
    if (_calories <= 0) {
      Get.snackbar(
        'Invalid Input',
        'Please enter calories burned greater than 0',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.red,
      );
      return;
    }

    setState(() {
      _isLogging = true;
    });

    try {
      // Get the scanner controller
      final ScannerController scannerController = Get.find<ScannerController>();
      
      // Create an exercise record
      final exerciseRecord = ExerciseRecord(
        exerciseType: _exerciseNameController.text.trim().isEmpty 
            ? 'Manual Exercise' 
            : _exerciseNameController.text.trim(),
        intensity: 'Medium',
        duration: 0, // Manual entry doesn't have duration
        caloriesBurned: _calories,
        recordTime: widget.existingRecord?.recordTime ?? DateTime.now(),
      );
      
      // Create a NutritionRecord for the exercise
      final nutritionRecord = NutritionRecord(
        exerciseRecord: exerciseRecord,
        recordTime: widget.existingRecord?.recordTime ?? DateTime.now(),
        processingStatus: ProcessingStatus.COMPLETED,
        isExercise: true,
      );
      
      // Check if we're editing an existing record
      if (widget.existingRecord != null) {
        // EDITING MODE: Update existing record
        final oldCalories = widget.existingRecord!.exerciseRecord?.caloriesBurned ?? 0;
        final caloriesDifference = _calories - oldCalories;
        
        // Find and replace the existing record in the list
        final index = scannerController.dailyRecords.indexWhere(
          (record) => record.recordTime == widget.existingRecord!.recordTime
        );
        
        if (index != -1) {
          scannerController.dailyRecords[index] = nutritionRecord;
        }
        
        // Update burned calories (add the difference)
        scannerController.burnedCalories.value += caloriesDifference;
        
        // Update the existing nutrition records
        if (scannerController.existingNutritionRecords != null) {
          scannerController.existingNutritionRecords!.dailyBurnedCalories += caloriesDifference;
          
          // Find and replace in the existing records list
          final existingIndex = scannerController.existingNutritionRecords!.dailyRecords.indexWhere(
            (record) => record.recordTime == widget.existingRecord!.recordTime
          );
          
          if (existingIndex != -1) {
            scannerController.existingNutritionRecords!.dailyRecords[existingIndex] = nutritionRecord;
          }
        }
        
        Get.snackbar(
          'Updated! ✓',
          'Exercise updated: $_calories calories burned',
          backgroundColor: Colors.blue.withOpacity(0.2),
          colorText: Colors.blue,
          duration: Duration(seconds: 2),
        );
      } else {
        // NEW MODE: Add new record
        // Add the exercise record to daily records (at the beginning)
        scannerController.dailyRecords.insert(0, nutritionRecord);
        
        // Update burned calories in the controller
        scannerController.burnedCalories.value += _calories;
        
        // Update the existing nutrition records with new burned calories
        if (scannerController.existingNutritionRecords != null) {
          scannerController.existingNutritionRecords!.dailyBurnedCalories += _calories;
          // Also add to the dailyRecords list in the existing records
          scannerController.existingNutritionRecords!.dailyRecords.insert(0, nutritionRecord);
        }
        
        Get.snackbar(
          'Success! 🎉',
          'Exercise logged: $_calories calories burned',
          backgroundColor: Colors.green.withOpacity(0.2),
          colorText: Colors.green,
          duration: Duration(seconds: 2),
        );
      }
      
      // IMPORTANT: Notify all GetBuilder listeners to update UI
      scannerController.update();
      
      await Future.delayed(Duration(milliseconds: 300));
      
      // Navigate back to home page
      await Future.delayed(Duration(milliseconds: 800));
      
      // Close all exercise pages and return to home
      Get.until((route) => route.isFirst);
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log exercise: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.red,
      );
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage for pie chart (max 500 calories for full circle)
    double percent = (_calories / 500).clamp(0.0, 1.0);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MealAIColors.blackText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manual Entry',
          style: TextStyle(
            color: MealAIColors.blackText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Your Exercise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MealAIColors.blackText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manually enter the calories you burned during your workout.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Exercise name input (optional)
            Text(
              'Exercise Name (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MealAIColors.blackText,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _exerciseNameController,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: MealAIColors.blackText,
                ),
                decoration: InputDecoration(
                  hintText: 'E.g., Workout Session, Sports, etc.',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  icon: Icon(Icons.edit, color: Colors.grey[700], size: 20),
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Calories burned section with pie chart
            Text(
              'Calories Burned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MealAIColors.blackText,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _calories > 0 
                      ? Colors.black
                      : Colors.grey[300]!,
                  width: _calories > 0 ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_calories > 0 ? 0.05 : 0.02),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Pie chart on the left
                  CircularPercentIndicator(
                    radius: 50,
                    lineWidth: 10.0,
                    animation: true,
                    animationDuration: 500,
                    percent: percent,
                    backgroundColor: Colors.grey.shade200,
                    progressColor: Colors.black,
                    circularStrokeCap: CircularStrokeCap.round,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: _calories > 0 ? Colors.black : Colors.grey,
                          size: 28,
                        ),
                        if (_calories > 500)
                          Text(
                            '500+',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Input box on the right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _caloriesController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: _calories > 0 
                                      ? Colors.black 
                                      : Colors.grey,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: _onCaloriesChanged,
                              ),
                            ),
                            Text(
                              'cals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          _calories > 500 
                              ? 'Great workout! 🔥'
                              : _calories > 200
                                  ? 'Good effort! 💪'
                                  : _calories > 0
                                      ? 'Keep it up!'
                                      : 'Enter calories burned',
                          style: TextStyle(
                            fontSize: 12,
                            color: _calories > 0 
                                ? Colors.black 
                                : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Info box
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Use a fitness tracker or online calculator to estimate your calories burned.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Log button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLogging || _calories <= 0
                    ? null
                    : _logExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLogging || _calories <= 0
                      ? Colors.grey[300]
                      : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLogging
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.grey[600],
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            widget.existingRecord != null ? 'Updating...' : 'Logging...',  // UPDATED
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.existingRecord != null ? 'Update Exercise' : 'Log Exercise',  // UPDATED
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _calories <= 0 
                              ? Colors.grey[500] 
                              : Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}