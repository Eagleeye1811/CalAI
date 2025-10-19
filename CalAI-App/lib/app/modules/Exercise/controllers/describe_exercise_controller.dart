import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DescribeExerciseController extends GetxController {
  RxBool isLoading = false.obs;
  
  // Exercise calorie rates (per minute, medium intensity)
  final Map<String, Map<String, double>> exerciseCalories = {
    'pushups': {'low': 3, 'medium': 4, 'high': 6},
    'situps': {'low': 3, 'medium': 4, 'high': 6},
    'squats': {'low': 4, 'medium': 5, 'high': 7},
    'burpees': {'low': 7, 'medium': 10, 'high': 12},
    'jumping jacks': {'low': 5, 'medium': 7, 'high': 9},
    'planks': {'low': 2, 'medium': 3, 'high': 4},
    'lunges': {'low': 4, 'medium': 5, 'high': 7},
    'mountain climbers': {'low': 6, 'medium': 8, 'high': 10},
    'cycling': {'low': 6, 'medium': 9, 'high': 12},
    'swimming': {'low': 8, 'medium': 11, 'high': 14},
    'yoga': {'low': 2, 'medium': 3, 'high': 4},
    'pilates': {'low': 3, 'medium': 4, 'high': 5},
    'dancing': {'low': 4, 'medium': 6, 'high': 8},
    'boxing': {'low': 7, 'medium': 9, 'high': 12},
    'jump rope': {'low': 8, 'medium': 11, 'high': 13},
    'walking': {'low': 3, 'medium': 4, 'high': 5},
    'hiking': {'low': 5, 'medium': 7, 'high': 9},
    'rowing': {'low': 6, 'medium': 8, 'high': 11},
    'elliptical': {'low': 5, 'medium': 7, 'high': 10},
    'stairs': {'low': 6, 'medium': 9, 'high': 11},
  };
  
  Future<Map<String, dynamic>?> analyzeExerciseDescription(String description) async {
    isLoading.value = true;
    
    try {
      // Parse the description using simple regex and keywords
      // In production, you'd call your backend API with Gemini
      final result = _parseExerciseLocally(description);
      
      await Future.delayed(Duration(milliseconds: 800)); // Simulate API call
      
      return result;
    } catch (e) {
      print('Error analyzing exercise: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  Map<String, dynamic> _parseExerciseLocally(String description) {
    String lowerDesc = description.toLowerCase();
    
    // Extract exercise name
    String exerciseName = 'Exercise';
    String matchedKey = 'pushups'; // default
    
    for (String exercise in exerciseCalories.keys) {
      if (lowerDesc.contains(exercise)) {
        exerciseName = _capitalize(exercise);
        matchedKey = exercise;
        break;
      }
    }
    
    // Extract duration (look for numbers followed by min/minute/mins/minutes)
    int duration = 1; // default
    RegExp durationRegex = RegExp(r'(\d+)\s*(min|mins|minute|minutes)');
    Match? durationMatch = durationRegex.firstMatch(lowerDesc);
    if (durationMatch != null) {
      duration = int.parse(durationMatch.group(1)!);
    }
    
    // Extract intensity
    String intensity = 'Medium'; // default
    if (lowerDesc.contains('high') || lowerDesc.contains('intense') || 
        lowerDesc.contains('hard') || lowerDesc.contains('vigorous')) {
      intensity = 'High';
    } else if (lowerDesc.contains('low') || lowerDesc.contains('light') || 
               lowerDesc.contains('easy') || lowerDesc.contains('gentle')) {
      intensity = 'Low';
    }
    
    // Calculate calories
    double caloriesPerMin = exerciseCalories[matchedKey]?[intensity.toLowerCase()] ?? 4.0;
    int caloriesBurned = (duration * caloriesPerMin).round();
    
    return {
      'exerciseName': exerciseName,
      'intensity': intensity,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
    };
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}