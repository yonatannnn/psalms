import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with username and password
  Future<UserModel?> signUp({
    required String username,
    required String password,
  }) async {
    try {
      // Create user with Firebase Auth using username as email
      // We'll use a dummy email format since Firebase requires email
      final String email = '$username@mezmuredawit.local';
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Create user document in Firestore
        final UserModel userModel = UserModel(
          id: user.uid,
          username: username,
          password: password, // Note: In production, don't store plain password
          authEmail: email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with username and password
  Future<UserModel?> signIn({
    required String username,
    required String password,
  }) async {
    try {
      // Look up user by username in Firestore to get authEmail
      final QuerySnapshot qs = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        throw Exception('user-not-found');
      }
      final data = qs.docs.first.data() as Map<String, dynamic>;
      final String authEmail = data['authEmail'] as String;

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Get user data from Firestore
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final UserModel userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          
          // Update last login time
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({'lastLoginAt': DateTime.now().toIso8601String()});

          return userModel.copyWith(lastLoginAt: DateTime.now());
        }
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      final User? user = currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(2)
          .get();

      if (result.docs.isEmpty) return true;
      // If only our own document matches, it's available
      if (excludeUserId != null &&
          result.docs.every((d) => d.id == excludeUserId)) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // Track daily app open: increments count only once per day
  Future<void> trackDailyOpen(String userId) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final snap = await docRef.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final int currentCount = (data['dailyOpenCount'] as int?) ?? 0;
      final String? lastDate = data['lastOpenDate'] as String?;
      final String today = DateTime.now().toIso8601String().split('T').first;
      if (lastDate != today) {
        await docRef.update({
          'dailyOpenCount': currentCount + 1,
          'lastOpenDate': today,
        });
      }
    } catch (e) {
      // Do not crash app on analytics write failure
    }
  }
  // Update username and/or password (requires current password)
  Future<void> updateCredentials({
    String? newUsername,
    String? newPassword,
    required String currentPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      // Reauthenticate
      // Email is derived from current username in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');
      final currentUsername = (userDoc.data() as Map<String, dynamic>)['username'] as String;
      final currentEmail = '$currentUsername@mezmuredawit.local';
      final cred = EmailAuthProvider.credential(email: currentEmail, password: currentPassword);
      await user.reauthenticateWithCredential(cred);

      // Update password
      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      // Normalize proposed username
      final normalized = newUsername?.trim();
      // Update username in Firestore; keep authEmail immutable to avoid provider restrictions
      if (normalized != null && normalized.isNotEmpty && normalized != currentUsername) {
        // Simple validation for username -> email mapping
        final valid = RegExp(r'^[A-Za-z0-9_.-]{3,}$').hasMatch(normalized);
        if (!valid) {
          throw Exception('invalid-username');
        }
        // Check availability
        final available = await isUsernameAvailable(normalized, excludeUserId: user.uid);
        if (!available) throw Exception('Username is already taken');
        await _firestore.collection('users').doc(user.uid).update({
          'username': normalized,
          if (newPassword != null && newPassword.isNotEmpty) 'password': newPassword,
        });
      } else if (newPassword != null && newPassword.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update({'password': newPassword});
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('Failed to update credentials: $e');
    }
  }
}
