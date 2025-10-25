import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/repo/saved_foods_repo.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'nutrition_detail_page.dart';
import 'package:CalAI/app/constants/enums.dart';

class SavedFoodsPage extends StatefulWidget {
  const SavedFoodsPage({Key? key}) : super(key: key);

  @override
  State<SavedFoodsPage> createState() => _SavedFoodsPageState();
}

class _SavedFoodsPageState extends State<SavedFoodsPage> {
  final SavedFoodsRepo _repo = SavedFoodsRepo();
  List<Map<String, dynamic>> _savedFoods = [];
  bool _isLoading = true;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadSavedFoods();
  }

  Future<void> _loadSavedFoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID from AuthController
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _userId = authController.userId!;

      // Fetch saved foods
      final foods = await _repo.getSavedFoods(_userId);

      setState(() {
        _savedFoods = foods;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading saved foods: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFoodFromSaved(String foodName, int index) async {
    try {
      final result = await _repo.removeFoodFromFavorites(_userId, foodName);
      
      if (result == QueryStatus.SUCCESS) {
        setState(() {
          _savedFoods.removeAt(index);
        });
        
        Get.snackbar(
          'Removed',
          '$foodName removed from saved foods',
          backgroundColor: Colors.orange.withOpacity(0.2),
          colorText: Colors.orange.shade800,
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove food',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Foods',
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _savedFoods.isEmpty
              ? _buildEmptyState()
              : _buildFoodsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 80,
              color: context.textColor.withOpacity(0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Saved Foods',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Foods you save will appear here for quick access',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedFoods,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _savedFoods.length,
        itemBuilder: (context, index) {
          final food = _savedFoods[index];
          return _buildFoodItem(food, index);
        },
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food, int index) {
    return Bounceable(
      onTap: () {
        // Navigate to nutrition detail page
        Get.to(() => NutritionDetailPage(food: food));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    food['serving'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textColor.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      _buildNutrientTag(
                        '${food['calories']} cal',
                        Colors.orange,
                      ),
                      SizedBox(width: 2.w),
                      _buildNutrientTag(
                        'P: ${food['protein']}g',
                        Colors.blue,
                      ),
                      SizedBox(width: 2.w),
                      _buildNutrientTag(
                        'C: ${food['carbs']}g',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bookmark icon (filled)
            Column(
              children: [
                Bounceable(
                  onTap: () async {
                    // Confirm deletion
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: context.cardColor,
                        title: Text('Remove from Saved?', style: TextStyle(color: context.textColor)),
                        content: Text(
                          'Remove ${food['name']} from your saved foods?',
                          style: TextStyle(color: context.textColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: TextStyle(color: context.textColor)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      _removeFoodFromSaved(food['name'], index);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientTag(String text, MaterialColor color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }
}