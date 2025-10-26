import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:calai/app/constants/colors.dart';
import 'package:calai/app/components/dialogs.dart';
import 'package:calai/app/repo/meals_repo.dart';
import 'package:calai/app/controllers/auth_controller.dart';
import 'package:calai/app/constants/enums.dart';
import 'food_database_page.dart';

class CreateMealPage extends StatefulWidget {
  final Map<String, dynamic>? existingMeal;
  final String? mealId;
  
  const CreateMealPage({
    Key? key,
    this.existingMeal,
    this.mealId,
  }) : super(key: key);

  @override
  State<CreateMealPage> createState() => _CreateMealPageState();
}

class _CreateMealPageState extends State<CreateMealPage> {
  final TextEditingController _mealNameController = TextEditingController();
  final List<Map<String, dynamic>> _mealItems = [];

  // Calculate totals from meal items
  int get totalCalories => _mealItems.fold(0, (sum, item) => sum + (item['calories'] as int));
  int get totalProtein => _mealItems.fold(0, (sum, item) => sum + (item['protein'] as int));
  int get totalCarbs => _mealItems.fold(0, (sum, item) => sum + (item['carbs'] as int));
  int get totalFat => _mealItems.fold(0, (sum, item) => sum + (item['fat'] as int));

  @override
  void initState() {
    super.initState();
    _loadExistingMeal();
  }

  void _loadExistingMeal() {
    if (widget.existingMeal != null) {
      _mealNameController.text = widget.existingMeal!['name'] ?? '';
      if (widget.existingMeal!['items'] != null) {
        _mealItems.addAll(List<Map<String, dynamic>>.from(widget.existingMeal!['items']));
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    super.dispose();
  }

  void _addMealItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddItemSheet(),
    );
  }

  void _removeMealItem(int index) {
    setState(() {
      _mealItems.removeAt(index);
    });
  }

  Future<void> _saveMeal() async {
    if (_mealNameController.text.isEmpty) {
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Please enter a meal name",
      );
      return;
    }

    if (_mealItems.isEmpty) {
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Please add at least one item to the meal",
      );
      return;
    }

    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "User not authenticated",
        );
        return;
      }

      AppDialogs.showLoadingDialog(
        title: widget.existingMeal != null ? "Updating Meal" : "Saving Meal",
        message: widget.existingMeal != null ? "Updating your meal..." : "Creating your custom meal...",
      );

      final mealData = {
        'name': _mealNameController.text,
        'items': _mealItems,
        'totalCalories': totalCalories,
        'totalProtein': totalProtein,
        'totalCarbs': totalCarbs,
        'totalFat': totalFat,
      };

      final result = await MealsRepo().saveMeal(authController.userId!, mealData);

      AppDialogs.hideDialog();

    if (result == QueryStatus.SUCCESS) {
        AppDialogs.showSuccessSnackbar(
            title: "Success",
            message: "${_mealNameController.text} has been ${widget.existingMeal != null ? 'updated' : 'created'}!",
        );
        
        Get.back(result: true);
    } else {
        AppDialogs.showErrorSnackbar(
            title: "Error",
            message: "Failed to ${widget.existingMeal != null ? 'update' : 'save'} meal",
        );
      }
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to ${widget.existingMeal != null ? 'update' : 'save'} meal: $e",
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
          widget.existingMeal != null ? 'Edit Meal' : 'Create Meal',
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMealNameInput(),
              SizedBox(height: 3.h),
              _buildCaloriesBox(),
              SizedBox(height: 2.h),
              _buildMacrosRow(),
              SizedBox(height: 3.h),
              _buildMealItemsSection(),
              SizedBox(height: 3.h),
              _buildSaveButton(),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: context.tileColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: TextField(
            controller: _mealNameController,
            decoration: InputDecoration(
              hintText: 'e.g., Breakfast Bowl, Post-Workout Meal',
              hintStyle: TextStyle(color: context.textColor.withOpacity(0.4), fontSize: 15),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(fontSize: 16, color: context.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: context.textColor, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calories',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textColor.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$totalCalories',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosRow() {
    return Row(
      children: [
        Expanded(child: _buildMacroBox('Protein', totalProtein, 'g', Colors.red)),
        SizedBox(width: 2.w),
        Expanded(child: _buildMacroBox('Carbs', totalCarbs, 'g', Colors.orange)),
        SizedBox(width: 2.w),
        Expanded(child: _buildMacroBox('Fats', totalFat, 'g', Colors.blue)),
      ],
    );
  }

  Widget _buildMacroBox(String label, int value, String unit, MaterialColor color) {
    IconData icon;
    if (label == 'Protein') {
      icon = Icons.restaurant_menu;
    } else if (label == 'Carbs') {
      icon = Icons.grain;
    } else {
      icon = Icons.water_drop;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$value$unit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Meal Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            Bounceable(
              onTap: _addMealItem,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Add Item',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _mealItems.isEmpty
            ? _buildEmptyItems()
            : _buildItemsList(),
      ],
    );
  }

  Widget _buildEmptyItems() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: context.textColor.withOpacity(0.4)),
          SizedBox(height: 1.h),
          Text(
            'No items added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textColor.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Tap "Add Item" to start building your meal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.textColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _mealItems.length,
      itemBuilder: (context, index) {
        final item = _mealItems[index];
        return _buildMealItemCard(item, index);
      },
    );
  }

  Widget _buildMealItemCard(Map<String, dynamic> item, int index) {
    return Container(
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${item['calories']} cal • P: ${item['protein']}g • C: ${item['carbs']}g • F: ${item['fat']}g',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade400),
            onPressed: () => _removeMealItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Bounceable(
      onTap: _saveMeal,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.textColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.existingMeal != null ? 'Update Meal' : 'Save Meal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.cardColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemSheet() {
    final TextEditingController searchController = TextEditingController();
    
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Add Food Item',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: context.tileColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  hintStyle: TextStyle(color: context.textColor.withOpacity(0.5), fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: context.textColor.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(color: context.textColor),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildQuickAddItem('Chicken Breast', 165, 31, 0, 4),
                _buildQuickAddItem('Brown Rice', 112, 3, 24, 1),
                _buildQuickAddItem('Broccoli', 55, 4, 11, 1),
                _buildQuickAddItem('Salmon', 206, 22, 0, 13),
                _buildQuickAddItem('Banana', 89, 1, 23, 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddItem(String name, int calories, int protein, int carbs, int fat) {
    return Bounceable(
      onTap: () {
        setState(() {
          _mealItems.add({
            'name': name,
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          });
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$calories cal • P: ${protein}g • C: ${carbs}g • F: ${fat}g',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle, color: Colors.black, size: 28),
          ],
        ),
      ),
    );
  }
}