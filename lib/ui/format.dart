import 'package:intl/intl.dart';

/// 文件大小格式化：1.2 MB。
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}

/// 消息时间：今天显示 HH:mm，否则显示 M月d日 HH:mm。
String formatTime(int timestamp, {String locale = 'en'}) {
  final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return DateFormat.Hm(locale).format(time);
  }
  if (time.year == now.year) {
    return DateFormat.MMMd(locale).add_Hm().format(time);
  }
  return DateFormat.yMMMd(locale).add_Hm().format(time);
}
