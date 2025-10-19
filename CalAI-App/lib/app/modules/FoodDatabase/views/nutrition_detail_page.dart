import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/components/dialogs.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/models/AI/nutrition_output.dart';
import 'package:CalAI/app/constants/enums.dart';
import 'package:CalAI/app/repo/nutrition_record_repo.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/repo/saved_foods_repo.dart';

class NutritionDetailPage extends StatefulWidget {
  final Map<String, dynamic> food;

  const NutritionDetailPage({
    Key? key,
    required this.food,
  }) : super(key: key);

  @override
  State<NutritionDetailPage> createState() => _NutritionDetailPageState();
}

class _NutritionDetailPageState extends State<NutritionDetailPage> {
  String _selectedMeasurement = 'Tbsp';
  int _servingAmount = 1;
  bool _isSaved = false;
  bool _isLogging = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    try {
      final authController = Get.find<AuthController>();  // ✅ CHANGED
      if (!authController.isAuthenticated) return;

      final userId = authController.userId!;
      final repo = SavedFoodsRepo();
      final isSaved = await repo.isFoodSaved(userId, widget.food['name']);

      if (mounted) {
        setState(() {
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      print("Error checking if food is saved: $e");
    }
  }

  int get calculatedCalories => ((widget.food['calories'] as num) * _servingAmount).toInt();
  int get calculatedProtein => ((widget.food['protein'] as num) * _servingAmount).toInt();
  int get calculatedCarbs => ((widget.food['carbs'] as num) * _servingAmount).toInt();
  int get calculatedFat => ((widget.food['fat'] as num) * _servingAmount).toInt();
  int get calculatedFiber => ((widget.food['fiber'] as num) * _servingAmount).toInt();
  int get calculatedSugar => ((widget.food['sugar'] as num) * _servingAmount).toInt();
  int get calculatedSodium => ((widget.food['sodium'] as num) * _servingAmount).toInt();

  Future<void> _toggleSave() async {
    try {
      final authController = Get.find<AuthController>();  // ✅ CHANGED
      if (!authController.isAuthenticated) {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "Please login to save foods",
        );
        return;
      }

      final userId = authController.userId!;
      final repo = SavedFoodsRepo();

      if (_isSaved) {
        final result = await repo.removeFoodFromFavorites(userId, widget.food['name']);
        if (result == QueryStatus.SUCCESS) {
          setState(() {
            _isSaved = false;
          });
          AppDialogs.showSuccessSnackbar(
            title: "Unsaved",
            message: "${widget.food['name']} removed from favorites",
          );
        }
      } else {
        final result = await repo.saveFoodToFavorites(userId, widget.food);
        if (result == QueryStatus.SUCCESS) {
          setState(() {
            _isSaved = true;
          });
          AppDialogs.showSuccessSnackbar(
            title: "Saved",
            message: "${widget.food['name']} saved to your favorites!",
          );
        }
      }
    } catch (e) {
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to save food: $e",
      );
    }
  }

