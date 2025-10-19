import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/components/dialogs.dart';
import 'package:CalAI/app/repo/custom_foods_repo.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/constants/enums.dart';
import 'food_database_page.dart';

class AddNutrientsPage extends StatefulWidget {
  final String brandName;
  final String description;
  final String servingSize;
  final String servingsPerContainer;

  const AddNutrientsPage({
    Key? key,
    required this.brandName,
    required this.description,
    required this.servingSize,
    required this.servingsPerContainer,
  }) : super(key: key);

  @override
  State<AddNutrientsPage> createState() => _AddNutrientsPageState();
}

class _AddNutrientsPageState extends State<AddNutrientsPage> {
  // Controllers for all nutrients
  final TextEditingController _caloriesController = TextEditingController(text: '0');
  final TextEditingController _proteinController = TextEditingController(text: '0');
  final TextEditingController _carbsController = TextEditingController(text: '0');
  final TextEditingController _fatController = TextEditingController(text: '0');
  final TextEditingController _fiberController = TextEditingController(text: '0');
  final TextEditingController _sugarController = TextEditingController(text: '0');
  final TextEditingController _sodiumController = TextEditingController(text: '0');
  final TextEditingController _saturatedFatController = TextEditingController(text: '0');
  final TextEditingController _transFatController = TextEditingController(text: '0');
  final TextEditingController _cholesterolController = TextEditingController(text: '0');
  final TextEditingController _potassiumController = TextEditingController(text: '0');
  final TextEditingController _calciumController = TextEditingController(text: '0');
  final TextEditingController _ironController = TextEditingController(text: '0');
  final TextEditingController _vitaminAController = TextEditingController(text: '0');
  final TextEditingController _vitaminCController = TextEditingController(text: '0');
  final TextEditingController _vitaminDController = TextEditingController(text: '0');

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _saturatedFatController.dispose();
    _transFatController.dispose();
    _cholesterolController.dispose();
    _potassiumController.dispose();
    _calciumController.dispose();
    _ironController.dispose();
    _vitaminAController.dispose();
    _vitaminCController.dispose();
    _vitaminDController.dispose();
    super.dispose();
  }

  Future<void> _saveFood() async {
    try {
      // Get user ID from AuthController
      final authController = Get.find<AuthController>();  // ✅ CHANGED
      if (!authController.isAuthenticated) {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "User not authenticated",
        );
        return;
      }

      AppDialogs.showLoadingDialog(
        title: "Saving Food",
        message: "Creating your custom food...",
      );

      // Prepare food data
      final foodData = {
        'brandName': widget.brandName,
        'description': widget.description,
        'servingSize': widget.servingSize,
        'servingsPerContainer': widget.servingsPerContainer,
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'protein': int.tryParse(_proteinController.text) ?? 0,
        'carbs': int.tryParse(_carbsController.text) ?? 0,
        'fat': int.tryParse(_fatController.text) ?? 0,
        'fiber': int.tryParse(_fiberController.text) ?? 0,
        'sugar': int.tryParse(_sugarController.text) ?? 0,
        'sodium': int.tryParse(_sodiumController.text) ?? 0,
        'saturatedFat': int.tryParse(_saturatedFatController.text) ?? 0,
        'transFat': int.tryParse(_transFatController.text) ?? 0,
        'cholesterol': int.tryParse(_cholesterolController.text) ?? 0,
        'potassium': int.tryParse(_potassiumController.text) ?? 0,
        'calcium': int.tryParse(_calciumController.text) ?? 0,
        'iron': int.tryParse(_ironController.text) ?? 0,
        'vitaminA': int.tryParse(_vitaminAController.text) ?? 0,
        'vitaminC': int.tryParse(_vitaminCController.text) ?? 0,
        'vitaminD': int.tryParse(_vitaminDController.text) ?? 0,
      };

      // Save to Firestore
      final result = await CustomFoodsRepo().saveCustomFood(authController.userId!, foodData);

      AppDialogs.hideDialog();

      if (result == QueryStatus.SUCCESS) {
        AppDialogs.showSuccessSnackbar(
          title: "Success",
          message: "${widget.description} has been created!",
        );
        
        // Navigate back to FoodDatabasePage with "My foods" tab selected
        Get.off(() => FoodDatabasePage(initialTabIndex: 2));
      } else {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "Failed to save food",
        );
      }
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to save food: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MealAIColors.blackText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Nutrients',
          style: TextStyle(
            color: MealAIColors.blackText,
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
              // Progress indicator
              Row(
                children: [
                  _buildProgressDot(true),
                  Expanded(child: _buildProgressLine(true)),
                  _buildProgressDot(true),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Basic Info',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Nutrients',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 3.h),

              // Food summary card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.brandName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Serving: ${widget.servingSize}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Macronutrients Section
              _buildSectionTitle('Macronutrients'),
              SizedBox(height: 1.h),
              _buildNutrientInput('Calories', 'kcal', _caloriesController, Colors.orange),
              _buildNutrientInput('Protein', 'g', _proteinController, Colors.blue),
              _buildNutrientInput('Carbohydrates', 'g', _carbsController, Colors.green),
              _buildNutrientInput('Total Fat', 'g', _fatController, Colors.purple),
              _buildNutrientInput('Fiber', 'g', _fiberController, Colors.brown),
              _buildNutrientInput('Sugar', 'g', _sugarController, Colors.pink),

              SizedBox(height: 2.h),

              // Fats Section
              _buildSectionTitle('Fats'),
              SizedBox(height: 1.h),
              _buildNutrientInput('Saturated Fat', 'g', _saturatedFatController, Colors.red),
              _buildNutrientInput('Trans Fat', 'g', _transFatController, Colors.deepOrange),

              SizedBox(height: 2.h),

              // Minerals Section
              _buildSectionTitle('Minerals'),
              SizedBox(height: 1.h),
              _buildNutrientInput('Sodium', 'mg', _sodiumController, Colors.amber),
              _buildNutrientInput('Cholesterol', 'mg', _cholesterolController, Colors.red),
              _buildNutrientInput('Potassium', 'mg', _potassiumController, Colors.indigo),
              _buildNutrientInput('Calcium', 'mg', _calciumController, Colors.cyan),
              _buildNutrientInput('Iron', 'mg', _ironController, Colors.grey),

              SizedBox(height: 2.h),

              // Vitamins Section
              _buildSectionTitle('Vitamins'),
              SizedBox(height: 1.h),
              _buildNutrientInput('Vitamin A', 'mcg', _vitaminAController, Colors.orange),
              _buildNutrientInput('Vitamin C', 'mg', _vitaminCController, Colors.yellow),
              _buildNutrientInput('Vitamin D', 'mcg', _vitaminDController, Colors.lime),

              SizedBox(height: 3.h),

              // Save button
              _buildSaveButton(),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool active) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? MealAIColors.blackText : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(bool active) {
    return Container(
      height: 2,
      color: active ? MealAIColors.blackText : Colors.grey.shade300,
      margin: EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: MealAIColors.blackText,
      ),
    );
  }

  Widget _buildNutrientInput(
    String label,
    String unit,
    TextEditingController controller,
    MaterialColor color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Bounceable(
      onTap: _saveFood,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: MealAIColors.blackText,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Save Food',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}