import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:CalAI/app/constants/enums.dart';

class CustomFoodsRepo {
  final usersCollection = FirebaseFirestore.instance.collection('users');

  /// Save a custom food to user's custom foods collection
  Future<QueryStatus> saveCustomFood(
    String userId,
    Map<String, dynamic> foodData,
  ) async {
    try {
      // Add timestamp for sorting
      foodData['createdAt'] = DateTime.now().toIso8601String();
      
      // Use description as document ID to prevent duplicates
      final docId = foodData['description'].toString().replaceAll(' ', '_').toLowerCase();
      
      await usersCollection
          .doc(userId)
          .collection('customFoods')
          .doc(docId)
          .set(foodData);

      return QueryStatus.SUCCESS;
    } catch (e) {
      print("Error saving custom food: $e");
      return QueryStatus.FAILED;
    }
  }

  /// Get all custom foods for a user
  Future<List<Map<String, dynamic>>> getUserCustomFoods(String userId) async {
    try {
      final snapshot = await usersCollection
          .doc(userId)
          .collection('customFoods')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting custom foods: $e");
      return [];
    }
  }

  /// Delete a custom food
  Future<QueryStatus> deleteCustomFood(
    String userId,
    String description,
  ) async {
    try {
      final docId = description.replaceAll(' ', '_').toLowerCase();
      
      await usersCollection
          .doc(userId)
          .collection('customFoods')
          .doc(docId)
          .delete();

      return QueryStatus.SUCCESS;
    } catch (e) {
      print("Error deleting custom food: $e");
      return QueryStatus.FAILED;
    }
  }
}