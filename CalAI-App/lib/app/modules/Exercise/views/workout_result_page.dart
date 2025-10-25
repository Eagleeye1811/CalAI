import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/models/AI/exercise_record.dart';
import 'package:CalAI/app/constants/enums.dart';

class WorkoutResultPage extends StatefulWidget {
  final String exerciseType;
  final String intensity;
  final int duration;
  final int burnedCalories;
  final NutritionRecord? existingRecord;

  const WorkoutResultPage({
    Key? key,
    required this.exerciseType,
    required this.intensity,
    required this.duration,
    required this.burnedCalories,
    this.existingRecord,
  }) : super(key: key);

  @override
  State<WorkoutResultPage> createState() => _WorkoutResultPageState();
}

class _WorkoutResultPageState extends State<WorkoutResultPage> {
  late TextEditingController _caloriesController;
  bool _isLogging = false;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController(
      text: widget.burnedCalories.toString(),
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _logWorkout() async {
    setState(() {
      _isLogging = true;
    });

    try {
      final int calories = int.tryParse(_caloriesController.text) ?? 0;
      
      if (calories <= 0) {
        Get.snackbar(
          'Invalid Input',
          'Please enter valid calories burned',
          backgroundColor: Colors.red.withOpacity(0.2),
          colorText: Colors.red,
        );
        setState(() {
          _isLogging = false;
        });
        return;
      }

      // Get the scanner controller
      final ScannerController scannerController = Get.find<ScannerController>();
      
      // Create an exercise record
      final exerciseRecord = ExerciseRecord(
        exerciseType: widget.exerciseType,
        intensity: widget.intensity,
        duration: widget.duration,
        caloriesBurned: calories,
        recordTime: widget.existingRecord?.recordTime ?? DateTime.now(),
      );
      
      // Create a NutritionRecord for the exercise
      final nutritionRecord = NutritionRecord(
        exerciseRecord: exerciseRecord,
        recordTime: widget.existingRecord?.recordTime ?? DateTime.now(),
        processingStatus: ProcessingStatus.COMPLETED,
        isExercise: true,
        entrySource: EntrySource.EXERCISE, // ADD THIS
      );
      
      // Check if we're editing an existing record
      if (widget.existingRecord != null) {
        // EDITING MODE: Update existing record
        final oldCalories = widget.existingRecord!.exerciseRecord?.caloriesBurned ?? 0;
        final caloriesDifference = calories - oldCalories;
        
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
        
        // IMPORTANT: Notify all GetBuilder listeners to update UI
        scannerController.update();
        
        await Future.delayed(Duration(milliseconds: 300));
        
        Get.snackbar(
          'Updated! ✓',
          'Exercise updated: $calories calories burned',
          backgroundColor: Colors.blue.withOpacity(0.2),
          colorText: Colors.blue,
          duration: Duration(seconds: 2),
        );
      } else {
        // NEW MODE: Add new record
        // Add the exercise record to daily records (at the beginning)
        scannerController.dailyRecords.insert(0, nutritionRecord);
        
        // Update burned calories in the controller
        scannerController.burnedCalories.value += calories;
        
        // Update the existing nutrition records with new burned calories
        if (scannerController.existingNutritionRecords != null) {
          scannerController.existingNutritionRecords!.dailyBurnedCalories += calories;
          scannerController.existingNutritionRecords!.dailyRecords.insert(0, nutritionRecord);
        }
        
        // IMPORTANT: Notify all GetBuilder listeners to update UI
        scannerController.update();
        
        await Future.delayed(Duration(milliseconds: 300));
        
        Get.snackbar(
          'Success! 🎉',
          'Workout logged: $calories calories burned',
          backgroundColor: Colors.green.withOpacity(0.2),
          colorText: Colors.green,
          duration: Duration(seconds: 2),
        );
      }
      
      // Navigate back to home page
      await Future.delayed(Duration(milliseconds: 800));
      
      // Close all exercise pages and return to home
      Get.until((route) => route.isFirst);
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log workout: $e',
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
    final bool isEditMode = widget.existingRecord != null;
    
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Update Workout' : 'Workout Summary',
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.tileColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.textColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isEditMode ? Icons.edit : Icons.check_circle,
                      size: 80,
                      color: context.textColor,
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  Text(
                    isEditMode ? 'Update your workout' : 'Your workout burned',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Editable calories display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'cals',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: context.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Workout details
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.borderColor,
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
                      children: [
                        _buildDetailRow(
                          icon: Icons.fitness_center,
                          label: 'Exercise',
                          value: widget.exerciseType,
                        ),
                        Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.speed,
                          label: 'Intensity',
                          value: widget.intensity,
                        ),
                        Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.timer,
                          label: 'Duration',
                          value: '${widget.duration} mins',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Log it / Update button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLogging ? null : _logWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLogging
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: context.cardColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditMode ? 'Update' : 'Log It',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.cardColor,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: context.textColor.withOpacity(0.6), size: 24),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: context.textColor.withOpacity(0.6),
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
      ],
    );
  }
}