import 'package:flutter/material.dart';
import 'package:village_app/core/theme/village_theme.dart';

/// Returns the on-surface semantic color for a chore/meal difficulty level.
///
/// Theme-aware: bright on dark surfaces, dark on light surfaces, so the label
/// always clears WCAG AA against the background it is drawn on.
Color difficultyColor(BuildContext context, String difficulty) {
  final c = VillageSemanticColors.of(context);
  switch (difficulty) {
    case 'Easy':
      return c.positive;
    case 'Medium':
      return c.warning;
    case 'Hard':
      return c.danger;
    default:
      return Colors.grey;
  }
}

/// Returns a filled-background difficulty color.
///
/// Always the darker shade so white text passes on it in both light and dark
/// mode. Use for filled chips/avatars, not for text drawn on a surface.
Color difficultyColorFilled(String difficulty) {
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

/// Returns the on-surface semantic color for a subscription or assignment
/// status string. Theme-aware (see [difficultyColor]).
///
/// Handles subscription statuses (active, trial, past_due, expired, canceled)
/// and school-assignment statuses (Pending, Submitted, Graded, Excused).
Color statusColor(BuildContext context, String status) {
  final c = VillageSemanticColors.of(context);
  switch (status) {
    // Subscription domain
    case 'active':
      return c.positive;
    case 'trial':
      return Theme.of(context).colorScheme.primary;
    case 'past_due':
      return c.warning;
    case 'expired':
      return c.danger;
    case 'canceled':
      return Colors.grey;
    // Assignment domain
    case 'Pending':
      return c.warning;
    case 'Submitted':
      return c.info;
    case 'Graded':
      return c.positive;
    case 'Excused':
      return Colors.grey;
    default:
      return Colors.grey;
  }
}
