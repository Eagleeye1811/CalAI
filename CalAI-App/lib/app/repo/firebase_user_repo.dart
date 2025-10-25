import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/models/Auth/user_repo.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final usersCollection = FirebaseFirestore.instance.collection('users');

  FirebaseUserRepo({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser;
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<UserModel> signUp(UserModel myUser, String password) async {
    try {
      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
          email: myUser.email, password: password);

      myUser = myUser.copyWith(userId: user.user!.uid);

      return myUser;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> setUserData(UserModel myUser) async {
    try {
      await usersCollection.doc(myUser.userId).set(myUser.toEntity());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      log('Starting Google sign-in...');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        log('Google sign-in canceled');
        throw Exception('Google sign-in canceled');
      }

      log('Google sign-in successful: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        log('Google auth token retrieval failed');
        throw Exception('Google authentication tokens missing');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        log('Firebase user is null after Google sign-in');
        throw Exception('Firebase authentication failed');
      }

      log('Firebase sign-in successful: ${user.email}');
      return UserModel(
        userId: user.uid,
        email: user.email!,
        name: user.displayName ?? 'Unknown User',
        photoUrl: user.photoURL ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      log('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  Future<UserModel> getUserById(String userId) async {
    try {
      final DocumentSnapshot snapshot = await usersCollection.doc(userId).get();
      if (snapshot.exists) {
        return UserModel.fromEntity(snapshot.data() as Map<String, dynamic>);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> updateUserMacroData(String userId, UserBasicInfo info) async {
    try {
      await usersCollection.doc(userId).update({
        'user_info': {
          'macros': {
            'daily_calories': info.userMacros.calories,
            'daily_fat': info.userMacros.fat,
            'daily_protein': info.userMacros.protein,
            'daily_carb': info.userMacros.carbs,
            'daily_water': info.userMacros.water,
            'daily_fiber': info.userMacros.fiber,
          },
        }
      });
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      await usersCollection.doc(user.userId).update(user.toEntity());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // Add at the end of the FirebaseUserRepo class, before the closing brace

  /// Get weight history for a user
  Future<List<Map<String, dynamic>>> getWeightHistory(String userId) async {
    try {
      final snapshot = await usersCollection
          .doc(userId)
          .collection('weightHistory')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'date': (data['date'] as Timestamp).toDate(),
          'weight': (data['weight'] as num).toDouble(),
        };
      }).toList();
    } catch (e) {
      log('Error fetching weight history: $e');
      rethrow;
    }
  }

  /// Add a weight entry
  Future<void> addWeightEntry(String userId, double weight, DateTime date) async {
    try {
      await usersCollection
          .doc(userId)
          .collection('weightHistory')
          .doc(date.millisecondsSinceEpoch.toString())
          .set({
        'weight': weight,
        'date': Timestamp.fromDate(date),
      });
    } catch (e) {
      log('Error adding weight entry: $e');
      rethrow;
    }
  }

  /// Delete a weight entry
  Future<void> deleteWeightEntry(String userId, DateTime date) async {
    try {
      await usersCollection
          .doc(userId)
          .collection('weightHistory')
          .doc(date.millisecondsSinceEpoch.toString())
          .delete();
    } catch (e) {
      log('Error deleting weight entry: $e');
      rethrow;
    }
  }
}
