import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class StringToDateUtil {

  static initializeTimezone() {
    // Initialize the timezone package
    tz.initializeTimeZones();
  }
  /// Converts a date string to a formatted date string.
  /// - `dateStr` is the input date string.
  /// - `format` is the desired output date format, default is 'yyyy-MM-dd – kk:mm'.
  static String formatDateTime(String dateStr, {String format = 'MMM-dd  hh:mm a'}) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat(format).format(parsedDate);
    } catch (e) {
      // Handle the exception if the date format is invalid or parsing fails
      print("Error parsing date: $e");
      return "Old Date";
    }
  }

  static String formatTimeStampToDateTime(int milliseconds, {String format = 'MMM-dd  hh:mm a'}) {

    try {
      DateTime parsedDate = DateTime.parse(DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(DateTime.fromMillisecondsSinceEpoch(milliseconds)));
      return DateFormat(format).format(parsedDate);
    } catch (e) {
      // Handle the exception if the date format is invalid or parsing fails
      print("Error parsing date: $e");
      return "Old Date";
    }
  }

  static String convertMillisecondsToDateTime(String milliseconds) {
    int secs = int.parse(milliseconds);

    // Convert milliseconds to DateTime
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(secs);

    // Format the DateTime to a human-readable string
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);

    return formattedDate;
  }

  /// Returns only the date part from a date string.
  /// - `dateStr` is the input date string.
  /// - `format` is the desired output date format, default is 'yyyy-MM-dd'.
  static String extractDate(String dateStr, {String format = 'yyyy-MMM-dd'}) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat(format).format(parsedDate);
    } catch (e) {
      // Handle the exception if the date format is invalid or parsing fails
      print("Error parsing date: $e");
      return "Old Date";
    }
  }

  /// Returns only the time part from a date string.
  /// - `dateStr` is the input date string.
  /// - `format` is the desired output time format, default is 'HH:mm:ss'.
  static String extractTime(String dateStr, {String format = 'hh:mm a'}) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat(format).format(parsedDate);
    } catch (e) {
      // Handle the exception if the time format is invalid or parsing fails
      print("Error parsing time: $e");
      return "Old Date";
    }
  }

  /// Custom method to format the date string as "Today", "Yesterday", or a formatted date like "OCT-25".
  static String formatToRelativeDay(String dateStr) {
    try {
      // Initialize Cairo timezone
      final cairo = tz.getLocation('Africa/Cairo');

      // Parse the input date in UTC and then convert it to Cairo time
      DateTime parsedDateUtc = DateTime.parse(dateStr).toUtc();
      DateTime parsedDate = tz.TZDateTime.from(parsedDateUtc, cairo);

      // Get current time in Cairo
      DateTime nowCairo = tz.TZDateTime.now(cairo);
      DateTime todayCairo = DateTime(nowCairo.year, nowCairo.month, nowCairo.day);
      DateTime yesterdayCairo = todayCairo.subtract(Duration(days: 1));

      // Format time as HH:mm a
      String timeString = DateFormat('hh:mm a').format(parsedDate);

      if (parsedDate.isAfter(todayCairo)) {
        return "Today, $timeString";
      } else if (parsedDate.isAfter(yesterdayCairo)) {
        return "Yesterday, $timeString";
      } else {
        return "${DateFormat('MMM-dd').format(parsedDate)}, $timeString"; // Example: OCT-25, 03:45 PM
      }
    } catch (e) {
      print("Error parsing date: $e");
      return "Old Date";
    }
  }

  static String formatOrderItemDateToRelativeDay(int date) {
    try {
      // Initialize Cairo timezone
      final cairo = tz.getLocation('Africa/Cairo');

      // Parse the input date in UTC and then convert it to Cairo time
      DateTime parsedDateUtc = DateTime.parse(DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(DateTime.fromMillisecondsSinceEpoch(date))).toUtc();
      DateTime parsedDate = tz.TZDateTime.from(parsedDateUtc, cairo);

      // Get current time in Cairo
      DateTime nowCairo = tz.TZDateTime.now(cairo);
      DateTime todayCairo = DateTime(nowCairo.year, nowCairo.month, nowCairo.day);
      DateTime yesterdayCairo = todayCairo.subtract(Duration(days: 1));

      // Format time as HH:mm a
      String timeString = DateFormat('hh:mm a').format(parsedDate);

      if (parsedDate.isAfter(todayCairo)) {
        return "Today, $timeString";
      } else if (parsedDate.isAfter(yesterdayCairo)) {
        return "Yesterday, $timeString";
      } else {
        return "${DateFormat('MMM-dd').format(parsedDate)}, $timeString"; // Example: OCT-25, 03:45 PM
      }
    } catch (e) {
      print("Error parsing date: $e");
      return "Old Date";
    }
  }
}
