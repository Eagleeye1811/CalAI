import 'package:CalAI/app/components/empty.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/modules/Analytics/model/analytics.dart';
import 'package:CalAI/app/controllers/user_controller.dart';
import 'package:CalAI/app/repo/nutrition_record_repo.dart';
import 'package:CalAI/app/utility/registry_service.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:get/get.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String? _userId;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  _Metric _selectedMetric = _Metric.calories;
  int? _expandedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userController = Get.find<UserController>();
    if (userController.hasUser) {
      _userId ??= userController.userModel!.userId;
    }
  }

  // 🔥 OPTION 1: Always fetch fresh data by computing directly from nutritionRecords
  Future<MonthlyAnalytics?> _fetchFreshMonthlyData() async {
    if (_userId == null) return null;
    
    try {
      final repo = serviceLocator<NutritionRecordRepo>();
      
      // Fetch ALL nutrition records for the user
      final coll = await repo.usersCollection
          .doc(_userId!)
          .collection('nutritionRecords')
          .get();

      final year = _selectedMonth.year;
      final month = _selectedMonth.month;
      final List<DailyAnalytics> daily = [];
      
      // Filter and build DailyAnalytics for the selected month
      for (final d in coll.docs) {
        final data = d.data();
        try {
          final rec = DailyNutritionRecords.fromJson(data);
          if (rec.recordDate.year == year && rec.recordDate.month == month) {
            daily.add(DailyAnalytics(
              date: DateTime(rec.recordDate.year, rec.recordDate.month, rec.recordDate.day),
              totalCalories: rec.dailyConsumedCalories,
              totalProtein: rec.dailyConsumedProtein,
              totalFat: rec.dailyConsumedFat,
              totalCarbs: rec.dailyConsumedCarb,
              mealCount: rec.dailyRecords.length,
              totalCaloriesBurned: rec.dailyBurnedCalories,
              waterIntake: 0,
            ));
          }
        } catch (_) {
          // ignore malformed docs
        }
      }

      daily.sort((a, b) => a.date.compareTo(b.date));
      return MonthlyAnalytics(
        dailyAnalytics: daily,
        lastModified: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching fresh monthly data: $e');
      return null;
    }
  }

  Widget _buildSummary(MonthlyAnalytics data) {
    final days = data.dailyAnalytics;
    int totalCalories = 0;
    int totalProtein = 0;
    int totalFat = 0;
    int totalCarbs = 0;
    int totalMeals = 0;
    int maxDayCalories = 0;
    int totalWater = 0;

    for (final d in days) {
      totalCalories += d.totalCalories;
      totalProtein += d.totalProtein;
      totalFat += d.totalFat;
      totalCarbs += d.totalCarbs;
      totalMeals += d.mealCount;
      if (d.totalCalories > maxDayCalories) maxDayCalories = d.totalCalories;
      totalWater += d.waterIntake;
    }

    final int divisor = days.isNotEmpty ? days.length : 1;
    final avgCalories = (totalCalories / divisor).round();
    final avgProtein = (totalProtein / divisor).round();
    final avgCarbs = (totalCarbs / divisor).round();
    final avgFat = (totalFat / divisor).round();
    final avgWater = (totalWater / divisor).round();
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              _MonthButton(icon: Icons.chevron_left, onTap: _prevMonth),
              Expanded(
                child: Center(
                  child: Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: MealAIColors.blackText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _MonthButton(icon: Icons.chevron_right, onTap: _nextMonth),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        
        // Weight & Goal + Streak Section (Two columns in one row) - MOVED UP
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              // First Box: Weight & Goal
              Expanded(
                child: GetBuilder<UserController>(
                  builder: (userController) {
                    double? currentWeight;
                    double? goalWeight;
                    if (userController.hasUser) {
                      currentWeight = userController.userModel?.userInfo?.currentWeight;
                      goalWeight = userController.userModel?.userInfo?.desiredWeight;
                    }
                    return _buildWeightGoalBox(currentWeight, goalWeight);
                  },
                ),
              ),
              SizedBox(width: 3.w),
              // Second Box: Daily Streak
              Expanded(
                child: _buildStreakBox(data),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: _metricPicker(),
        ),
        SizedBox(height: 1.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: _buildMonthlyChart(days),
        ),
        SizedBox(height: 1.5.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Container(
            padding: EdgeInsets.all(4.w),
            width: double.infinity,
            decoration: BoxDecoration(
              color: MealAIColors.lightSurface,
              borderRadius: BorderRadius.circular(3.w),
              border:
                  Border.all(color: MealAIColors.blackText.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Monthly Averages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MealAIColors.blackText,
                  ),
                ),
                SizedBox(height: 1.5.h),
                Wrap(
                  spacing: 5.w,
                  runSpacing: 1.2.h,
                  children: [
                    _avgMetric('Avg Cal/day', '${avgCalories} cal'),
                    _avgMetric('Protein', '${avgProtein} g'),
                    _avgMetric('Carbs', '${avgCarbs} g'),
                    _avgMetric('Fat', '${avgFat} g'),
                    _avgMetric('Water', '${avgWater} ml'),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        
        // BMI Section - MOVED TO BOTTOM
        GetBuilder<UserController>(
          builder: (userController) {
            double? userHeight;
            double? userWeight;
            if (userController.hasUser) {
              userHeight = userController.userModel?.userInfo?.currentHeight;
              userWeight = userController.userModel?.userInfo?.currentWeight;
            }
            return _buildBMISection(userHeight, userWeight);
          },
        ),
        
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildMonthlyChart(List<DailyAnalytics> days) {
    if (days.isEmpty) return const SizedBox.shrink();

    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    int minDay = 31;
    int maxDay = 1;
    double maxY = 0;
    for (final d in sorted) {
      final x = d.date.day.toDouble();
      final y = _valueForMetric(d).toDouble();
      spots.add(FlSpot(x, y));
      if (d.date.day < minDay) minDay = d.date.day;
      if (d.date.day > maxDay) maxDay = d.date.day;
      if (y > maxY) maxY = y;
    }

    // Add some headroom for y-axis
    final double yInterval = _niceYInterval(maxY);
    final double chartMaxY = (maxY == 0 ? 1000 : maxY + yInterval);

    return SizedBox(
      height: 28.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MealAIColors.lightSurface,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: MealAIColors.blackText.withOpacity(0.08)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(3.w, 1.5.h, 4.w, 1.5.h),
          child: LineChart(
            LineChartData(
              minX: minDay.toDouble(),
              maxX: maxDay.toDouble(),
              minY: 0,
              maxY: chartMaxY,
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((ts) {
                      final day = ts.x.toInt();
                      final value = ts.y.toInt();
                      final label = _metricLabel(_selectedMetric);
                      return LineTooltipItem(
                        'Day $day\n$value $label',
                        const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.black.withOpacity(0.08),
                  strokeWidth: 1,
                ),
                horizontalInterval: yInterval,
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 14.w,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: MealAIColors.blackText),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _niceXInterval(minDay, maxDay),
                    getTitlesWidget: (value, meta) {
                      final v = value.toInt();
                      return Padding(
                        padding: EdgeInsets.only(top: 0.6.h),
                        child: Text(
                          v.toString(),
                          style: const TextStyle(
                              fontSize: 10, color: MealAIColors.blackText),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(
                      color: Colors.black.withOpacity(0.2), width: 1),
                  bottom: BorderSide(
                      color: Colors.black.withOpacity(0.2), width: 1),
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: MealAIColors.blackText,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, p, bar, i) => FlDotCirclePainter(
                      radius: 3,
                      color: MealAIColors.blackText,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: MealAIColors.blackText.withOpacity(0.06),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _niceXInterval(int minDay, int maxDay) {
    final range = (maxDay - minDay).clamp(1, 31);
    if (range <= 7) return 1;
    if (range <= 14) return 2;
    if (range <= 21) return 3;
    return 5;
  }

  double _niceYInterval(double maxY) {
    if (maxY <= 500) return 100;
    if (maxY <= 1200) return 200;
    if (maxY <= 2000) return 250;
    if (maxY <= 3000) return 500;
    return 1000;
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MealAIColors.blackText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: MealAIColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _avgMetric(String label, String value) {
    return SizedBox(
      width: 30.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MealAIColors.blackText,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: MealAIColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyTile(DailyAnalytics d, int index, int maxDayCalories) {
    final dayLabel = DateFormat('dd MMM').format(d.date);
    final percent =
        maxDayCalories > 0 ? (d.totalCalories / maxDayCalories) : 0.0;
    final expanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(() {
        _expandedIndex = expanded ? null : index;
      }),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
        padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: MealAIColors.lightSurface,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: MealAIColors.blackText.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 18.w,
                  child: Text(
                    dayLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MealAIColors.blackText,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 0.6.h,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: percent.clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: MealAIColors.blackText,
                              borderRadius: BorderRadius.circular(1.w),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 0.6.h),
                      Text(
                        '${d.totalCalories} cal · ${d.mealCount} meals',
                        style: TextStyle(
                          fontSize: 11,
                          color: MealAIColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: MealAIColors.blackText,
                  size: 4.w,
                ),
              ],
            ),
            if (expanded) ...[
              SizedBox(height: 1.h),
              Divider(color: Colors.black.withOpacity(0.08), height: 1),
              SizedBox(height: 1.h),
              _expandedMetrics(d),
              if ((d.overAllSummary ?? '').isNotEmpty) ...[
                SizedBox(height: 1.h),
                Text(
                  d.overAllSummary!,
                  style: TextStyle(fontSize: 12, color: MealAIColors.grey),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _expandedMetrics(DailyAnalytics d) {
    final pairs = <MapEntry<String, String>>[
      MapEntry('Calories', '${d.totalCalories} cal'),
      MapEntry('Protein', '${d.totalProtein} g'),
      MapEntry('Carbs', '${d.totalCarbs} g'),
      MapEntry('Fat', '${d.totalFat} g'),
      MapEntry('Water', '${d.waterIntake} ml'),
      MapEntry('Burned', '${d.totalCaloriesBurned} cal'),
      MapEntry('Meals', d.mealCount.toString()),
    ];

    return Wrap(
      spacing: 4.w,
      runSpacing: 1.h,
      children: pairs.map((e) => _kv(e.key, e.value)).toList(),
    );
  }

  Widget _kv(String k, String v) {
    return SizedBox(
      width: 30.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MealAIColors.blackText,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            k,
            style: TextStyle(fontSize: 12, color: MealAIColors.grey),
          ),
        ],
      ),
    );
  }

  // Metric/Month helpers
  Widget _metricPicker() {
    final items = const [
      _Metric.calories,
      _Metric.protein,
      _Metric.carbs,
      _Metric.fat,
      _Metric.water,
    ];
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: items.map((m) {
        final selected = m == _selectedMetric;
        return GestureDetector(
          onTap: () => setState(() => _selectedMetric = m),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: selected ? MealAIColors.blackText : Colors.transparent,
              borderRadius: BorderRadius.circular(5.w),
              border: Border.all(
                color: MealAIColors.blackText.withOpacity(0.25),
              ),
            ),
            child: Text(
              _metricTitle(m),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : MealAIColors.blackText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _metricTitle(_Metric m) {
    switch (m) {
      case _Metric.calories:
        return 'Calories';
      case _Metric.protein:
        return 'Protein';
      case _Metric.carbs:
        return 'Carbs';
      case _Metric.fat:
        return 'Fat';
      case _Metric.water:
        return 'Water';
    }
  }

  String _metricLabel(_Metric m) {
    switch (m) {
      case _Metric.calories:
        return 'cal';
      case _Metric.protein:
        return 'g';
      case _Metric.carbs:
        return 'g';
      case _Metric.fat:
        return 'g';
      case _Metric.water:
        return 'ml';
    }
  }

  int _valueForMetric(DailyAnalytics d) {
    switch (_selectedMetric) {
      case _Metric.calories:
        return d.totalCalories;
      case _Metric.protein:
        return d.totalProtein;
      case _Metric.carbs:
        return d.totalCarbs;
      case _Metric.fat:
        return d.totalFat;
      case _Metric.water:
        return d.waterIntake;
    }
  }
  
  // Add these helper methods after _valueForMetric method

/// Calculate BMI from height (cm) and weight (kg)
double? _calculateBMI(double? height, double? weight) {
  if (height == null || weight == null || height <= 0 || weight <= 0) {
    return null;
  }
  // Convert height from cm to meters
  final heightInMeters = height / 100;
  // BMI = weight (kg) / height (m)²
  return weight / (heightInMeters * heightInMeters);
}

/// Get BMI category based on WHO standards
String _getBMICategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25.0) return 'Healthy';
  if (bmi < 30.0) return 'Overweight';
  return 'Obese';
}

/// Get BMI color based on category
Color _getBMIColor(double bmi) {
  if (bmi < 18.5) return Colors.blue;
  if (bmi < 25.0) return Colors.green;
  if (bmi < 30.0) return Colors.orange;
  return Colors.red;
}

  /// Build BMI widget
  Widget _buildBMISection(double? height, double? weight) {
    final bmi = _calculateBMI(height, weight);
    
    if (bmi == null) {
      return Container(
        padding: EdgeInsets.all(4.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: MealAIColors.lightSurface,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: MealAIColors.blackText.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: MealAIColors.grey, size: 5.w),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Complete your height and weight in profile to see BMI',
                style: TextStyle(
                  fontSize: 12,
                  color: MealAIColors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final category = _getBMICategory(bmi);
    final color = _getBMIColor(bmi);

    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: MealAIColors.lightSurface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: MealAIColors.blackText.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight, color: MealAIColors.blackText, size: 5.w),
              SizedBox(width: 2.w),
              const Text(
                'Body Mass Index (BMI)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MealAIColors.blackText,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              SizedBox(width: 3.w),
              Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    'Your weight is $category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 👇 Removed height/weight section here
          // 👇 BMI Scale comes next
          _buildBMIScale(bmi),
          // 👇 Removed info box here
        ],
      ),
    );
  }

  Widget _bmiDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: MealAIColors.grey,
          ),
        ),
        SizedBox(height: 0.3.h),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: MealAIColors.blackText,
          ),
        ),
      ],
    );
  }
    
  Widget _buildBMIScale(double bmi) {
    // BMI ranges: <18.5, 18.5-24.9, 25-29.9, >=30
    // Clamp BMI to reasonable display range (10-40)
    final displayBMI = bmi.clamp(10.0, 40.0);
    
    // Calculate position on scale (10-40 range = 30 units)
    // Position as percentage: (BMI - 10) / 30
    final position = ((displayBMI - 10) / 30).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.5.h),
        Text(
          'BMI Scale',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MealAIColors.grey,
          ),
        ),
        SizedBox(height: 1.h),
        
        // The colored scale bar with gradient
        Stack(
          children: [
            // Background with smooth gradient
            Container(
              height: 1.2.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.h),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue,           // Underweight
                    Colors.blue.shade300,  // Transition
                    Colors.green,          // Healthy start
                    Colors.green,          // Healthy end
                    Colors.orange.shade300,// Transition
                    Colors.orange,         // Overweight
                    Colors.deepOrange,     // Transition
                    Colors.red,            // Obese
                  ],
                  stops: const [
                    0.0,   // Blue start
                    0.25,  // Blue to green transition
                    0.28,  // Green start (18.5)
                    0.49,  // Green end (24.9)
                    0.52,  // Green to orange transition
                    0.65,  // Orange (25-29.9)
                    0.80,  // Orange to red transition
                    1.0,   // Red (30+)
                  ],
                ),
              ),
            ),
            
            // Position marker
            Positioned(
              left: position * 82.w, // Adjust based on container width
              top: -0.6.h,
              child: Column(
                children: [
                  // Marker line
                  Container(
                    width: 0.6.w,
                    height: 2.4.h,
                    decoration: BoxDecoration(
                      color: MealAIColors.blackText,
                      borderRadius: BorderRadius.circular(0.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  // Marker dot
                  Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: MealAIColors.blackText,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: 0.8.h),
        
        // Labels below the scale
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _scaleLabel('Under', Colors.blue),
            _scaleLabel('Healthy', Colors.green),
            _scaleLabel('Over', Colors.orange),
            _scaleLabel('Obese', Colors.red),
          ],
        ),
        
        // BMI value markers
        SizedBox(height: 0.3.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _scaleValueLabel('<18.5'),
            _scaleValueLabel('18.5-24.9'),
            _scaleValueLabel('25-29.9'),
            _scaleValueLabel('≥30'),
          ],
        ),
      ],
    );
  }

  Widget _scaleLabel(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2.w,
          height: 2.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: MealAIColors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _scaleValueLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8,
        color: MealAIColors.grey.withOpacity(0.7),
      ),
    );
  }  

  void _prevMonth() {
    final prev = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _setMonth(prev);
  }

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _setMonth(next);
  }

  void _setMonth(DateTime month) {
    setState(() {
      _selectedMonth = DateTime(month.year, month.month);
      _expandedIndex = null;
    });
  }

  /// Build Weight & Goal Box
  Widget _buildWeightGoalBox(double? currentWeight, double? goalWeight) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: MealAIColors.lightSurface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: MealAIColors.blackText.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: MealAIColors.blackText, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Weight Tracker',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MealAIColors.blackText,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _weightDetail(
            'My Weight',
            currentWeight != null ? '${currentWeight.toStringAsFixed(1)} kg' : '--',
            Colors.blue,
          ),
          SizedBox(height: 1.5.h),
          _weightDetail(
            'Goal',
            goalWeight != null ? '${goalWeight.toStringAsFixed(1)} kg' : '--',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _weightDetail(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 1.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(0.5.w),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: MealAIColors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MealAIColors.blackText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Streak Box
  Widget _buildStreakBox(MonthlyAnalytics data) {
    // Calculate current streak
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day); // Normalize to date only
    int currentStreak = 0;
    
    // Check each day backwards from today
    for (int i = 0; i < 365; i++) { // Check up to a year back (reasonable limit)
      final checkDate = todayDate.subtract(Duration(days: i));
      
      // Find data for this specific date
      final dayData = data.dailyAnalytics.firstWhere(
        (d) {
          final dDate = DateTime(d.date.year, d.date.month, d.date.day);
          return dDate.year == checkDate.year &&
                dDate.month == checkDate.month &&
                dDate.day == checkDate.day;
        },
        orElse: () => DailyAnalytics(date: checkDate, mealCount: 0),
      );
      
      // If this day has activity, increment streak
      if (dayData.mealCount > 0) {
        currentStreak++;
      } else {
        // Streak broken - stop counting
        break;
      }
    }
    
    // Get last 7 days activity
    final last7Days = List.generate(7, (index) {
      final date = todayDate.subtract(Duration(days: 6 - index));
      final dayData = data.dailyAnalytics.firstWhere(
        (d) {
          final dDate = DateTime(d.date.year, d.date.month, d.date.day);
          return dDate.year == date.year && 
                dDate.month == date.month && 
                dDate.day == date.day;
        },
        orElse: () => DailyAnalytics(date: date, mealCount: 0),
      );
      return {
        'day': ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7],
        'hasActivity': dayData.mealCount > 0,
      };
    });

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: MealAIColors.lightSurface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: MealAIColors.blackText.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Daily Streak',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MealAIColors.blackText,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Fire icon with streak number
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: currentStreak > 0 ? Colors.orange : Colors.grey.shade300,
                  size: 16.w,
                ),
                Positioned(
                  bottom: 2.5.h,
                  child: Text(
                    '$currentStreak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          // Days of the week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: last7Days.map((dayInfo) {
              return Column(
                children: [
                  Text(
                    dayInfo['day'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MealAIColors.grey,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    width: 2.5.w,
                    height: 2.5.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (dayInfo['hasActivity'] as bool)
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Progress',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GetBuilder<UserController>(
        builder: (userController) {
          if (userController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (userController.hasUser) {
            _userId ??= userController.userModel!.userId;
            
            // 🔥 KEY CHANGE: Use FutureBuilder with _fetchFreshMonthlyData()
            // This ensures fresh data is fetched every time the widget builds
            return FutureBuilder<MonthlyAnalytics?>(
              key: ValueKey('analytics_${_selectedMonth.year}_${_selectedMonth.month}'), // Force rebuild on month change
              future: _fetchFreshMonthlyData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load analytics',
                      style: TextStyle(color: MealAIColors.red),
                    ),
                  );
                }
                final data = snapshot.data;
                if (data == null || data.dailyAnalytics.isEmpty) {
                  return _buildEmptyState();
                }
                return SingleChildScrollView(child: _buildSummary(data));
              },
            );
          }
          
          if (userController.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                userController.errorMessage,
                style: TextStyle(color: MealAIColors.red),
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                _MonthButton(icon: Icons.chevron_left, onTap: _prevMonth),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: MealAIColors.grey,
                      ),
                    ),
                  ),
                ),
                _MonthButton(icon: Icons.chevron_right, onTap: _nextMonth),
              ],
            ),
          ),
          EmptyIllustrations(
            removeHeightValue: true,
            title: "No records yet",
            message: "You haven't logged any meals in $monthLabel.",
            imagePath: "assets/svg/empty.svg",
            width: 50.w,
            height: 40.h,
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MealAIColors.blackText.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: MealAIColors.blackText,
          size: 20,
        ),
      ),
    );
  }
}

enum _Metric { calories, protein, carbs, fat, water }