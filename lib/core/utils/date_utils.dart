// Responsável: Alisson Batista (integração de datas)
import 'package:intl/intl.dart';

class DateHelpers {
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Chave de dia (UTC) usada pelo calendário para agrupar eventos.
  static DateTime utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Dias entre hoje e [d] (0 = hoje, 1 = amanhã, -1 = ontem).
  static int daysFromToday(DateTime d) =>
      dayOnly(d).difference(dayOnly(DateTime.now())).inDays;

  static String time(DateTime d) => DateFormat('HH:mm', 'pt_BR').format(d);
  static String shortDate(DateTime d) => DateFormat('dd/MM', 'pt_BR').format(d);
  static String fullDate(DateTime d) => DateFormat('dd/MM/yyyy', 'pt_BR').format(d);

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Ex.: "Quarta-feira, 30 de setembro"
  static String longDate(DateTime d) =>
      capitalize(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(d));

  /// Ex.: "Hoje, 18:00", "Amanhã, 23:59", "05/10 · 19:00"
  static String relative(DateTime d) {
    final n = daysFromToday(d);
    if (n == 0) return 'Hoje, ${time(d)}';
    if (n == 1) return 'Amanhã, ${time(d)}';
    return '${shortDate(d)} · ${time(d)}';
  }
}
