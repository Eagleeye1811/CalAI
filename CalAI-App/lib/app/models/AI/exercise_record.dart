class ExerciseRecord {
  final String exerciseType;
  final String intensity;
  final int duration;
  final int caloriesBurned;
  final DateTime recordTime;

  ExerciseRecord({
    required this.exerciseType,
    required this.intensity,
    required this.duration,
    required this.caloriesBurned,
    required this.recordTime,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      exerciseType: json['exerciseType'] ?? 'Exercise',
      intensity: json['intensity'] ?? '',
      duration: json['duration'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      recordTime: DateTime.parse(json['recordTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseType': exerciseType,
      'intensity': intensity,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'recordTime': recordTime.toIso8601String(),
    };
  }
}