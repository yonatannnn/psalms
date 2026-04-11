import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reading_preferences_model.dart';
import 'local_storage_service.dart';

class ReadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _local = LocalStorageService.instance;

  // Save reading preferences — local-first, then sync to Firestore
  Future<void> saveReadingPreferences(ReadingPreferencesModel preferences) async {
    // Save locally first (instant)
    await _local.saveReadingPreferences(preferences);

    // Sync to Firestore in background
    try {
      await _firestore
          .collection('reading_preferences')
          .doc(preferences.userId)
          .set(preferences.toJson());
    } catch (_) {
      // Offline — local save is sufficient, will sync next time
    }
  }

  // Get reading preferences — local-first, falls back to Firestore
  Future<ReadingPreferencesModel?> getReadingPreferences(String userId) async {
    // Try local cache first
    final cached = await _local.getReadingPreferences(userId);
    if (cached != null) {
      // Background sync from Firestore to keep cache fresh
      _syncFromFirestore(userId);
      return cached;
    }

    // No local data — try Firestore
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('reading_preferences')
          .doc(userId)
          .get();

      if (doc.exists) {
        final prefs = ReadingPreferencesModel.fromJson(
            doc.data() as Map<String, dynamic>);
        await _local.saveReadingPreferences(prefs);
        return prefs;
      }
      return null;
    } catch (_) {
      // Offline and no cache
      return null;
    }
  }

  // Update reading preferences — local-first, then sync
  Future<void> updateReadingPreferences(ReadingPreferencesModel preferences) async {
    final updatedPreferences = preferences.copyWith(updatedAt: DateTime.now());

    // Save locally first
    await _local.saveReadingPreferences(updatedPreferences);

    // Sync to Firestore in background
    try {
      await _firestore
          .collection('reading_preferences')
          .doc(preferences.userId)
          .update(updatedPreferences.toJson());
    } catch (_) {
      // If update fails (doc doesn't exist remotely), try set
      try {
        await _firestore
            .collection('reading_preferences')
            .doc(preferences.userId)
            .set(updatedPreferences.toJson());
      } catch (_) {
        // Offline — local save is sufficient
      }
    }
  }

  // Check if user has reading preferences — local-first
  Future<bool> hasReadingPreferences(String userId) async {
    // Check local first
    final cached = await _local.getReadingPreferences(userId);
    if (cached != null) return true;

    // Try Firestore
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('reading_preferences')
          .doc(userId)
          .get();
      if (doc.exists) {
        // Cache it locally
        final prefs = ReadingPreferencesModel.fromJson(
            doc.data() as Map<String, dynamic>);
        await _local.saveReadingPreferences(prefs);
      }
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // Background sync: fetch from Firestore and update local cache
  void _syncFromFirestore(String userId) {
    Future.microtask(() async {
      try {
        final doc = await _firestore
            .collection('reading_preferences')
            .doc(userId)
            .get();
        if (doc.exists) {
          final prefs = ReadingPreferencesModel.fromJson(
              doc.data() as Map<String, dynamic>);
          await _local.saveReadingPreferences(prefs);
        }
      } catch (_) {
        // Silently fail
      }
    });
  }
}
