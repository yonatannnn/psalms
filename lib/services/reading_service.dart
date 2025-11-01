import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reading_preferences_model.dart';

class ReadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save reading preferences
  Future<void> saveReadingPreferences(ReadingPreferencesModel preferences) async {
    try {
      print('ReadingService: Saving preferences to Firestore for user ${preferences.userId}');
      await _firestore
          .collection('reading_preferences')
          .doc(preferences.userId)
          .set(preferences.toJson());
      print('ReadingService: Preferences saved successfully to Firestore');
    } catch (e) {
      print('ReadingService: Error saving preferences: $e');
      throw Exception('Failed to save reading preferences: $e');
    }
  }

  // Get reading preferences for a user
  Future<ReadingPreferencesModel?> getReadingPreferences(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('reading_preferences')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (doc.exists) {
        return ReadingPreferencesModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get reading preferences: $e');
    }
  }

  // Update reading preferences
  Future<void> updateReadingPreferences(ReadingPreferencesModel preferences) async {
    try {
      final updatedPreferences = preferences.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('reading_preferences')
          .doc(preferences.userId)
          .update(updatedPreferences.toJson());
    } catch (e) {
      throw Exception('Failed to update reading preferences: $e');
    }
  }

  // Check if user has reading preferences
  Future<bool> hasReadingPreferences(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('reading_preferences')
          .doc(userId)
          .get(const GetOptions(source: Source.server));
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check reading preferences: $e');
    }
  }
}

