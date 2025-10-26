import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sizer/sizer.dart';
import 'package:calai/app/constants/colors.dart';

class NutritionTrackerCard extends StatelessWidget {
  final int maximumCalories;
  final int consumedCalories;
  final int burnedCalories;
  final int maximumFat;
  final int consumedFat;
  final int maximumProtein;
  final int consumedProtein;
  final int maximumCarb;
  final int consumedCarb;
  final bool showLeftView;
  final VoidCallback onToggle;

  const NutritionTrackerCard({
    Key? key,
    required this.maximumCalories,
    required this.consumedCalories,
    required this.burnedCalories,
    required this.maximumFat,
    required this.consumedFat,
    required this.maximumProtein,
    required this.consumedProtein,
    required this.maximumCarb,
    required this.consumedCarb,
    required this.showLeftView,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final caloriesLeft = maximumCalories - consumedCalories + burnedCalories;
    final progress = (consumedCalories / maximumCalories).clamp(0.0, 1.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          // Main Calorie Card
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(4.w),
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.textColor.withOpacity(0.02),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showLeftView) ...[
                          Text(
                            '$caloriesLeft',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'Calories left',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textColor.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$consumedCalories',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                    height: 1.0,
                                  ),
                                ),
                                TextSpan(
                                  text: ' /$maximumCalories',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: context.textColor.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Calories eaten',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textColor.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(Icons.restaurant, size: 16, color: Colors.orange),
                            SizedBox(width: 1.w),
                            Text(
                              '+$consumedCalories',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textColor.withOpacity(0.87),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.local_fire_department, size: 16, color: context.textColor),
                            SizedBox(width: 1.w),
                            Text(
                              '+$burnedCalories',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textColor.withOpacity(0.87),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, animatedProgress, child) {
                      return CircularPercentIndicator(
                        radius: 50,
                        lineWidth: 8,
                        percent: animatedProgress,
                        center: Icon(
                          Icons.local_fire_department,
                          color: context.textColor,
                          size: 32,
                        ),
                        progressColor: context.textColor,
                        backgroundColor: context.borderColor,
                        circularStrokeCap: CircularStrokeCap.round,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),
          
          // Macro Cards Row
          Row(
            children: [
              Expanded(child: _buildMacroCard(
                context,
                'Protein', 
                consumedProtein, 
                maximumProtein, 
                Icons.fitness_center, 
                Color(0xFFE57373),
              )),
              SizedBox(width: 3.w),
              Expanded(child: _buildMacroCard(
                context,
                'Carbs', 
                consumedCarb, 
                maximumCarb,
                Icons.grain, 
                Color(0xFFFFB74D),
              )),
              SizedBox(width: 3.w),
              Expanded(child: _buildMacroCard(
                context,
                'Fats', 
                consumedFat, 
                maximumFat,
                Icons.water_drop, 
                Color(0xFF64B5F6),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context,
    String label, 
    int value, 
    int max, 
    IconData icon, 
    Color color,
  ) {
    final left = (max - value).clamp(0, max);
    final progress = (value / max).clamp(0.0, 1.0);
    
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(4.w),
          border: Border.all(
            color: context.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.02),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            if (showLeftView) ...[
              Text(
                '${left}g',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              Text(
                '$label left',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textColor.withOpacity(0.6),
                ),
              ),
            ] else ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    TextSpan(
                      text: ' /$max',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textColor.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$label eaten',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textColor.withOpacity(0.6),
                ),
              ),
            ],
            SizedBox(height: 2.h),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, animatedProgress, child) {
                return CircularPercentIndicator(
                  radius: 35,
                  lineWidth: 6,
                  percent: animatedProgress,
                  center: Icon(icon, color: color, size: 24),
                  progressColor: color,
                  backgroundColor: context.borderColor,
                  circularStrokeCap: CircularStrokeCap.round,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}