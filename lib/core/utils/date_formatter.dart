import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  static String formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    try {
      return _dateTime.format(parsed.toLocal());
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(parsed.toLocal());
    }
  }
}
