import 'package:calai/app/components/empty.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calai/app/constants/colors.dart';
import 'package:calai/app/modules/Analytics/model/analytics.dart';
import 'package:calai/app/controllers/user_controller.dart';
import 'package:calai/app/repo/nutrition_record_repo.dart';
import 'package:calai/app/utility/registry_service.dart';
import 'package:sizer/sizer.dart';
import 'package:calai/app/models/AI/nutrition_record.dart';
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

  Future<MonthlyAnalytics?> _fetchFreshMonthlyData() async {
    if (_userId == null) return null;
    
    try {
      final repo = serviceLocator<NutritionRecordRepo>();
      
      final coll = await repo.usersCollection
          .doc(_userId!)
          .collection('nutritionRecords')
          .get();

      final year = _selectedMonth.year;
      final month = _selectedMonth.month;
      final List<DailyAnalytics> daily = [];
      
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
                      color: context.textColor,
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
        
        // Weight & Goal + Streak Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
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
              color: context.cardColor,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Monthly Averages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
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
        
        // BMI Section
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

    final double yInterval = _niceYInterval(maxY);
    final double chartMaxY = (maxY == 0 ? 1000 : maxY + yInterval);

    return SizedBox(
      height: 28.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: context.borderColor),
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
                  getTooltipColor: (spot) => context.textColor,
                  tooltipPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((ts) {
                      final day = ts.x.toInt();
                      final value = ts.y.toInt();
                      final label = _metricLabel(_selectedMetric);
                      return LineTooltipItem(
                        'Day $day\n$value $label',
                        TextStyle(
                          color: context.cardColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: context.textColor.withOpacity(0.08),
                  strokeWidth: 1,
                ),
                horizontalInterval: yInterval,
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 14.w,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textColor,
                        ),
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
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textColor,
                          ),
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
                    color: context.textColor.withOpacity(0.2),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: context.textColor.withOpacity(0.2),
                    width: 1,
                  ),
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: context.textColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, p, bar, i) => FlDotCirclePainter(
                      radius: 3,
                      color: context.textColor,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: context.textColor.withOpacity(0.06),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textColor.withOpacity(0.6),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyTile(DailyAnalytics d, int index, int maxDayCalories) {
    final dayLabel = DateFormat('dd MMM').format(d.date);
    final percent = maxDayCalories > 0 ? (d.totalCalories / maxDayCalories) : 0.0;
    final expanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(() {
        _expandedIndex = expanded ? null : index;
      }),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
        padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: context.borderColor),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
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
                          color: context.textColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: percent.clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.textColor,
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
                          color: context.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: context.textColor,
                  size: 4.w,
                ),
              ],
            ),
            if (expanded) ...[
              SizedBox(height: 1.h),
              Divider(color: context.borderColor, height: 1),
              SizedBox(height: 1.h),
              _expandedMetrics(d),
              if ((d.overAllSummary ?? '').isNotEmpty) ...[
                SizedBox(height: 1.h),
                Text(
                  d.overAllSummary!,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textColor.withOpacity(0.6),
                  ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            k,
            style: TextStyle(
              fontSize: 12,
              color: context.textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

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
              color: selected ? context.textColor : Colors.transparent,
              borderRadius: BorderRadius.circular(5.w),
              border: Border.all(
                color: context.textColor.withOpacity(0.25),
              ),
            ),
            child: Text(
              _metricTitle(m),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? context.cardColor : context.textColor,
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

  double? _calculateBMI(double? height, double? weight) {
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      return null;
    }
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Healthy';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBMISection(double? height, double? weight) {
    final bmi = _calculateBMI(height, weight);
    
    if (bmi == null) {
      return Container(
        padding: EdgeInsets.all(4.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: context.textColor.withOpacity(0.6),
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Complete your height and weight in profile to see BMI',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textColor.withOpacity(0.6),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight, color: context.textColor, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Body Mass Index (BMI)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
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
          _buildBMIScale(bmi),
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
            color: context.textColor.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 0.3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
      ],
    );
  }
    
  Widget _buildBMIScale(double bmi) {
    final displayBMI = bmi.clamp(10.0, 40.0);
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
            color: context.textColor.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 1.h),
        
        Stack(
          children: [
            Container(
              height: 1.2.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.h),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.blue.shade300,
                    Colors.green,
                    Colors.green,
                    Colors.orange.shade300,
                    Colors.orange,
                    Colors.deepOrange,
                    Colors.red,
                  ],
                  stops: const [0.0, 0.25, 0.28, 0.49, 0.52, 0.65, 0.80, 1.0],
                ),
              ),
            ),
            
            Positioned(
              left: position * 82.w,
              top: -0.6.h,
              child: Column(
                children: [
                  Container(
                    width: 0.6.w,
                    height: 2.4.h,
                    decoration: BoxDecoration(
                      color: context.textColor,
                      borderRadius: BorderRadius.circular(0.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: context.textColor.withOpacity(0.2),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: context.textColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.cardColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.textColor.withOpacity(0.3),
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
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _scaleLabel('Under', Colors.blue),
            _scaleLabel('Healthy', Colors.green),
            _scaleLabel('Over', Colors.orange),
            _scaleLabel('Obese', Colors.red),
          ],
        ),
        
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
            color: context.textColor.withOpacity(0.6),
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
        color: context.textColor.withOpacity(0.5),
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

  Widget _buildWeightGoalBox(double? currentWeight, double? goalWeight) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: context.textColor, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Weight Tracker',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
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
                  color: context.textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBox(MonthlyAnalytics data) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int currentStreak = 0;
    
    for (int i = 0; i < 365; i++) {
      final checkDate = todayDate.subtract(Duration(days: i));
      
      final dayData = data.dailyAnalytics.firstWhere(
        (d) {
          final dDate = DateTime(d.date.year, d.date.month, d.date.day);
          return dDate.year == checkDate.year &&
                dDate.month == checkDate.month &&
                dDate.day == checkDate.day;
        },
        orElse: () => DailyAnalytics(date: checkDate, mealCount: 0),
      );
      
      if (dayData.mealCount > 0) {
        currentStreak++;
      } else {
        break;
      }
    }
    
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: context.borderColor),
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
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
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
                      color: context.textColor.withOpacity(0.6),
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
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        title: Text(
          'Progress',
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: context.textColor),
      ),
      body: GetBuilder<UserController>(
        builder: (userController) {
          if (userController.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: context.textColor,
              ),
            );
          }
          
          if (userController.hasUser) {
            _userId ??= userController.userModel!.userId;
            
            return FutureBuilder<MonthlyAnalytics?>(
              key: ValueKey('analytics_${_selectedMonth.year}_${_selectedMonth.month}'),
              future: _fetchFreshMonthlyData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: context.textColor,
                    ),
                  );
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
                        color: context.textColor.withOpacity(0.6),
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
          color: context.textColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: context.textColor,
          size: 20,
        ),
      ),
    );
  }
}

enum _Metric { calories, protein, carbs, fat, water }