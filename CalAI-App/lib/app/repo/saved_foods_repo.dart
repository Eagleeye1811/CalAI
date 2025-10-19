import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:CalAI/app/constants/enums.dart';

class SavedFoodsRepo {
  final usersCollection = FirebaseFirestore.instance.collection('users');

  /// Save a food to user's saved foods collection
  Future<QueryStatus> saveFoodToFavorites(
    String userId,
    Map<String, dynamic> foodData,
  ) async {
    try {
      // Add timestamp for sorting
      foodData['savedAt'] = DateTime.now().toIso8601String();
      
      // Use food name as document ID to prevent duplicates
      final docId = foodData['name'].toString().replaceAll(' ', '_').toLowerCase();
      
      await usersCollection
          .doc(userId)
          .collection('savedFoods')
          .doc(docId)
          .set(foodData);

      return QueryStatus.SUCCESS;
    } catch (e) {
      print("Error saving food: $e");
      return QueryStatus.FAILED;
    }
  }

  /// Remove a food from user's saved foods
  Future<QueryStatus> removeFoodFromFavorites(
    String userId,
    String foodName,
  ) async {
    try {
      final docId = foodName.replaceAll(' ', '_').toLowerCase();
      
      await usersCollection
          .doc(userId)
          .collection('savedFoods')
          .doc(docId)
          .delete();

      return QueryStatus.SUCCESS;
    } catch (e) {
      print("Error removing food: $e");
      return QueryStatus.FAILED;
    }
  }

  /// Get all saved foods for a user
  Future<List<Map<String, dynamic>>> getSavedFoods(String userId) async {
    try {
      final snapshot = await usersCollection
          .doc(userId)
          .collection('savedFoods')
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting saved foods: $e");
      return [];
    }
  }

  /// Check if a food is saved
  Future<bool> isFoodSaved(String userId, String foodName) async {
    try {
      final docId = foodName.replaceAll(' ', '_').toLowerCase();
      
      final doc = await usersCollection
          .doc(userId)
          .collection('savedFoods')
          .doc(docId)
          .get();

      return doc.exists;
    } catch (e) {
      print("Error checking if food is saved: $e");
      return false;
    }
  }
}