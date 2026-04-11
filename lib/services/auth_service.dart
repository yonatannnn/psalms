import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _local = LocalStorageService.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with username and password (requires internet)
  Future<UserModel?> signUp({
    required String username,
    required String password,
  }) async {
    try {
      final String email = '$username@mezmuredawit.local';

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        final UserModel userModel = UserModel(
          id: user.uid,
          username: username,
          password: password,
          authEmail: email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        // Cache user data locally
        await _local.saveUser(userModel);

        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with username and password (requires internet)
  Future<UserModel?> signIn({
    required String username,
    required String password,
  }) async {
    try {
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
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final UserModel userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>);

          // Update last login time (fire-and-forget)
          _firestore
              .collection('users')
              .doc(user.uid)
              .update({'lastLoginAt': DateTime.now().toIso8601String()})
              .catchError((_) {});

          final updated = userModel.copyWith(lastLoginAt: DateTime.now());

          // Cache user data locally
          await _local.saveUser(updated);

          return updated;
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
      await _local.clearUser();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get current user data — local-first, falls back to Firestore, then syncs
  Future<UserModel?> getCurrentUserData() async {
    try {
      final User? user = currentUser;
      if (user == null) return null;

      // Try local cache first
      final cached = await _local.getUser();
      if (cached != null && cached.id == user.uid) {
        // Sync from Firestore in background to keep local cache fresh
        _syncUserFromFirestore(user.uid);
        return cached;
      }

      // No cache — fetch from Firestore
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>);
        await _local.saveUser(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      // If Firestore fails (offline), return cached data
      final cached = await _local.getUser();
      if (cached != null) return cached;
      throw Exception('Failed to get user data: $e');
    }
  }

  // Background sync: fetch latest user data from Firestore and update cache
  void _syncUserFromFirestore(String uid) {
    Future.microtask(() async {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          await _local.saveUser(userModel);
        }
      } catch (_) {
        // Silently fail — local cache is still valid
      }
    });
  }

  // Check if username is available (requires internet)
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(2)
          .get();

      if (result.docs.isEmpty) return true;
      if (excludeUserId != null &&
          result.docs.every((d) => d.id == excludeUserId)) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // Track daily app open — local-first, syncs to Firestore in background
  Future<void> trackDailyOpen(String userId) async {
    // Always track locally
    await _local.trackDailyOpen();

    // Try to sync to Firestore in background
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
    } catch (_) {
      // Offline — local tracking still works
    }
  }

  // Update username and/or password (requires internet)
  Future<void> updateCredentials({
    String? newUsername,
    String? newPassword,
    required String currentPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');
      final currentUsername = (userDoc.data() as Map<String, dynamic>)['username'] as String;
      final currentEmail = '$currentUsername@mezmuredawit.local';
      final cred = EmailAuthProvider.credential(email: currentEmail, password: currentPassword);
      await user.reauthenticateWithCredential(cred);

      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      final normalized = newUsername?.trim();
      if (normalized != null && normalized.isNotEmpty && normalized != currentUsername) {
        final valid = RegExp(r'^[A-Za-z0-9_.-]{3,}$').hasMatch(normalized);
        if (!valid) {
          throw Exception('invalid-username');
        }
        final available = await isUsernameAvailable(normalized, excludeUserId: user.uid);
        if (!available) throw Exception('Username is already taken');
        await _firestore.collection('users').doc(user.uid).update({
          'username': normalized,
          if (newPassword != null && newPassword.isNotEmpty) 'password': newPassword,
        });
      } else if (newPassword != null && newPassword.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update({'password': newPassword});
      }

      // Update local cache after successful credential update
      final updatedDoc = await _firestore.collection('users').doc(user.uid).get();
      if (updatedDoc.exists) {
        final updatedUser = UserModel.fromJson(updatedDoc.data() as Map<String, dynamic>);
        await _local.saveUser(updatedUser);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('Failed to update credentials: $e');
    }
  }
}
