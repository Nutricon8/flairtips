import 'package:intl/intl.dart';

/// Parse UTC ISO string and return local DateTime
DateTime parseUtcToLocal(String utcIsoString) {
  final utcDateTime = DateTime.parse(utcIsoString);
  return utcDateTime.toLocal();
}

/// Format as "Wed, 29 Apr 2025"
String formatMatchDate(String utcIsoString) {
  final localDateTime = parseUtcToLocal(utcIsoString);
  return DateFormat('E, d MMM y').format(localDateTime);
}

/// Format as "21:00"
String formatTime(String utcIsoString) {
  final localDateTime = parseUtcToLocal(utcIsoString);
  return DateFormat('HH:mm').format(localDateTime);
}

/// Format as "17:00PM, 29-04-2025"
String formatFixtureDate(String utcIsoString) {
  final localDateTime = parseUtcToLocal(utcIsoString);

  // Get hour to determine AM/PM
  final hour = localDateTime.hour;
  final isPM = hour >= 12;
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  // Format date
  final dateFormat = DateFormat('dd-MM-yyyy');

  return '${displayHour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}${isPM ? 'PM' : 'AM'}, ${dateFormat.format(localDateTime)}';
}
/// Step 1: Parse the UTC ISO string and return local DateTime.
/*DateTime parseUtcToLocal(String utcIsoString) {
  // DateTime.parse correctly handles "Z" as UTC
  final utcDateTime = DateTime.parse(utcIsoString);
  return utcDateTime.toLocal();
}

/// Step 2: Format local DateTime as "Wed, 29 Apr 2025"
String formatMatchDate(String utcIsoString) {
  final localDateTime = parseUtcToLocal(utcIsoString);
  return DateFormat('E, d MMM y').format(localDateTime);
}

/// Step 3: Format local DateTime as "21:00"
String formatTime(String utcIsoString) {
  final localDateTime = parseUtcToLocal(utcIsoString);
  return DateFormat('HH:mm').format(localDateTime);
}

/// Step 4: Format as: "17:00PM, 29-04-2025"
String formatFixtureDate(String utcIsoString) {
  final localDateTime = parseUtcToLocal(utcIsoString);

  // You previously had "17:00PM", so we replicate that:
  final timeFormat = DateFormat('HH:mm'); // 24h format
  final dateFormat = DateFormat('dd-MM-yyyy'); // day-month-year

  final time = timeFormat.format(localDateTime);

  return '${time}PM, ${dateFormat.format(localDateTime)}';
}*/


/// Step 1: Parse the UTC date string and return local DateTime.
/*DateTime parseUtcFixtureToLocal(String input) {
  input = input.trim().toUpperCase();

  // Detect if AM/PM is present
  final hasAmPm = input.contains('AM') || input.contains('PM');
  final DateFormat inputFormat =
      hasAmPm
          ? DateFormat("hh:mma, dd-MM-yyyy")
          : DateFormat("HH:mm, dd-MM-yyyy");

  // Parse as UTC
  final utcDateTime = inputFormat.parseUtc(input);

  // Convert to local time
  //return utcDateTime.toLocal();
  return utcDateTime;
}

/// Step 2: Format local DateTime as "Wed, 29 Apr 2025"
String formatMatchDate(String utcInput) {
  final localDateTime = parseUtcFixtureToLocal(utcInput);
  return DateFormat('E, d MMM y').format(localDateTime);
}

/// Step 3: Format local DateTime as "21:00"
String formatTime(String utcInput) {
  final localDateTime = parseUtcFixtureToLocal(utcInput);
  return DateFormat('HH:mm').format(localDateTime);
}*/