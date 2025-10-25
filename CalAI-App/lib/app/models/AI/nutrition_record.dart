import 'package:CalAI/app/constants/enums.dart';
import 'package:CalAI/app/models/AI/nutrition_input.dart';
import 'package:CalAI/app/models/AI/nutrition_output.dart';
import 'package:CalAI/app/models/AI/exercise_record.dart';


class NutritionRecord {
  NutritionOutput? nutritionOutput;
  NutritionInputQuery? nutritionInputQuery;
  ExerciseRecord? exerciseRecord;
  DateTime? recordTime;
  ProcessingStatus? processingStatus;
  bool isExercise;
  EntrySource? entrySource;

  NutritionRecord({
    this.nutritionOutput,
    this.recordTime,
    this.nutritionInputQuery,
    this.exerciseRecord,
    this.processingStatus,
    this.isExercise = false,
    this.entrySource,
  });

  factory NutritionRecord.fromJson(Map<String, dynamic> json) =>
      NutritionRecord(
        nutritionOutput: json['nutritionOutput'] != null 
            ? NutritionOutput.fromJson(json['nutritionOutput'])
            : null,
        nutritionInputQuery: json['nutritionInputQuery'] != null
            ? NutritionInputQuery.fromJson(json['nutritionInputQuery'])
            : null,
        exerciseRecord: json['exerciseRecord'] != null
            ? ExerciseRecord.fromJson(json['exerciseRecord'])
            : null,
        recordTime: DateTime.parse(json['recordTime']),
        processingStatus: json['processingStatus'] != null
            ? ProcessingStatus.values.byName(json['processingStatus'])
            : ProcessingStatus.COMPLETED,
        isExercise: json['isExercise'] ?? false,
        entrySource: json['entrySource'] != null
            ? EntrySource.values.byName(json['entrySource'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (nutritionOutput != null) 'nutritionOutput': nutritionOutput!.toJson(),
        'recordTime': recordTime!.toIso8601String(),
        if (nutritionInputQuery != null) 'nutritionInputQuery': nutritionInputQuery!.toJson(),
        if (exerciseRecord != null) 'exerciseRecord': exerciseRecord!.toJson(),
        'processingStatus': processingStatus!.name,
        'isExercise': isExercise,
        if (entrySource != null) 'entrySource': entrySource!.name,
      };
}

class DailyNutritionRecords {
  final List<NutritionRecord> dailyRecords;
  final String recordId;
  final DateTime recordDate;
  int dailyConsumedCalories = 0;
  int dailyBurnedCalories = 0;
  int dailyConsumedProtein = 0;
  int dailyConsumedFat = 0;
  int dailyConsumedCarb = 0;
  int? dailyConsumedFiber;
  int? dailyConsumedSugar;
  int? dailyConsumedSodium;

  DailyNutritionRecords({
    required this.dailyRecords,
    required this.recordDate,
    required this.recordId,
    this.dailyConsumedCalories = 0,
    this.dailyBurnedCalories = 0,
    this.dailyConsumedProtein = 0,
    this.dailyConsumedFat = 0,
    this.dailyConsumedCarb = 0,
    this.dailyConsumedFiber,
    this.dailyConsumedSugar,
    this.dailyConsumedSodium,
  });

  factory DailyNutritionRecords.fromJson(Map<String, dynamic> json) =>
      DailyNutritionRecords(
        dailyRecords: (json['dailyRecords'] as List)
            .map((item) =>
                NutritionRecord.fromJson(item as Map<String, dynamic>))
            .toList(),
        recordDate: DateTime.parse(json['recordDate']),
        recordId: json['recordId'],
        dailyConsumedCalories: json['dailyConsumedCalories'] ?? 0,
        dailyBurnedCalories: json['dailyBurnedCalories'] ?? 0,
        dailyConsumedProtein: json['dailyConsumedProtein'] ?? 0,
        dailyConsumedFat: json['dailyConsumedFat'] ?? 0,
        dailyConsumedCarb: json['dailyConsumedCarb'] ?? 0,
        dailyConsumedFiber: json['dailyConsumedFiber'],
        dailyConsumedSugar: json['dailyConsumedSugar'],
        dailyConsumedSodium: json['dailyConsumedSodium'],
      );

  Map<String, dynamic> toJson() => {
        'dailyRecords': dailyRecords.map((record) => record.toJson()).toList(),
        'recordDate': recordDate.toIso8601String(),
        'recordId': recordId,
        'dailyConsumedCalories': dailyConsumedCalories,
        'dailyBurnedCalories': dailyBurnedCalories,
        'dailyConsumedProtein': dailyConsumedProtein,
        'dailyConsumedFat': dailyConsumedFat,
        'dailyConsumedCarb': dailyConsumedCarb,
        'dailyConsumedFiber': dailyConsumedFiber,
        'dailyConsumedSugar': dailyConsumedSugar,
        'dailyConsumedSodium': dailyConsumedSodium,
      };
}