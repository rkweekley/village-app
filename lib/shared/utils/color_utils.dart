import 'package:flutter/material.dart';

/// Shared color parsing utility used across the app.
///
/// Accepts a color string that is either:
/// - A named color (case-insensitive): red, pink, purple, deep_purple,
///   indigo, blue, light_blue, cyan, teal, green, light_green, lime,
///   yellow, amber, orange, deep_orange, brown, grey/gray, blue_grey
/// - A hex color string: #FF0000 or #FF000000 (with optional '#' prefix)
///
/// Returns [Colors.blue] as default fallback for null/empty/unparsable values.
Color parseColor(String? color) {
  if (color == null || color.isEmpty) return Colors.blue;

  switch (color.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'pink':
      return Colors.pink;
    case 'purple':
      return Colors.purple;
    case 'deep_purple':
      return Colors.deepPurple;
    case 'indigo':
      return Colors.indigo;
    case 'blue':
      return Colors.blue;
    case 'light_blue':
      return Colors.lightBlue;
    case 'cyan':
      return Colors.cyan;
    case 'teal':
      return Colors.teal;
    case 'green':
      return Colors.green;
    case 'light_green':
      return Colors.lightGreen;
    case 'lime':
      return Colors.lime;
    case 'yellow':
      return Colors.yellow;
    case 'amber':
      return Colors.amber;
    case 'orange':
      return Colors.orange;
    case 'deep_orange':
      return Colors.deepOrange;
    case 'brown':
      return Colors.brown;
    case 'grey':
    case 'gray':
      return Colors.grey;
    case 'blue_grey':
      return Colors.blueGrey;
    default:
      // Try parsing as hex
      try {
        var hex = color.replaceAll('#', '');
        if (hex.length == 3) {
          // Expand 3-digit shorthand: #F00 → FF0000
          hex = hex.split('').map((c) => '$c$c').join();
        }
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
        if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
      return Colors.blue;
  }
}
