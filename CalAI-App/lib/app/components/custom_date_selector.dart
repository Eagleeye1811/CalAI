import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:CalAI/app/constants/colors.dart';

class CustomDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<String, bool> datesWithActivity;
  
  const CustomDateSelector({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.datesWithActivity = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(7, (index) {
      return now.subtract(Duration(days: 3 - index));
    });

    return Container(
      height: 10.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;
          
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final hasActivity = datesWithActivity[dateKey] ?? false;
          
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 13.w,
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).substring(0, 3),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? context.textColor : context.textColor.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  Container(
                    width: 11.w,
                    height: 11.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? Colors.green 
                            : (hasActivity ? Colors.green : context.borderColor),
                        width: isSelected ? 2 : (hasActivity ? 2 : 1.5),
                        style: (isSelected || hasActivity) ? BorderStyle.solid : BorderStyle.none,
                      ),
                    ),
                    child: CustomPaint(
                      painter: (isSelected || hasActivity) ? null : DottedCirclePainter(context: context),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : (hasActivity ? Colors.green : context.textColor.withOpacity(0.4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DottedCirclePainter extends CustomPainter {
  final BuildContext context;
  
  const DottedCirclePainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = context.borderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    
    var angle = 0.0;
    while (angle < 360) {
      final x1 = center.dx + radius * cos(angle * pi / 180);
      final y1 = center.dy + radius * sin(angle * pi / 180);
      
      final nextAngle = angle + dashWidth;
      final x2 = center.dx + radius * cos(nextAngle * pi / 180);
      final y2 = center.dy + radius * sin(nextAngle * pi / 180);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      angle += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}