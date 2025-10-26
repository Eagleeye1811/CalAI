import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:calai/app/constants/colors.dart';

class StreakDialog extends StatelessWidget {
  final int streakCount;
  final List<bool> weekActivity; // 7 days, true if active
  
  const StreakDialog({
    Key? key,
    required this.streakCount,
    required this.weekActivity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: context.cardColor,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.apple, 
                      size: 24,
                      color: context.textColor,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Cal AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '$streakCount',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            
            // Fire Icon and Count
            Icon(
              Icons.local_fire_department,
              size: 80,
              color: Colors.orange,
            ),
            Text(
              '$streakCount',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              'Day streak',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade300,
              ),
            ),
            SizedBox(height: 3.h),
            
            // Week Activity Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].asMap().entries.map((entry) {
                final isActive = entry.key < weekActivity.length && weekActivity[entry.key];
                return Column(
                  children: [
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.orange : context.borderColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 3.h),
            
            // Message
            Text(
              "You're on fire! Every day matters\nfor hitting your goal!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textColor.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 3.h),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: context.cardColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}