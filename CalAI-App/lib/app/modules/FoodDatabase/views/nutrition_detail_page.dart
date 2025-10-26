import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:calai/app/constants/colors.dart';
import 'package:calai/app/components/dialogs.dart';
import 'package:calai/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:calai/app/models/AI/nutrition_record.dart';
import 'package:calai/app/models/AI/nutrition_output.dart';
import 'package:calai/app/constants/enums.dart';
import 'package:calai/app/repo/nutrition_record_repo.dart';
import 'package:calai/app/controllers/auth_controller.dart';
import 'package:calai/app/repo/saved_foods_repo.dart';
import 'package:calai/app/repo/custom_foods_repo.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionDetailPage extends StatefulWidget {
  final Map<String, dynamic> food;
  final NutritionRecord? existingRecord;

  const NutritionDetailPage({
    Key? key,
    required this.food,
    this.existingRecord,
  }) : super(key: key);

  @override
  State<NutritionDetailPage> createState() => _NutritionDetailPageState();
}

class _NutritionDetailPageState extends State<NutritionDetailPage> {
  String _selectedMeasurement = 'Tbsp';
  int _servingAmount = 1;
  bool _isSaved = false;
  bool _isLogging = false;
  
  // For tracking edited macro values
  Map<String, int> _editedValues = {};
  bool _hasEdits = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    
  }

  Future<void> _checkIfSaved() async {
    try {
      final authController = Get.find<AuthController>();
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

  int get calculatedCalories {
    if (_hasEdits && _editedValues.containsKey('calories')) {
      return _editedValues['calories']!;
    }
    return ((widget.food['calories'] as num) * _servingAmount).toInt();
  }
  
  int get calculatedProtein {
    if (_hasEdits && _editedValues.containsKey('protein')) {
      return _editedValues['protein']!;
    }
    return ((widget.food['protein'] as num) * _servingAmount).toInt();
  }
  
  int get calculatedCarbs {
    if (_hasEdits && _editedValues.containsKey('carbs')) {
      return _editedValues['carbs']!;
    }
    return ((widget.food['carbs'] as num) * _servingAmount).toInt();
  }
  
  int get calculatedFat {
    if (_hasEdits && _editedValues.containsKey('fat')) {
      return _editedValues['fat']!;
    }
    return ((widget.food['fat'] as num) * _servingAmount).toInt();
  }
  
  int get calculatedFiber {
    if (_hasEdits && _editedValues.containsKey('fiber')) {
      return _editedValues['fiber']!;
    }
    return ((widget.food['fiber'] as num) * _servingAmount).toInt();
  }
  
  int get calculatedSugar {
    if (_hasEdits && _editedValues.containsKey('sugar')) {
      return _editedValues['sugar']!;
    }
    return ((widget.food['sugar'] as num) * _servingAmount).toInt();
  }
  
  int get calculatedSodium {
    if (_hasEdits && _editedValues.containsKey('sodium')) {
      return _editedValues['sodium']!;
    }
    return ((widget.food['sodium'] as num) * _servingAmount).toInt();
  }

  Future<void> _showEditMacroDialog(String macroName, int currentValue, {bool isMg = false}) async {
    final TextEditingController controller = TextEditingController(
      text: currentValue.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit $macroName',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.textColor),
            decoration: InputDecoration(
              labelText: '$macroName (${isMg ? "mg" : "g"})',
              labelStyle: TextStyle(color: context.textColor.withOpacity(0.7)),
              hintText: 'Enter value',
              hintStyle: TextStyle(color: context.textColor.withOpacity(0.4)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: context.tileColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.textColor.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value >= 0) {
                  Navigator.pop(dialogContext, value);
                } else {
                  AppDialogs.showErrorSnackbar(
                    title: "Invalid Input",
                    message: "Please enter a valid number",
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (result != null && mounted) {
      setState(() {
        _editedValues[macroName.toLowerCase()] = result;
        _hasEdits = true;
        
        // Recalculate calories if macros changed
        if (macroName != 'Calories' && macroName != 'Sodium' && macroName != 'Fiber' && macroName != 'Sugar') {
          int protein = _editedValues['protein'] ?? calculatedProtein;
          int carbs = _editedValues['carbs'] ?? calculatedCarbs;
          int fat = _editedValues['fat'] ?? calculatedFat;
          _editedValues['calories'] = (protein * 4) + (carbs * 4) + (fat * 9);
        }
      });
      
      AppDialogs.showSuccessSnackbar(
        title: "Updated",
        message: "$macroName updated to $result${isMg ? 'mg' : 'g'}",
      );
    }
  }

  Future<void> _toggleSave() async {
    try {
      final authController = Get.find<AuthController>();
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
      final isUpdating = widget.existingRecord != null;
      
      AppDialogs.showLoadingDialog(
        title: isUpdating ? "Updating Food" : "Adding Food",
        message: isUpdating 
            ? "Updating ${widget.food['name']}..."
            : "Adding ${widget.food['name']} to your meals...",
      );

      final authController = Get.find<AuthController>();
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

      if (isUpdating) {
        // Update existing record
        final existingRecord = widget.existingRecord!;
        final oldIngredient = existingRecord.nutritionOutput?.response?.ingredients?.first;
        
        // Remove old values from consumed totals
        if (oldIngredient != null) {
          scannerController.consumedCalories.value -= oldIngredient.calories ?? 0;
          scannerController.consumedProtein.value -= oldIngredient.protein ?? 0;
          scannerController.consumedCarb.value -= oldIngredient.carbs ?? 0;
          scannerController.consumedFat.value -= oldIngredient.fat ?? 0;
          scannerController.consumedFiber.value -= oldIngredient.fiber ?? 0;
          scannerController.consumedSugar.value -= oldIngredient.sugar ?? 0;
          scannerController.consumedSodium.value -= oldIngredient.sodium ?? 0;

          if (scannerController.existingNutritionRecords != null) {
            scannerController.existingNutritionRecords!.dailyConsumedCalories -= oldIngredient.calories ?? 0;
            scannerController.existingNutritionRecords!.dailyConsumedProtein -= oldIngredient.protein ?? 0;
            scannerController.existingNutritionRecords!.dailyConsumedCarb -= oldIngredient.carbs ?? 0;
            scannerController.existingNutritionRecords!.dailyConsumedFat -= oldIngredient.fat ?? 0;
            scannerController.existingNutritionRecords!.dailyConsumedFiber = 
                (scannerController.existingNutritionRecords!.dailyConsumedFiber ?? 0) - (oldIngredient.fiber ?? 0);
            scannerController.existingNutritionRecords!.dailyConsumedSugar = 
                (scannerController.existingNutritionRecords!.dailyConsumedSugar ?? 0) - (oldIngredient.sugar ?? 0);
            scannerController.existingNutritionRecords!.dailyConsumedSodium = 
                (scannerController.existingNutritionRecords!.dailyConsumedSodium ?? 0) - (oldIngredient.sodium ?? 0);
          }
        }

        // Update ingredient with new values
        final updatedIngredient = Ingredient(
          name: widget.food['name'],
          calories: calculatedCalories,
          protein: calculatedProtein,
          carbs: calculatedCarbs,
          fat: calculatedFat,
          fiber: calculatedFiber,
          sugar: calculatedSugar,
          sodium: calculatedSodium,
          healthScore: oldIngredient?.healthScore ?? 7,
          healthComments: oldIngredient?.healthComments ?? 'Added from food database',
        );

        // Update the nutrition response
        existingRecord.nutritionOutput?.response?.ingredients = [updatedIngredient];
        existingRecord.nutritionOutput?.response?.portion = '${widget.food['serving']} x$_servingAmount';
        existingRecord.nutritionOutput?.response?.portionSize = _servingAmount.toDouble();

        // Add new values to consumed totals
        scannerController.consumedCalories.value += calculatedCalories;
        scannerController.consumedProtein.value += calculatedProtein;
        scannerController.consumedCarb.value += calculatedCarbs;
        scannerController.consumedFat.value += calculatedFat;
        scannerController.consumedFiber.value += calculatedFiber;
        scannerController.consumedSugar.value += calculatedSugar;
        scannerController.consumedSodium.value += calculatedSodium;

        if (scannerController.existingNutritionRecords != null) {
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
            throw Exception("Failed to update in database");
          }
        }

        scannerController.update();
      } else {
        // Create new record
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
          entrySource: EntrySource.FOOD_DATABASE,
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
      }

      await Future.delayed(Duration(milliseconds: 300));
      AppDialogs.hideDialog();
      AppDialogs.showSuccessSnackbar(
        title: "Success",
        message: isUpdating 
            ? "${widget.food['name']} updated successfully!"
            : "${widget.food['name']} added to your meals!",
      );
      await Future.delayed(Duration(milliseconds: 500));

      Get.until((route) => route.isFirst);
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to ${widget.existingRecord != null ? 'update' : 'add'} food: $e",
      );
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            ListTile(
              leading: Icon(Icons.report_outlined, color: Colors.orange),
              title: Text(
                'Report Food',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportFood();
              },
            ),
            Divider(height: 1, color: context.borderColor),
            
            ListTile(
              leading: Icon(Icons.image_outlined, color: Colors.blue),
              title: Text(
                'Save Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveImage();
              },
            ),
            Divider(height: 1, color: context.borderColor),
            
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Delete Food',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteFood();
              },
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _reportFood() {
    final TextEditingController reportController = TextEditingController();
    String selectedReason = 'Incorrect nutrition information';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: context.cardColor,
          title: Text(
            'Report Food',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s wrong with this food?',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 16),
                
                ...['Incorrect nutrition information', 'Duplicate entry', 'Inappropriate content', 'Other']
                    .map((reason) => RadioListTile<String>(
                          title: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textColor,
                            ),
                          ),
                          value: reason,
                          groupValue: selectedReason,
                          activeColor: Theme.of(context).colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value!;
                            });
                          },
                        ))
                    .toList(),
                
                SizedBox(height: 16),
                Text(
                  'Additional details (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: reportController,
                  maxLines: 3,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    hintText: 'Provide more details...',
                    hintStyle: TextStyle(color: context.textColor.withOpacity(0.4)),
                    filled: true,
                    fillColor: context.tileColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.textColor.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () {
                final details = reportController.text.trim();
                if (details.isEmpty) {
                  AppDialogs.showErrorSnackbar(
                    title: "Details Required",
                    message: "Please provide details about the issue.",
                  );
                  return;
                }
                Navigator.pop(context);
                _submitReport(selectedReason, details);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Report',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String reason, String details) async {
    try {
      // Get current user
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        AppDialogs.showErrorSnackbar(
          title: "Authentication Required",
          message: "Please sign in to report foods.",
        );
        return;
      }
      
      final userId = authController.userId!;
      final userEmail = authController.userModel?.email ?? 'unknown';
      
      // Submit to Firestore
      await FirebaseFirestore.instance.collection('food_reports').add({
        'foodName': widget.food['name'],
        'foodId': widget.food['id'] ?? widget.food['name'],
        'reason': reason,
        'details': details,
        'reportedBy': userId,
        'reportedByEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      });
      
      if (mounted) {
        AppDialogs.showSuccessSnackbar(
          title: "Report Submitted",
          message: "Thank you for your feedback. We'll review this shortly.",
        );
      }
    } catch (e) {
      print('Error submitting report: $e');
      if (mounted) {
        AppDialogs.showErrorSnackbar(
          title: "Submission Failed",
          message: "Could not submit report. Please try again.",
        );
      }
    }
  }

  Future<void> _saveImage() async {
    if (widget.food['imageUrl'] == null || widget.food['imageUrl'] == '') {
      AppDialogs.showErrorSnackbar(
        title: "No Image",
        message: "This food item doesn't have an image to save.",
      );
      return;
    }
    
    try {
      // Request permission
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          AppDialogs.showErrorSnackbar(
            title: "Permission Denied",
            message: "Please grant photo library access to save images.",
          );
          return;
        }
      }
      
      AppDialogs.showLoadingDialog(
        title: "Saving Image",
        message: "Downloading and saving to gallery...",
      );
      
      // Download image
      final imageUrl = widget.food['imageUrl'];
      final tempDir = await getTemporaryDirectory();
      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${tempDir.path}/$fileName';
      
      await Dio().download(imageUrl, filePath);
      
      // Save to gallery
      await Gal.putImage(filePath);
      
      // Clean up temp file
      await File(filePath).delete();
      
      AppDialogs.hideDialog();
      
      if (mounted) {
        AppDialogs.showSuccessSnackbar(
          title: "Image Saved",
          message: "Food image saved to your gallery!",
        );
      }
    } catch (e) {
      print('Error saving image: $e');
      AppDialogs.hideDialog();
      if (mounted) {
        AppDialogs.showErrorSnackbar(
          title: "Save Failed",
          message: "Could not save image. Please try again.",
        );
      }
    }
  }

  Future<void> _deleteFood() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'Delete Food?',
          style: TextStyle(color: context.textColor),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.food['name']}"? This action cannot be undone.',
          style: TextStyle(color: context.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      AppDialogs.showLoadingDialog(
        title: "Deleting",
        message: "Removing food from database...",
      );

      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        AppDialogs.hideDialog();
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "User not authenticated",
        );
        return;
      }

      final userId = authController.userId!;
      
      bool isCustomFood = widget.food['isCustom'] == true || 
                         widget.food['createdBy'] == userId;
      
      QueryStatus result;
      
      if (isCustomFood) {
        result = await CustomFoodsRepo().deleteCustomFood(
          userId, 
          widget.food['name']
        );
      } else {
        result = await SavedFoodsRepo().removeFoodFromFavorites(
          userId,
          widget.food['name']
        );
      }

      AppDialogs.hideDialog();

      if (result == QueryStatus.SUCCESS) {
        AppDialogs.showSuccessSnackbar(
          title: "Deleted",
          message: "${widget.food['name']} has been deleted.",
        );
        Get.back(result: true);
      } else {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "Failed to delete food. Please try again.",
        );
      }
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to delete food: $e",
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
          onPressed: () => Navigator.pop(context, _isSaved),
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
            onPressed: _showOptionsMenu,
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
                        child: Hero(
                          tag: 'food-name-${widget.existingRecord?.recordTime?.toIso8601String() ?? widget.food['name']}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.food['name'],
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                      onTap: _toggleSave,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          key: ValueKey(_isSaved),
                          color: context.textColor,
                          size: 32,
                        ),
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
                      color: context.textColor,
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
                          color: context.textColor,
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
                                if (_servingAmount > 1) {
                                  setState(() {
                                    _servingAmount--;
                                    // Reset edits when serving changes
                                    _hasEdits = false;
                                    _editedValues.clear();
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
                              '$_servingAmount',
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
                                  _servingAmount++;
                                  // Reset edits when serving changes
                                  _hasEdits = false;
                                  _editedValues.clear();
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

                  // Calories Box
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showEditMacroDialog('Calories', calculatedCalories);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.tileColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.borderColor.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.textColor.withOpacity(0.04),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF6B35).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: Color(0xFFFF6B35),
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calories',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textColor.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '$calculatedCalories',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: context.textColor.withOpacity(0.3),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

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
                  Text(
                    'Other nutrition facts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  _buildNutritionFactRow('Saturated Fat', '1g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Polyunsaturated Fat', '2g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Monounsaturated Fat', '3g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Trans Fat', '0g'),
                  SizedBox(height: 12),
                  
                  _buildNutritionFactRow('Cholesterol', '${calculatedSodium > 0 ? "5mg" : "0mg"}'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Sodium', '${calculatedSodium}mg'),
                  SizedBox(height: 12),
                  
                  _buildNutritionFactRow('Total Carbohydrate', '${calculatedCarbs}g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Dietary Fiber', '${calculatedFiber}g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Total Sugars', '${calculatedSugar}g'),
                  SizedBox(height: 12),
                  _buildNutritionFactRow('Added Sugars', '${(calculatedSugar * 0.5).toInt()}g'),
                  SizedBox(height: 12),
                  
                  _buildNutritionFactRow('Protein', '${calculatedProtein}g'),
                  SizedBox(height: 12),
                  
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
                  onPressed: _isLogging ? null : _saveToLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.textColor,
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
                            color: context.cardColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.existingRecord != null ? 'Update' : 'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.cardColor,
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
          color: isSelected ? context.textColor : context.cardColor,
          border: Border.all(
            color: isSelected ? context.textColor : context.borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? context.cardColor : context.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBox(String label, int value, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showEditMacroDialog(label, value);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.tileColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.borderColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.03),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.textColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${value}g',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionFactRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: context.textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }
}