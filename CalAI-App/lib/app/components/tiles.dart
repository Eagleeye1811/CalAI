import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';

class PrimaryTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const PrimaryTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(bottom: 2.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? context.textColor
              : context.tileColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? context.cardColor
                          : context.textColor,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondaryTile extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const SecondaryTile({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(bottom: 2.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? context.textColor
              : context.tileColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? context.cardColor
                              : context.textColor,
                        ),
                  ),
                  SizedBox(height: 1.w),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: isSelected
                              ? context.cardColor.withOpacity(0.8)
                              : context.textColor.withOpacity(0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryIconTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const PrimaryIconTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(bottom: 2.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? context.textColor : context.tileColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? context.cardColor : context.textColor,
              child: Icon(
                icon,
                color: isSelected
                    ? context.textColor
                    : context.cardColor,
              ),
            ),
            SizedBox(width: 5.w),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? context.cardColor
                        : context.textColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealTimePicker extends StatefulWidget {
  final String title;
  final bool isSelected;
  final IconData icon;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const MealTimePicker({
    super.key,
    required this.title,
    required this.isSelected,
    required this.icon,
    required this.onTimeChanged,
  });

  @override
  _MealTimePickerState createState() => _MealTimePickerState();
}

class _MealTimePickerState extends State<MealTimePicker> {
  TimeOfDay? selectedTime;

  Future<void> _pickTime(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: isDarkMode ? ThemeData.dark() : ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: context.textColor,
              onPrimary: context.cardColor,
              surface: context.tileColor,
              onSurface: context.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
      widget.onTimeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickTime(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(bottom: 8.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? context.textColor
              : context.tileColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.isSelected
                      ? context.cardColor
                      : context.textColor,
                  child: Icon(
                    widget.icon,
                    color: widget.isSelected
                        ? context.textColor
                        : context.cardColor,
                  ),
                ),
                SizedBox(width: 16.0),
                Text(
                  selectedTime != null
                      ? selectedTime!.format(context)
                      : widget.title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected
                            ? context.cardColor
                            : context.textColor,
                      ),
                ),
              ],
            ),
            Icon(
              selectedTime != null ? Icons.edit : Icons.add,
              color: widget.isSelected
                  ? context.cardColor
                  : context.textColor,
            ),
          ],
        ),
      ),
    );
  }
}