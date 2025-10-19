import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';  // ADD THIS
import 'package:CalAI/app/modules/Exercise/controllers/describe_exercise_controller.dart';
import 'workout_result_page.dart';

class DescribeExercisePage extends StatefulWidget {
  final NutritionRecord? existingRecord;  // ADD THIS
  
  const DescribeExercisePage({
    Key? key,
    this.existingRecord,  // ADD THIS
  }) : super(key: key);

  @override
  State<DescribeExercisePage> createState() => _DescribeExercisePageState();
}

class _DescribeExercisePageState extends State<DescribeExercisePage> {
  final TextEditingController _descriptionController = TextEditingController();
  final DescribeExerciseController _controller = Get.put(DescribeExerciseController());
  
  @override
  void initState() {
    super.initState();
    // Pre-fill if editing existing exercise
    if (widget.existingRecord?.exerciseRecord != null) {
      final exercise = widget.existingRecord!.exerciseRecord!;
      _descriptionController.text = '${exercise.exerciseType}, ${exercise.intensity} intensity, ${exercise.duration} minutes';
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MealAIColors.blackText, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Describe Exercise',
          style: TextStyle(
            color: MealAIColors.blackText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe Your Workout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MealAIColors.blackText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tell us what exercise you did, for how long, and at what intensity.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            
            // Examples section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.grey[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Examples:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• "I did 50 pushups in 2 minutes"',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '• "Intense cycling for 30 minutes"',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '• "Light yoga session for 15 mins"',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '• "30 burpees, high intensity"',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Text input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                style: TextStyle(
                  fontSize: 16,
                  color: MealAIColors.blackText,
                ),
                decoration: InputDecoration(
                  hintText: 'E.g., "I did pushups for 1 minute at medium intensity"',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            
            Spacer(),
            
            // Analyze button
            Obx(() => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _controller.isLoading.value
                    ? null
                    : () => _analyzeExercise(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _controller.isLoading.value
                      ? Colors.grey[300]
                      : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _controller.isLoading.value
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
                            'Analyzing...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Analyze Exercise',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeExercise() async {
    final description = _descriptionController.text.trim();
    
    if (description.isEmpty) {
      Get.snackbar(
        'Empty Description',
        'Please describe your workout',
        backgroundColor: Colors.orange.withOpacity(0.2),
        colorText: Colors.orange,
      );
      return;
    }
    
    try {
      final result = await _controller.analyzeExerciseDescription(description);
      
      if (result != null) {
        // Navigate to workout result page
        Get.to(() => WorkoutResultPage(
          exerciseType: result['exerciseName'] ?? 'Exercise',
          intensity: result['intensity'] ?? 'Medium',
          duration: result['duration'] ?? 0,
          burnedCalories: result['caloriesBurned'] ?? 0,
          existingRecord: widget.existingRecord,  // ADD THIS
        ));
      }
    } catch (e) {
      Get.snackbar(
        'Analysis Failed',
        'Could not analyze your workout. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.red,
      );
    }
  }
}