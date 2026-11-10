import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'firebase_providers.dart';

/// The single `settings/app` document (PRD section 8.1).
class SettingsRepository {
  SettingsRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection(Col.settings).doc(Col.settingsDoc);

  /// A missing document falls back to the PRD section 8.2 defaults, so a fresh
  /// project still renders prices instead of an error.
  Future<AppSettings> fetch() {
    return guardFirestore(() async {
      final snap = await _doc.get();
      return snap.exists ? AppSettings.fromDoc(snap) : AppSettings.defaults;
    });
  }

  /// PRD ADM-4: stamp every admin write.
  Future<void> save(AppSettings settings, {required String adminUid}) {
    return guardFirestore(() => _doc.set({
          ...settings.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminUid,
        }, SetOptions(merge: true)));
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(firestoreProvider)),
);

/// PRD section 13: cached in memory for the session. Invalidated after the
/// admin saves, and by the Retry button.
final settingsProvider = FutureProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).fetch(),
);
