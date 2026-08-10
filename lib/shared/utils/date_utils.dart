/// Shared date formatting utilities for the Village app.
///
/// Formats an ISO-8601 date string into a human-readable short date.
library;

/// Formats an ISO-8601 datetime string into a short date like "Jan 5, 2025".
///
/// Set [includeYear] to `false` to omit the year (e.g. "Jan 5").
String formatDate(String iso, {bool includeYear = true}) {
  final d = DateTime.parse(iso);
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final month = months[d.month - 1];
  return includeYear ? '$month ${d.day}, ${d.year}' : '$month ${d.day}';
}
