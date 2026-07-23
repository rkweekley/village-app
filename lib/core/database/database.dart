// Drift (SQLite) local database — offline-first storage.
//
// Full Drift schema will be defined in Sprint 2 during offline-first implementation.
// Tables for: families, users, chores, chore_assignments, completions,
// rewards, redemptions, points, calendar_events, attendees, shopping_items.
//
// To generate the Drift database code, run:
//   dart run build_runner build --delete-conflicting-outputs
//
// Example table definition:
//
// @DataClassName('FamilyRecord')
// class Families extends Table {
//   TextColumn get id => text()();
//   TextColumn get name => text()();
//   TextColumn get inviteCode => text().nullable()();
//   BoolColumn get isActive => boolean()();
//   DateTimeColumn get createdAt => dateTime()();
//   DateTimeColumn get updatedAt => dateTime()();
//
//   @override
//   Set<Column> get primaryKey => {id};
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder for the Drift database connection.
/// Will be swapped with generated code once schema is defined.
final databaseProvider = Provider<Object>((ref) {
  // TODO: replace with VillageDatabase() once Drift schema is generated
  return Object();
});
