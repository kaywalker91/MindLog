import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Tracks whether timezone database has been initialized.
bool _timeZoneInitialized = false;

/// Initializes the timezone database on first use.
void _ensureTimeZoneInitialized() {
  if (!_timeZoneInitialized) {
    tz_data.initializeTimeZones();
    _timeZoneInitialized = true;
  }
}

/// Returns the current time in KST (Korea Standard Time, UTC+09:00).
///
/// The returned DateTime has a timeZoneOffset of +09:00.
DateTime getCurrentKstTime() {
  _ensureTimeZoneInitialized();
  final kstZone = tz.getLocation('Asia/Seoul');
  final now = tz.TZDateTime.now(kstZone);
  return now;
}

/// Converts a UTC DateTime to KST (Korea Standard Time, UTC+09:00).
///
/// Takes a [utc] DateTime (isUtc=true expected) and returns a DateTime
/// representing the same instant in KST with timeZoneOffset +09:00.
DateTime utcToKst(DateTime utc) {
  _ensureTimeZoneInitialized();
  final kstZone = tz.getLocation('Asia/Seoul');
  final kstTime = tz.TZDateTime.from(utc, kstZone);
  return kstTime;
}

/// Formats a DateTime as ISO8601 string with KST offset (+09:00).
///
/// Returns a string in the format: YYYY-MM-DDTHH:mm:ss+09:00
String formatIso8601Kst(DateTime dt) {
  final formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
  return '${formatter.format(dt)}+09:00';
}
