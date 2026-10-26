/// Helpers for the `yyyy-MM-dd` day keys and the hour labels used by the app.
abstract final class DateKey {
  /// Local date as `yyyy-MM-dd`.
  static String of(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parses `yyyy-MM-dd` into a local date at midnight. Returns null when the
  /// text is not a valid key.
  static DateTime? parse(String key) {
    final List<String> parts = key.split('-');
    if (parts.length != 3) {
      return null;
    }
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    final DateTime parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  /// Strips the time part from [value].
  static DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// `9` becomes `09:00`.
  static String hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  /// `9` becomes `09:00 - 10:00`.
  static String hourRangeLabel(int hour) => '${hourLabel(hour)} - ${hourLabel(hour + 1)}';
}
