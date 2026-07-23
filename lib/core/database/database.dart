// Sprint 1 stub for Drift offline database.
// Sprint 2: replace with generated Drift database + codegen.
//
// Schema definitions are documented here so we have a single source of
// truth for the offline tables. The actual implementation will use
// Drift annotations + build_runner when codegen is enabled.
//
// Tables:
//   profiles
//     id TEXT PK, display_name TEXT, email TEXT, role TEXT,
//     points_balance INT DEFAULT 0, avatar_url TEXT?,
//     family_id TEXT, updated_at TEXT
//
//   chores
//     id TEXT PK, family_id TEXT, name TEXT, description TEXT?,
//     point_value INT DEFAULT 10, frequency TEXT DEFAULT 'daily',
//     assigned_to TEXT?, is_completed INT DEFAULT 0,
//     due_date TEXT?, completed_at TEXT?, created_at TEXT, updated_at TEXT
//
//   rewards
//     id TEXT PK, family_id TEXT, name TEXT, description TEXT?,
//     point_cost INT DEFAULT 50, is_limited INT DEFAULT 0,
//     max_redemptions INT?, current_redemptions INT DEFAULT 0,
//     created_at TEXT, updated_at TEXT
//
//   sync_queue
//     id INT PK AUTOINCREMENT, entity_type TEXT, entity_id TEXT,
//     operation TEXT (create|update|delete), payload TEXT,
//     status TEXT DEFAULT 'pending' (pending|in_flight|failed|completed),
//     retry_count INT DEFAULT 0, error TEXT?,
//     created_at TEXT, last_attempt TEXT?

/// Placeholder for the Drift database.
///
/// In Sprint 2 this will become a @DriftDatabase class with
/// auto-generated DAOs. For now it documents the schema only.
abstract class LocalDatabase {
  /// Open (or create) the database file.
  Future<void> open();

  /// Close the database.
  void close();

  // ── Sync queue ─────────────────────────────────────────

  /// Enqueue a pending API operation for offline sync.
  int enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  });

  /// Fetch pending operations to process (max 50, oldest first).
  List<Map<String, dynamic>> getPendingSync();

  /// Mark a sync item as completed or failed.
  void markSynced(int syncId, {String? error});

  /// Count pending sync operations.
  int pendingCount();
}

/// In-memory stub implementation for development.
///
/// Does not persist data. Replace with a real Drift database in Sprint 2.
class MemoryLocalDatabase implements LocalDatabase {
  final _syncQueue = <Map<String, dynamic>>[];
  int _nextId = 1;

  @override
  Future<void> open() async {}

  @override
  void close() {}

  @override
  int enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) {
    final id = _nextId++;
    _syncQueue.add({
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'status': 'pending',
      'retry_count': 0,
      'error': null,
      'created_at': DateTime.now().toIso8601String(),
      'last_attempt': null,
    });
    return id;
  }

  @override
  List<Map<String, dynamic>> getPendingSync() {
    return _syncQueue
        .where((e) => e['status'] == 'pending')
        .take(50)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  void markSynced(int syncId, {String? error}) {
    final idx = _syncQueue.indexWhere((e) => e['id'] == syncId);
    if (idx == -1) return;
    _syncQueue[idx]['status'] = error == null ? 'completed' : 'failed';
    _syncQueue[idx]['retry_count'] = (_syncQueue[idx]['retry_count'] as int) + 1;
    _syncQueue[idx]['error'] = error;
    _syncQueue[idx]['last_attempt'] = DateTime.now().toIso8601String();
  }

  @override
  int pendingCount() {
    return _syncQueue.where((e) => e['status'] == 'pending').length;
  }
}
