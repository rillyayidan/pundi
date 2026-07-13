import 'package:intl/intl.dart';

String formatDate(DateTime date) =>
    DateFormat('d MMM yyyy', 'id_ID').format(date);
String formatShortDate(DateTime date) => DateFormat('dd/MM/yy').format(date);
String formatMonth(DateTime date) =>
    DateFormat('MMMM yyyy', 'id_ID').format(date);

DateTime startOfMonth(DateTime value) => DateTime(value.year, value.month);
DateTime endOfMonth(DateTime value) => DateTime(value.year, value.month + 1);
