import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'workout_result_page.dart';

class WeightLiftingExercisePage extends StatefulWidget {
  final NutritionRecord? existingRecord;
  
  const WeightLiftingExercisePage({
    Key? key,
    this.existingRecord,
  }) : super(key: key);

  @override
  State<WeightLiftingExercisePage> createState() => _WeightLiftingExercisePageState();
}

class _WeightLiftingExercisePageState extends State<WeightLiftingExercisePage> {
  String _selectedIntensity = '';
  int _duration = 0;
  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing existing exercise
    if (widget.existingRecord?.exerciseRecord != null) {
      final exercise = widget.existingRecord!.exerciseRecord!;
      _selectedIntensity = exercise.intensity;
      _duration = exercise.duration;
      _durationController.text = exercise.duration.toString();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  bool get _canContinue => _selectedIntensity.isNotEmpty && _duration > 0;

  int _calculateCalories() {
    // Calories per minute based on intensity (weight lifting burns less than running)
    double caloriesPerMinute = 0;
    switch (_selectedIntensity) {
      case 'High':
        caloriesPerMinute = 9.0; // Heavy compound lifts
        break;
      case 'Medium':
        caloriesPerMinute = 6.0; // Moderate weights
        break;
      case 'Low':
        caloriesPerMinute = 3.0; // Light weights
        break;
    }
    return (_duration * caloriesPerMinute).round();
  }

  @override
  Widget build(BuildContext context) {
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
          'Weight Lifting',
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
            // Set Intensity Section
            Text(
              'Set Intensity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MealAIColors.blackText,
              ),
            ),
            SizedBox(height: 16),
            _buildIntensityOption(
              level: 'High',
              title: 'Heavy Lifting',
              subtitle: 'Compound exercises (Deadlift, Squat, Bench)',
              icon: Icons.fitness_center,
              color: Colors.red,
            ),
            SizedBox(height: 12),
            _buildIntensityOption(
              level: 'Medium',
              title: 'Moderate Weights',
              subtitle: 'Mixed exercises with moderate load',
              icon: Icons.fitness_center,
              color: Colors.orange,
            ),
            SizedBox(height: 12),
            _buildIntensityOption(
              level: 'Low',
              title: 'Light Weights',
              subtitle: 'Isolation exercises and machines',
              icon: Icons.fitness_center,
              color: Colors.green,
            ),
            
            SizedBox(height: 32),
            
            // Duration Section
            Text(
              'Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MealAIColors.blackText,
              ),
            ),
            SizedBox(height: 16),
            
            // Duration buttons
            Row(
              children: [
                Expanded(
                  child: _buildDurationButton(15),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDurationButton(30),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDurationButton(60),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDurationButton(90),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Editable duration input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _duration > 0 ? Colors.black : Colors.grey[300]!,
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
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: _duration > 0 ? Colors.black : Colors.grey,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MealAIColors.blackText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter duration',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _duration = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  Text(
                    'mins',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canContinue
                    ? () {
                        int burnedCalories = _calculateCalories();
                        Get.to(() => WorkoutResultPage(
                              exerciseType: 'Weight Lifting',
                              intensity: _selectedIntensity,
                              duration: _duration,
                              burnedCalories: burnedCalories,
                              existingRecord: widget.existingRecord,
                            ));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canContinue
                      ? MealAIColors.blackText
                      : Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _canContinue ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityOption({
    required String level,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final bool isSelected = _selectedIntensity == level;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIntensity = level;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.06 : 0.02),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.black : Colors.grey[400],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationButton(int minutes) {
    final bool isSelected = _duration == minutes;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _duration = minutes;
          _durationController.text = minutes.toString();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
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
        child: Column(
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'mins',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}