import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sunday_prayers_model.dart';

class SundayPrayersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save Sunday prayers configuration
  Future<void> saveSundayPrayers(SundayPrayersModel prayers) async {
    try {
      await _firestore
          .collection('sunday_prayers')
          .doc(prayers.userId)
          .set(prayers.toJson());
    } catch (e) {
      throw Exception('Failed to save Sunday prayers: $e');
    }
  }

  // Get Sunday prayers for a user
  Future<SundayPrayersModel?> getSundayPrayers(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('sunday_prayers')
          .doc(userId)
          .get();

      if (doc.exists) {
        return SundayPrayersModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get Sunday prayers: $e');
    }
  }

  // Update Sunday prayers
  Future<void> updateSundayPrayers(SundayPrayersModel prayers) async {
    try {
      final updatedPrayers = prayers.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('sunday_prayers')
          .doc(prayers.userId)
          .update(updatedPrayers.toJson());
    } catch (e) {
      throw Exception('Failed to update Sunday prayers: $e');
    }
  }

  // Check if user has Sunday prayers configured
  Future<bool> hasSundayPrayers(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('sunday_prayers')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check Sunday prayers: $e');
    }
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
