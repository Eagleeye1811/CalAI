import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:calai/app/constants/colors.dart';
import 'package:calai/app/components/dialogs.dart';
import 'package:calai/app/controllers/auth_controller.dart';
import 'package:calai/app/constants/enums.dart';
import 'package:calai/app/models/AI/nutrition_output.dart';
import 'package:calai/app/models/AI/nutrition_record.dart';
import 'package:calai/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:calai/app/repo/nutrition_record_repo.dart';

class ManualFoodEntryPage extends StatefulWidget {
  const ManualFoodEntryPage({Key? key}) : super(key: key);

  @override
  State<ManualFoodEntryPage> createState() => _ManualFoodEntryPageState();
}

class _ManualFoodEntryPageState extends State<ManualFoodEntryPage> {
  String _foodName = 'Tap to name';
  int _quantity = 1;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isSaved = false;
  
  final List<Map<String, dynamic>> _ingredients = [];

  // Calculate totals from ingredients
  int get totalCalories => _ingredients.fold(0, (sum, item) => sum + (item['calories'] as int));
  int get totalProtein => _ingredients.fold(0, (sum, item) => sum + (item['protein'] as int));
  int get totalCarbs => _ingredients.fold(0, (sum, item) => sum + (item['carbs'] as int));
  int get totalFat => _ingredients.fold(0, (sum, item) => sum + (item['fat'] as int));
  int get totalFiber => _ingredients.fold(0, (sum, item) => sum + ((item['fiber'] ?? 0) as int));
  int get totalSugar => _ingredients.fold(0, (sum, item) => sum + ((item['sugar'] ?? 0) as int));
  int get totalSodium => _ingredients.fold(0, (sum, item) => sum + ((item['sodium'] ?? 0) as int));

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _foodName == 'Tap to name' ? '' : _foodName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Food Name', style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: context.textColor),
            decoration: InputDecoration(
              hintText: 'Enter food name',
              hintStyle: TextStyle(color: context.textColor.withOpacity(0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.textColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.textColor.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _foodName = controller.text;
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.textColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save', style: TextStyle(color: context.cardColor)),
            ),
          ],
        );
      },
    );
  }

  void _addIngredient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddIngredientSheet(),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _logFood() async {
    if (_foodName == 'Tap to name' || _foodName.isEmpty) {
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Please enter a food name",
      );
      return;
    }

    if (_ingredients.isEmpty) {
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Please add at least one ingredient",
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
        title: "Logging Food",
        message: "Adding to your meals...",
      );

      final userId = authController.userId!;
      final scannerController = Get.find<ScannerController>();

      final ingredientsList = _ingredients.map((ing) {
        return Ingredient(
          name: ing['name'],
          calories: ing['calories'] * _quantity,
          protein: ing['protein'] * _quantity,
          carbs: ing['carbs'] * _quantity,
          fat: ing['fat'] * _quantity,
          fiber: (ing['fiber'] ?? 0) * _quantity,
          sugar: (ing['sugar'] ?? 0) * _quantity,
          sodium: (ing['sodium'] ?? 0) * _quantity,
          healthScore: 7,
          healthComments: 'Manually entered ingredient',
        );
      }).toList();

      final nutritionResponse = NutritionResponse(
        foodName: _foodName,
        portion: '$_quantity serving${_quantity > 1 ? "s" : ""}',
        portionSize: _quantity.toDouble(),
        confidenceScore: 100,
        ingredients: ingredientsList,
        overallHealthScore: 7,
        overallHealthComments: 'Manually logged food',
      );

      final nutritionOutput = NutritionOutput(
        response: nutritionResponse,
        status: 1,
        message: 'Food added manually',
      );

      final nutritionRecord = NutritionRecord(
        nutritionOutput: nutritionOutput,
        recordTime: DateTime.now(),
        processingStatus: ProcessingStatus.COMPLETED,
        entrySource: EntrySource.MANUAL_ENTRY,
      );

      scannerController.dailyRecords.insert(0, nutritionRecord);
      scannerController.consumedCalories.value += totalCalories * _quantity;
      scannerController.consumedProtein.value += totalProtein * _quantity;
      scannerController.consumedCarb.value += totalCarbs * _quantity;
      scannerController.consumedFat.value += totalFat * _quantity;
      scannerController.consumedFiber.value += totalFiber * _quantity;
      scannerController.consumedSugar.value += totalSugar * _quantity;
      scannerController.consumedSodium.value += totalSodium * _quantity;

      if (scannerController.existingNutritionRecords != null) {
        scannerController.existingNutritionRecords!.dailyRecords.insert(0, nutritionRecord);
        scannerController.existingNutritionRecords!.dailyConsumedCalories += totalCalories * _quantity;
        scannerController.existingNutritionRecords!.dailyConsumedProtein += totalProtein * _quantity;
        scannerController.existingNutritionRecords!.dailyConsumedCarb += totalCarbs * _quantity;
        scannerController.existingNutritionRecords!.dailyConsumedFat += totalFat * _quantity;
        scannerController.existingNutritionRecords!.dailyConsumedFiber =
            (scannerController.existingNutritionRecords!.dailyConsumedFiber ?? 0) + totalFiber * _quantity;
        scannerController.existingNutritionRecords!.dailyConsumedSugar =
            (scannerController.existingNutritionRecords!.dailyConsumedSugar ?? 0) + totalSugar * _quantity;
        scannerController.existingNutritionRecords!.dailyConsumedSodium =
            (scannerController.existingNutritionRecords!.dailyConsumedSodium ?? 0) + totalSodium * _quantity;
      }

      final repo = NutritionRecordRepo();
      final result = await repo.saveNutritionData(
        scannerController.existingNutritionRecords!,
        userId,
      );

      scannerController.update();
      AppDialogs.hideDialog();

      if (result == QueryStatus.SUCCESS) {
        AppDialogs.showSuccessSnackbar(
          title: "Success",
          message: "$_foodName has been logged!",
        );
        Get.back();
        Get.back();
      } else {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "Failed to log food",
        );
      }
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to log food: $e",
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
          icon: Icon(Icons.arrow_back, color: context.textColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nutrition',
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: context.textColor, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bookmark and time
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSaved = !_isSaved;
                          });
                        },
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: context.textColor,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        DateFormat('hh:mm a').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Food name and quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showNameDialog,
                          child: Text(
                            _foodName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.borderColor, width: 2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.remove, size: 24, color: context.textColor),
                              ),
                            ),
                            SizedBox(width: 24),
                            Text(
                              '$_quantity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.add, size: 24, color: context.textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Nutrient carousel
                  SizedBox(
                    height: 340,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildPage1(),
                        _buildPage2(),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(0),
                      SizedBox(width: 8),
                      _buildDot(1),
                    ],
                  ),
                  SizedBox(height: 32),

                  // Ingredients section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: _addIngredient,
                        child: Text(
                          '+ Add',
                          style: TextStyle(
                            fontSize: 18,
                            color: context.textColor.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Ingredients list
                  _ingredients.isEmpty
                      ? SizedBox.shrink()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _ingredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = _ingredients[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.tileColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ingredient['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: context.textColor,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${ingredient['calories']} cal • ${ingredient['protein']}g P • ${ingredient['carbs']}g C • ${ingredient['fat']}g F',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: context.textColor.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeIngredient(index),
                                    child: Icon(Icons.close, color: context.textColor.withOpacity(0.6), size: 20),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Log button (fixed at bottom)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: context.textColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _logFood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.textColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Log',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textColor.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      children: [
        // Calories box
        Container(
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
                      '${totalCalories * _quantity}',
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
        ),
        SizedBox(height: 16),

        // Macros row
        Row(
          children: [
            Expanded(child: _buildMacroBox('Protein', totalProtein * _quantity, Icons.restaurant_menu, Colors.red)),
            SizedBox(width: 12),
            Expanded(child: _buildMacroBox('Carbs', totalCarbs * _quantity, Icons.grain, Colors.orange)),
            SizedBox(width: 12),
            Expanded(child: _buildMacroBox('Fats', totalFat * _quantity, Icons.water_drop, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      children: [
        // Fiber, Sugar, Sodium row
        Row(
          children: [
            Expanded(child: _buildNutrientBox('Fiber', totalFiber * _quantity, 'g', Icons.grass, Colors.purple)),
            SizedBox(width: 12),
            Expanded(child: _buildNutrientBox('Sugar', totalSugar * _quantity, 'g', Icons.cake, Colors.pink)),
            SizedBox(width: 12),
            Expanded(child: _buildNutrientBox('Sodium', totalSodium * _quantity, 'mg', Icons.opacity, Colors.orange)),
          ],
        ),
        SizedBox(height: 16),

        // Health Score box
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.tileColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Icon(Icons.favorite_border, color: Colors.red, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health score',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Text(
                'N/A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBox(String label, int value, IconData icon, Color color) {
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
            '${value}g',
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

  Widget _buildNutrientBox(String label, int value, String unit, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? context.textColor : context.borderColor,
      ),
    );
  }

  Widget _buildAddIngredientSheet() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final fiberController = TextEditingController();
    final sugarController = TextEditingController();
    final sodiumController = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Add Ingredient',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 20),
                _buildInputField('Ingredient Name', 'e.g., Chicken breast', nameController),
                SizedBox(height: 16),
                _buildInputField('Calories', '0', caloriesController, isNumber: true),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInputField('Protein (g)', '0', proteinController, isNumber: true)),
                    SizedBox(width: 12),
                    Expanded(child: _buildInputField('Carbs (g)', '0', carbsController, isNumber: true)),
                    SizedBox(width: 12),
                    Expanded(child: _buildInputField('Fat (g)', '0', fatController, isNumber: true)),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInputField('Fiber (g)', '0', fiberController, isNumber: true)),
                    SizedBox(width: 12),
                    Expanded(child: _buildInputField('Sugar (g)', '0', sugarController, isNumber: true)),
                  ],
                ),
                SizedBox(height: 16),
                _buildInputField('Sodium (mg)', '0', sodiumController, isNumber: true),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isEmpty) {
                        AppDialogs.showErrorSnackbar(
                          title: "Error",
                          message: "Please enter ingredient name",
                        );
                        return;
                      }

                      final ingredient = {
                        'name': nameController.text,
                        'calories': int.tryParse(caloriesController.text) ?? 0,
                        'protein': int.tryParse(proteinController.text) ?? 0,
                        'carbs': int.tryParse(carbsController.text) ?? 0,
                        'fat': int.tryParse(fatController.text) ?? 0,
                        'fiber': int.tryParse(fiberController.text) ?? 0,
                        'sugar': int.tryParse(sugarController.text) ?? 0,
                        'sodium': int.tryParse(sodiumController.text) ?? 0,
                      };

                      setState(() {
                        _ingredients.add(ingredient);
                      });

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Ingredient',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.cardColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.tileColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
            style: TextStyle(fontSize: 15, color: context.textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.textColor.withOpacity(0.4), fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}