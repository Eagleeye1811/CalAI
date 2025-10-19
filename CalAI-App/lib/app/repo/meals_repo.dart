import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:CalAI/app/constants/enums.dart';

class MealsRepo {
  final usersCollection = FirebaseFirestore.instance.collection('users');

  /// Save a custom meal to user's meals collection
  Future<QueryStatus> saveMeal(
    String userId,
    Map<String, dynamic> mealData,
  ) async {
    try {
      // Add timestamp for sorting
      mealData['createdAt'] = DateTime.now().toIso8601String();
      
      // Use meal name as document ID to prevent duplicates
      final docId = mealData['name'].toString().replaceAll(' ', '_').toLowerCase();
      
      await usersCollection
          .doc(userId)
          .collection('customMeals')
          .doc(docId)
          .set(mealData);

      return QueryStatus.SUCCESS;
    } catch (e) {
      print("Error saving meal: $e");
      return QueryStatus.FAILED;
    }
  }

  /// Get all custom meals for a user
  Future<List<Map<String, dynamic>>> getUserMeals(String userId) async {
    try {
      final snapshot = await usersCollection
          .doc(userId)
          .collection('customMeals')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting meals: $e");
      return [];
    }
  }

  /// Delete a custom meal
  Future<QueryStatus> deleteMeal(
    String userId,
    String mealName,
  ) async {
    try {
      final docId = mealName.replaceAll(' ', '_').toLowerCase();
      
      await usersCollection
          .doc(userId)
          .collection('customMeals')
          .doc(docId)
          .delete();

      return QueryStatus.SUCCESS;
    } catch (e) {
      print("Error deleting meal: $e");
      return QueryStatus.FAILED;
    }
  }
}