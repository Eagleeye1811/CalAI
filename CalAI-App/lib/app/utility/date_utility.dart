class DateUtility {
  static String getTimeFromDateTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String amPm = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour % 12 == 0 ? 12 : hour % 12;

    String minuteStr = minute.toString().padLeft(2, '0');

    return "$hour12:$minuteStr $amPm";
  }

  // ADD THIS METHOD
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return getTimeFromDateTime(dateTime);
    }
  }
}