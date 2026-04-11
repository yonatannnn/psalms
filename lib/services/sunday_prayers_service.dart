import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sunday_prayers_model.dart';
import 'local_storage_service.dart';

class SundayPrayersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _local = LocalStorageService.instance;

  // Save Sunday prayers — local-first, then sync to Firestore
  Future<void> saveSundayPrayers(SundayPrayersModel prayers) async {
    // Save locally first
    await _local.saveSundayPrayers(prayers);

    // Sync to Firestore in background
    try {
      await _firestore
          .collection('sunday_prayers')
          .doc(prayers.userId)
          .set(prayers.toJson());
    } catch (_) {
      // Offline — local save is sufficient
    }
  }

  // Get Sunday prayers — local-first, falls back to Firestore
  Future<SundayPrayersModel?> getSundayPrayers(String userId) async {
    // Try local cache first
    final cached = await _local.getSundayPrayers(userId);
    if (cached != null) {
      // Background sync
      _syncFromFirestore(userId);
      return cached;
    }

    // No local data — try Firestore
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('sunday_prayers')
          .doc(userId)
          .get();

      if (doc.exists) {
        final prayers = SundayPrayersModel.fromJson(
            doc.data() as Map<String, dynamic>);
        await _local.saveSundayPrayers(prayers);
        return prayers;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Update Sunday prayers — local-first, then sync
  Future<void> updateSundayPrayers(SundayPrayersModel prayers) async {
    final updatedPrayers = prayers.copyWith(updatedAt: DateTime.now());

    // Save locally first
    await _local.saveSundayPrayers(updatedPrayers);

    // Sync to Firestore in background
    try {
      await _firestore
          .collection('sunday_prayers')
          .doc(prayers.userId)
          .update(updatedPrayers.toJson());
    } catch (_) {
      try {
        await _firestore
            .collection('sunday_prayers')
            .doc(prayers.userId)
            .set(updatedPrayers.toJson());
      } catch (_) {
        // Offline — local save is sufficient
      }
    }
  }

  // Check if user has Sunday prayers — local-first
  Future<bool> hasSundayPrayers(String userId) async {
    final cached = await _local.getSundayPrayers(userId);
    if (cached != null) return true;

    try {
      final DocumentSnapshot doc = await _firestore
          .collection('sunday_prayers')
          .doc(userId)
          .get();
      if (doc.exists) {
        final prayers = SundayPrayersModel.fromJson(
            doc.data() as Map<String, dynamic>);
        await _local.saveSundayPrayers(prayers);
      }
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // Background sync
  void _syncFromFirestore(String userId) {
    Future.microtask(() async {
      try {
        final doc = await _firestore
            .collection('sunday_prayers')
            .doc(userId)
            .get();
        if (doc.exists) {
          final prayers = SundayPrayersModel.fromJson(
              doc.data() as Map<String, dynamic>);
          await _local.saveSundayPrayers(prayers);
        }
      } catch (_) {}
    });
  }

  // Get Ethiopian Orthodox prayer topics
  static List<String> getEthiopianPrayerTopics() {
    return [
      '1. የሙሴ ጸሎት',
      '2. የሃና ጸሎት',
      '3. የሕዝቅያስ ጸሎት',
      '4. የሚናሴ ጸሎት',
      '5. የዮናስ ጸሎት',
      '6. የዳንኤል ጸሎት',
      '7. የሶስቱ ልጆች ጸሎት',
      '8. እምባቆም ጸሎት',
      '9. ኢሳያስ ጸሎት',
      '10. የማርያም ጸሎት',
      '11. የዘካርያስ ጸሎት',
      '12. የስምዖን ጸሎት',
      '13. የሰሎሞን ማህሊ 1',
      '14. የሰሎሞን ማህሊ 2',
      '15. የሰሎሞን ማህሊ 3',
      '16. የሰሎሞን ማህሊ 4',
      '17. የሰሎሞን ማህሊ 5'
    ];
  }

  // Get English translations of prayer topics
  static List<String> getEnglishPrayerTopics() {
    return [
      '1. Prayer of Moses',
      '2. Prayer of Hannah',
      '3. Prayer of Hezekiah',
      '4. Prayer of Manasseh',
      '5. Prayer of Jonah',
      '6. Prayer of Daniel',
      '7. Prayer of the Three Children',
      '8. Prayer of Habakkuk',
      '9. Prayer of Isaiah',
      '10. Prayer of Mary',
      '11. Prayer of Zechariah',
      '12. Prayer of Simeon',
      '13. Prayer of Solomon Mahli 1',
      '14. Prayer of Solomon Mahli 2',
      '15. Prayer of Solomon Mahli 3',
      '16. Prayer of Solomon Mahli 4',
      '17. Prayer of Solomon Mahli 5'
    ];
  }
}