  Future<void> _saveToLog() async {
    setState(() {
      _isLogging = true;
    });

    try {
      AppDialogs.showLoadingDialog(
        title: "Adding Food",
        message: "Adding ${widget.food['name']} to your meals...",
      );

      final authController = Get.find<AuthController>();  // ✅ CHANGED
      if (!authController.isAuthenticated) {
        AppDialogs.hideDialog();
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "User not authenticated. Please login again.",
        );
        return;
      }

      final userId = authController.userId!;
      final scannerController = Get.find<ScannerController>();
    
      final ingredient = Ingredient(
        name: widget.food['name'],
        calories: calculatedCalories,
        protein: calculatedProtein,
        carbs: calculatedCarbs,
        fat: calculatedFat,
        fiber: calculatedFiber,
        sugar: calculatedSugar,
        sodium: calculatedSodium,
        healthScore: 7,
        healthComments: 'Added from food database',
      );

      final nutritionResponse = NutritionResponse(
        foodName: widget.food['name'],
        portion: '${widget.food['serving']} x$_servingAmount',
        portionSize: _servingAmount.toDouble(),
        confidenceScore: 100,
        ingredients: [ingredient],
        overallHealthScore: 7,
        overallHealthComments: 'Logged from food database',
      );

      final nutritionOutput = NutritionOutput(
        response: nutritionResponse,
        status: 1,
        message: 'Food added from database',
      );

      final nutritionRecord = NutritionRecord(
        nutritionOutput: nutritionOutput,
        recordTime: DateTime.now(),
        processingStatus: ProcessingStatus.COMPLETED,
      );

      scannerController.dailyRecords.insert(0, nutritionRecord);
      scannerController.consumedCalories.value += calculatedCalories;
      scannerController.consumedProtein.value += calculatedProtein;
      scannerController.consumedCarb.value += calculatedCarbs;
      scannerController.consumedFat.value += calculatedFat;
      scannerController.consumedFiber.value += calculatedFiber;
      scannerController.consumedSugar.value += calculatedSugar;
      scannerController.consumedSodium.value += calculatedSodium;

      if (scannerController.existingNutritionRecords != null) {
        scannerController.existingNutritionRecords!.dailyRecords.insert(0, nutritionRecord);
        scannerController.existingNutritionRecords!.dailyConsumedCalories += calculatedCalories;
        scannerController.existingNutritionRecords!.dailyConsumedProtein += calculatedProtein;
        scannerController.existingNutritionRecords!.dailyConsumedCarb += calculatedCarbs;
        scannerController.existingNutritionRecords!.dailyConsumedFat += calculatedFat;
        scannerController.existingNutritionRecords!.dailyConsumedFiber = 
            (scannerController.existingNutritionRecords!.dailyConsumedFiber ?? 0) + calculatedFiber;
        scannerController.existingNutritionRecords!.dailyConsumedSugar = 
            (scannerController.existingNutritionRecords!.dailyConsumedSugar ?? 0) + calculatedSugar;
        scannerController.existingNutritionRecords!.dailyConsumedSodium = 
            (scannerController.existingNutritionRecords!.dailyConsumedSodium ?? 0) + calculatedSodium;

        final repo = NutritionRecordRepo();
        final result = await repo.saveNutritionData(
          scannerController.existingNutritionRecords!,
          userId,
        );

        if (result != QueryStatus.SUCCESS) {
          throw Exception("Failed to save to database");
        }
      }

      scannerController.update();
      await Future.delayed(Duration(milliseconds: 300));
      AppDialogs.hideDialog();
      AppDialogs.showSuccessSnackbar(
        title: "Success",
        message: "${widget.food['name']} added to your meals!",
      );
      await Future.delayed(Duration(milliseconds: 500));
      Get.back();
      Get.back();
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to add food: $e",
      );
    } finally {
      setState(() {
        _isLogging = false;
      });
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
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context, _isSaved),
        ),
        title: Text(
          'Nutrition',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black, size: 24),
            onPressed: () {
              // Menu action
            },
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
                  // Food name with bookmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.food['name'],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleSave,
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),

                  // Serving Size Measurement
                  Text(
                    'Serving Size Measurement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMeasurementButton('Tbsp'),
                      SizedBox(width: 12),
                      _buildMeasurementButton('G'),
                      SizedBox(width: 12),
                      _buildMeasurementButton('Serving'),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Serving Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Serving Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_servingAmount > 1) {
                                  setState(() {
                                    _servingAmount--;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.remove, size: 24, color: Colors.black),
                              ),
                            ),
                            SizedBox(width: 24),
                            Text(
                              '$_servingAmount',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _servingAmount++;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.add, size: 24, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Calories Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.black, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calories',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$calculatedCalories',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined, color: Colors.grey[600], size: 20),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Macros Row
                  Row(
                    children: [
                      Expanded(child: _buildMacroBox('Protein', calculatedProtein, Icons.restaurant_menu, Colors.red)),
                      SizedBox(width: 12),
                      Expanded(child: _buildMacroBox('Carbs', calculatedCarbs, Icons.grain, Colors.orange)),
                      SizedBox(width: 12),
                      Expanded(child: _buildMacroBox('Fats', calculatedFat, Icons.water_drop, Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 32),

                  // Other nutrition facts
                                    // Other nutrition facts
                  Text(
                    'Other nutrition facts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Fats section
                  _buildNutritionFactRow('Saturated Fat', '1g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Polyunsaturated Fat', '2g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Monounsaturated Fat', '3g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Trans Fat', '0g'),
                  SizedBox(height: 12),
                  
                  // Cholesterol & Sodium
                  _buildNutritionFactRow('Cholesterol', '${calculatedSodium > 0 ? "5mg" : "0mg"}'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Sodium', '${calculatedSodium}mg'),
                  SizedBox(height: 12),
                  
                  // Carbohydrates section
                  _buildNutritionFactRow('Total Carbohydrate', '${calculatedCarbs}g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Dietary Fiber', '${calculatedFiber}g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Total Sugars', '${calculatedSugar}g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Added Sugars', '${(calculatedSugar * 0.5).toInt()}g'),
                  SizedBox(height: 12),
                  
                  // Protein
                  _buildNutritionFactRow('Protein', '${calculatedProtein}g'),
                  SizedBox(height: 12),
                  
                  // Minerals
                  _buildNutritionFactRow('Potassium', '${(calculatedSodium * 0.8).toInt()}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Calcium', '${(calculatedProtein * 15).toInt()}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Iron', '${(calculatedProtein * 0.2).toStringAsFixed(1)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Magnesium', '${(calculatedProtein * 5).toInt()}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Zinc', '${(calculatedProtein * 0.15).toStringAsFixed(1)}mg'),
                  SizedBox(height: 12),
                  
                  // Vitamins
                  _buildNutritionFactRow('Vitamin A', '${(calculatedCalories * 2).toInt()}IU'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Vitamin C', '${(calculatedCarbs * 0.5).toStringAsFixed(1)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Vitamin D', '${(calculatedCalories * 0.02).toStringAsFixed(1)}mcg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Vitamin E', '${(calculatedFat * 0.3).toStringAsFixed(1)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Vitamin K', '${(calculatedFat * 0.5).toStringAsFixed(1)}mcg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Thiamin (B1)', '${(calculatedCarbs * 0.02).toStringAsFixed(2)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Riboflavin (B2)', '${(calculatedProtein * 0.03).toStringAsFixed(2)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Niacin (B3)', '${(calculatedProtein * 0.5).toStringAsFixed(1)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Vitamin B6', '${(calculatedProtein * 0.04).toStringAsFixed(2)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Folate (B9)', '${(calculatedCarbs * 2).toInt()}mcg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Vitamin B12', '${(calculatedProtein * 0.1).toStringAsFixed(2)}mcg'),
                  SizedBox(height: 12),
                  
                  // Other minerals
                  _buildNutritionFactRow('Phosphorus', '${(calculatedProtein * 12).toInt()}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Selenium', '${(calculatedProtein * 0.5).toStringAsFixed(1)}mcg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Copper', '${(calculatedProtein * 0.02).toStringAsFixed(2)}mg'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Manganese', '${(calculatedCarbs * 0.05).toStringAsFixed(2)}mg'),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Save Button (fixed at bottom)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                  onPressed: _isLogging ? null : _saveToLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLogging
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildMeasurementButton(String label) {
    final isSelected = _selectedMeasurement == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMeasurement = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBox(String label, int value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
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
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${value}g',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.edit_outlined, color: Colors.grey[600], size: 14),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionFactRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}