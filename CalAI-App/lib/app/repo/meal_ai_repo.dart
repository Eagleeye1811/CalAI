import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:calai/app/models/AI/nutrition_input.dart';
import 'package:calai/app/models/AI/nutrition_output.dart';
import 'package:calai/app/config/environment.dart'; // 🆕 Import environment config

class AiRepository {
  Future<NutritionOutput> getNutritionData(
      NutritionInputQuery inputQuery) async {
    // 🆕 Use Environment.nutritionGetUrl directly
    final String apiUrl = Environment.nutritionGetUrl;

    print('🔗 Calling nutrition API: $apiUrl');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(inputQuery.toJsonForMealAIBackend()),
        headers: {"Content-Type": "application/json"},
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('✅ Nutrition data received successfully');
        return NutritionOutput.fromJson(jsonResponse);
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        return NutritionOutput(
          status: response.statusCode,
          message:
              "API request failed with status ${response.statusCode}: ${response.body}",
          response: null,
        );
      }
    } catch (e) {
      print('❌ Network error: $e');
      return NutritionOutput(
        status: 500,
        message: "Network error: ${e.toString()}",
        response: null,
      );
    }
  }

  // 🆕 Add description-based nutrition analysis
  Future<NutritionOutput> getNutritionFromDescription(
      NutritionInputQuery inputQuery) async {
    final String apiUrl = Environment.nutritionDescriptionUrl;

    print('🔗 Calling nutrition description API: $apiUrl');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(inputQuery.toJsonForMealAIBackend()),
        headers: {"Content-Type": "application/json"},
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('✅ Nutrition data received successfully');
        return NutritionOutput.fromJson(jsonResponse);
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        return NutritionOutput(
          status: response.statusCode,
          message:
              "API request failed with status ${response.statusCode}: ${response.body}",
          response: null,
        );
      }
    } catch (e) {
      print('❌ Network error: $e');
      return NutritionOutput(
        status: 500,
        message: "Network error: ${e.toString()}",
        response: null,
      );
    }
  }
}
