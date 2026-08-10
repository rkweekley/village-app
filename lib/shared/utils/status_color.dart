import 'package:flutter/material.dart';
import 'package:village_app/core/theme/village_theme.dart';

/// Returns the semantic color for a chore/meal difficulty level.
Color difficultyColor(String difficulty) {
  switch (difficulty) {
    case 'Easy':
      return VillageTheme.positive;
    case 'Medium':
      return VillageTheme.warning;
    case 'Hard':
      return VillageTheme.danger;
    default:
      return Colors.grey;
  }
}

/// Returns the semantic color for a subscription or assignment status string.
///
/// Handles subscription statuses (active, trial, past_due, expired, canceled)
/// and school-assignment statuses (Pending, Submitted, Graded, Excused).
Color statusColor(String status) {
  switch (status) {
    // Subscription domain
    case 'active':
      return VillageTheme.positive;
    case 'trial':
      return VillageTheme.primary;
    case 'past_due':
      return VillageTheme.warning;
    case 'expired':
      return VillageTheme.danger;
    case 'canceled':
      return Colors.grey;
    // Assignment domain
    case 'Pending':
      return VillageTheme.warning;
    case 'Submitted':
      return VillageTheme.info;
    case 'Graded':
      return VillageTheme.positive;
    case 'Excused':
      return Colors.grey;
    default:
      return Colors.grey;
  }
}
