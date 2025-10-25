import 'package:CalAI/app/components/dialogs.dart';
import 'package:CalAI/app/constants/enums.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/repo/nutrition_record_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/AI/nutrition_output.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/utility/date_utility.dart';
import 'package:CalAI/app/repo/saved_foods_repo.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/components/social_media_share_widget.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class NutritionView extends StatefulWidget {
  final NutritionRecord nutritionRecord;
  final UserModel userModel;

  const NutritionView({
    super.key,
    required this.nutritionRecord,
    required this.userModel,
  });

  @override
  State<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends State<NutritionView> {
  int _quantity = 1;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isSaved = false;
  bool _thumbsUpPressed = false;
  bool _thumbsDownPressed = false;
  
  // For tracking edited macro values
  Map<String, int> _editedTotals = {};
  bool _hasEdits = false;

  NutritionRecord get nutritionRecord => widget.nutritionRecord;
  UserModel get userModel => widget.userModel;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) return;

      final userId = authController.userId!;
      final foodName = nutritionRecord.nutritionOutput?.response?.foodName;
      
      if (foodName == null) return;

      final repo = SavedFoodsRepo();
      final isSaved = await repo.isFoodSaved(userId, foodName);
      
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      print("Error checking if food is saved: $e");
    }
  }

  Future<void> _toggleSave() async {
    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) return;

      final userId = authController.userId!;
      final totals = _calculateCurrentTotals();
      final foodName = nutritionRecord.nutritionOutput?.response?.foodName ?? 'Unknown Food';
      
      final repo = SavedFoodsRepo();
      
      if (_isSaved) {
        await repo.removeFoodFromFavorites(userId, foodName);
        if (mounted) {
          setState(() {
            _isSaved = false;
          });
        }
        AppDialogs.showSuccessSnackbar(
          title: "Removed",
          message: "$foodName removed from saved foods",
        );
      } else {
        final foodData = {
          'name': foodName,
          'calories': totals['calories'],
          'protein': totals['protein'],
          'carbs': totals['carbs'],
          'fat': totals['fat'],
          'fiber': totals['fiber'],
          'sugar': totals['sugar'],
          'sodium': totals['sodium'],
          'serving': nutritionRecord.nutritionOutput?.response?.portion ?? '1 serving',
        };
        
        await repo.saveFoodToFavorites(userId, foodData);
        if (mounted) {
          setState(() {
            _isSaved = true;
          });
        }
        AppDialogs.showSuccessSnackbar(
          title: "Saved",
          message: "$foodName saved to your favorites",
        );
      }
    } catch (e) {
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to save food: $e",
      );
    }
  }

  Map<String, int> _calculateCurrentTotals() {
    // If we have edits, return those
    if (_hasEdits && _editedTotals.isNotEmpty) {
      return Map.from(_editedTotals);
    }
    
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;
    int totalFiber = 0;
    int totalSugar = 0;
    int totalSodium = 0;

    if (nutritionRecord.nutritionOutput?.response?.ingredients != null) {
      for (Ingredient item in nutritionRecord.nutritionOutput!.response!.ingredients!) {
        totalCalories += (item.calories ?? 0);
        totalProtein += (item.protein ?? 0);
        totalCarbs += (item.carbs ?? 0);
        totalFat += (item.fat ?? 0);
        totalFiber += (item.fiber ?? 0);
        totalSugar += (item.sugar ?? 0);
        totalSodium += (item.sodium ?? 0);
      }
    }

    return {
      'calories': (totalCalories * _quantity),
      'protein': (totalProtein * _quantity),
      'carbs': (totalCarbs * _quantity),
      'fat': (totalFat * _quantity),
      'fiber': (totalFiber * _quantity),
      'sugar': (totalSugar * _quantity),
      'sodium': (totalSodium * _quantity),
    };
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
        // Initialize _editedTotals if empty
        if (_editedTotals.isEmpty) {
          _editedTotals = _calculateCurrentTotals();
        }
        
        _editedTotals[macroName.toLowerCase()] = result;
        _hasEdits = true;
        
        // Recalculate calories if macros changed (not for fiber, sugar, sodium)
        if (macroName != 'Calories' && macroName != 'Sodium' && macroName != 'Fiber' && macroName != 'Sugar') {
          int protein = _editedTotals['protein'] ?? 0;
          int carbs = _editedTotals['carbs'] ?? 0;
          int fat = _editedTotals['fat'] ?? 0;
          _editedTotals['calories'] = (protein * 4) + (carbs * 4) + (fat * 9);
        }
      });
      
      AppDialogs.showSuccessSnackbar(
        title: "Updated",
        message: "$macroName updated to $result${isMg ? 'mg' : 'g'}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (nutritionRecord.nutritionOutput?.response == null) {
      return Scaffold(
        backgroundColor: context.surfaceColor,
        appBar: AppBar(
          backgroundColor: context.cardColor,
          title: Text('Nutrition Details', style: TextStyle(color: context.textColor)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'No nutrition data available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _isSaved),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.textColor,
                  foregroundColor: context.cardColor,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    NutritionResponse response = nutritionRecord.nutritionOutput!.response!;
    final totals = _calculateCurrentTotals();
    final foodName = response.foodName ?? 'Unknown Food';
    final timeStamp = DateUtility.getTimeFromDateTime(nutritionRecord.recordTime!.toLocal());

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Stack(
        children: [
          _buildHeaderImage(),
          
          Column(
            children: [
              _buildCustomAppBar(context),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 180),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFoodHeader(foodName, timeStamp),
                            SizedBox(height: 24),
                            _buildCaloriesBox(totals['calories']!),
                            SizedBox(height: 16),
                            _buildMacrosCarousel(totals),
                            SizedBox(height: 8),
                            _buildCarouselIndicators(),
                            SizedBox(height: 32),
                            _buildIngredientsSection(response),
                            SizedBox(height: 24),
                            _buildFeedbackSection(),
                            SizedBox(height: 24),
                            _buildBottomButtons(),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    final query = nutritionRecord.nutritionInputQuery;
    final hasImage = (query?.imageFilePath != null && query!.imageFilePath!.isNotEmpty) ||
                     (query?.imageUrl != null && query!.imageUrl!.isNotEmpty);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode ? Colors.black87 : Colors.black54,
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (query!.imageFilePath != null)
                    Image.file(
                      File(query.imageFilePath!),
                      fit: BoxFit.cover,
                    )
                  else if (query.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: query.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  Icons.restaurant,
                  size: 100,
                  color: Colors.white54,
                ),
              ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context, _isSaved),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            Text(
              'Nutrition',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(() => SocialMediaShareWidget(
                      nutritionRecord: nutritionRecord,
                      userName: userModel.name,
                    ));
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _showOptionsMenu(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 22,
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

  Widget _buildFoodHeader(String foodName, String time) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _toggleSave,
                child: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  size: 28,
                  color: context.textColor,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  foodName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              
              SizedBox(width: 16),
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.textColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_quantity > 1) {
                          setState(() {
                            _quantity--;
                            // Reset edits when quantity changes
                            _hasEdits = false;
                            _editedTotals.clear();
                          });
                        }
                      },
                      child: Icon(Icons.remove, size: 20, color: context.textColor),
                    ),
                    SizedBox(width: 20),
                    Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _quantity++;
                          // Reset edits when quantity changes
                          _hasEdits = false;
                          _editedTotals.clear();
                        });
                      },
                      child: Icon(Icons.add, size: 20, color: context.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesBox(int calories) {
    final isEdited = _hasEdits && _editedTotals.containsKey('calories');
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showEditMacroDialog('Calories', calories);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: isEdited
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.tileColor,
                      Color(0xFFFF6B35).withOpacity(0.1),
                    ],
                  )
                : LinearGradient(
                    colors: [context.tileColor, context.tileColor],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: isEdited
                ? Border.all(
                    color: Color(0xFFFF6B35).withOpacity(0.4),
                    width: 2,
                  )
                : Border.all(
                    color: context.borderColor.withOpacity(0.1),
                    width: 1,
                  ),
            boxShadow: isEdited
                ? [
                    BoxShadow(
                      color: Color(0xFFFF6B35).withOpacity(0.15),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: context.textColor.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department,
                  size: 40,
                  color: Color(0xFFFF6B35),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '$calories',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Calories',
                    style: TextStyle(
                      fontSize: 15,
                      color: context.textColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isEdited) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B35).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Edited',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Tap to adjust',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textColor.withOpacity(0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacrosCarousel(Map<String, int> totals) {
    return Container(
      height: 140,
      child: PageView(
        controller: _pageController,
        children: [
          _buildMacrosPage1(totals),
          _buildMacrosPage2(totals),
        ],
      ),
    );
  }

  Widget _buildMacrosPage1(Map<String, int> totals) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildMacroBox(
              Icons.fitness_center,
              'Protein',
              '${totals['protein']}g',
              Color(0xFFE57373),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildMacroBox(
              Icons.grain,
              'Carbs',
              '${totals['carbs']}g',
              Color(0xFFFFB74D),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildMacroBox(
              Icons.water_drop,
              'Fats',
              '${totals['fat']}g',
              Color(0xFF64B5F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosPage2(Map<String, int> totals) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildMacroBox(
              Icons.spa,
              'Fiber',
              '${totals['fiber']}g',
              Color(0xFF81C784),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildMacroBox(
              Icons.cookie,
              'Sugar',
              '${totals['sugar']}g',
              Color(0xFFBA68C8),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildMacroBox(
              Icons.science,
              'Sodium',
              '${totals['sodium']}mg',
              Color(0xFF4DB6AC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBox(IconData icon, String label, String value, Color color) {
    final isEdited = _hasEdits && _editedTotals.containsKey(label.toLowerCase());
    
    return GestureDetector(
      onTap: () {
        // Extract numeric value from string (e.g., "50g" -> 50)
        final numericValue = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final isMg = value.contains('mg');
        
        // Haptic feedback
        HapticFeedback.lightImpact();
        
        _showEditMacroDialog(label, numericValue, isMg: isMg);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.tileColor,
          borderRadius: BorderRadius.circular(16),
          border: isEdited
              ? Border.all(
                  color: color.withOpacity(0.6),
                  width: 2,
                )
              : Border.all(
                  color: context.borderColor.withOpacity(0.1),
                  width: 1,
                ),
          boxShadow: isEdited
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: context.textColor.withOpacity(0.03),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            SizedBox(height: 10),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.textColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isEdited) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Edited',
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index 
                ? context.textColor 
                : context.textColor.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildIngredientsSection(NutritionResponse response) {
    final ingredients = response.ingredients ?? [];
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                onTap: () {
                  // TODO: Add ingredient
                },
                child: Text(
                  '+ Add',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.textColor.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          if (ingredients.isNotEmpty) ...[
            SizedBox(height: 16),
            ...ingredients.map((ingredient) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.tileColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.name ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.textColor,
                        ),
                      ),
                    ),
                    Text(
                      '${ingredient.calories ?? 0} cal',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.tileColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 24, color: context.textColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'How did Cal AI do?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _thumbsDownPressed = !_thumbsDownPressed;
                  if (_thumbsDownPressed) _thumbsUpPressed = false;
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _thumbsDownPressed ? Colors.red.shade100 : context.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _thumbsDownPressed ? Colors.red : context.borderColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.thumb_down_outlined,
                  size: 20,
                  color: _thumbsDownPressed ? Colors.red : context.textColor,
                ),
              ),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _thumbsUpPressed = !_thumbsUpPressed;
                  if (_thumbsUpPressed) _thumbsDownPressed = false;
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _thumbsUpPressed ? Colors.green.shade100 : context.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _thumbsUpPressed ? Colors.green : context.borderColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.thumb_up_outlined,
                  size: 20,
                  color: _thumbsUpPressed ? Colors.green : context.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Implement fix functionality
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.textColor, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high, size: 20, color: context.textColor),
                    SizedBox(width: 8),
                    Text(
                      'Fix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context, _isSaved);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.textColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
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

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.flag_outlined, color: Colors.orange),
              title: Text(
                'Report Food',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                _handleReportFood(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.download_outlined, color: Colors.blue),
              title: Text(
                'Save Image',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                _handleSaveImage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Food',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                _handleDeleteMeal(context);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReportFood(BuildContext context) async {
    final TextEditingController reportController = TextEditingController();
    String? selectedReason;
    
    final reasons = [
      'Incorrect nutrition information',
      'Wrong food name',
      'Inappropriate content',
      'Missing information',
      'Other',
    ];

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.cardColor,
              title: Text(
                'Report Food',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food: ${nutritionRecord.nutritionOutput?.response?.foodName ?? "Unknown"}',
                      style: TextStyle(
                        color: context.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Reason:',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...reasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(
                          reason,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 14,
                          ),
                        ),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: MealAIColors.darkPrimary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                      );
                    }).toList(),
                    SizedBox(height: 15),
                    TextField(
                      controller: reportController,
                      maxLines: 3,
                      style: TextStyle(color: context.textColor),
                      decoration: InputDecoration(
                        hintText: 'Additional details (optional)',
                        hintStyle: TextStyle(
                          color: context.textColor.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: context.tileColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: MealAIColors.darkPrimary,
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: context.textColor),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedReason == null) {
                      AppDialogs.showErrorSnackbar(
                        title: "Error",
                        message: "Please select a reason",
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    
                    AppDialogs.showLoadingDialog(
                      title: "Submitting Report",
                      message: "Please wait...",
                    );

                    // TODO: Implement actual reporting logic here
                    // You can send this to Firebase or your backend
                    final reportData = {
                      'userId': userModel.userId,
                      'foodName': nutritionRecord.nutritionOutput?.response?.foodName,
                      'reason': selectedReason,
                      'details': reportController.text,
                      'timestamp': DateTime.now().toIso8601String(),
                      'recordTime': nutritionRecord.recordTime?.toIso8601String(),
                    };
                    
                    print("Report data: $reportData");
                    
                    // Simulate network delay
                    await Future.delayed(Duration(seconds: 1));
                    
                    AppDialogs.hideDialog();
                    AppDialogs.showSuccessSnackbar(
                      title: "Report Submitted",
                      message: "Thank you for your feedback. We'll review this report.",
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    reportController.dispose();
  }

  Future<void> _handleSaveImage(BuildContext context) async {
    try {
      final query = nutritionRecord.nutritionInputQuery;
      
      if (query == null) {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "No image available to save",
        );
        return;
      }

      final hasImage = (query.imageFilePath != null && query.imageFilePath!.isNotEmpty) ||
                      (query.imageUrl != null && query.imageUrl!.isNotEmpty);

      if (!hasImage) {
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "No image available to save",
        );
        return;
      }

      AppDialogs.showLoadingDialog(
        title: "Saving Image",
        message: "Please wait...",
      );

      // Request storage permission
      if (!await Gal.hasAccess()) {
        final hasAccess = await Gal.requestAccess();
        if (!hasAccess) {
          AppDialogs.hideDialog();
          AppDialogs.showErrorSnackbar(
            title: "Permission Denied",
            message: "Please grant storage permission to save images",
          );
          return;
        }
      }

      try {
        if (query.imageFilePath != null && query.imageFilePath!.isNotEmpty) {
          // Save local file
          final file = File(query.imageFilePath!);
          if (await file.exists()) {
            await Gal.putImage(query.imageFilePath!);
          }
        } else if (query.imageUrl != null && query.imageUrl!.isNotEmpty) {
          // Download and save network image
          final tempDir = await getTemporaryDirectory();
          final tempFilePath = '${tempDir.path}/CalAI_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          await Dio().download(
            query.imageUrl!,
            tempFilePath,
          );
          
          await Gal.putImage(tempFilePath);
          
          // Clean up temp file
          await File(tempFilePath).delete();
        }

        AppDialogs.hideDialog();
        AppDialogs.showSuccessSnackbar(
          title: "Success",
          message: "Image saved to gallery successfully!",
        );
      } catch (e) {
        AppDialogs.hideDialog();
        AppDialogs.showErrorSnackbar(
          title: "Error",
          message: "Failed to save image: ${e.toString()}",
        );
        print("Error saving image: $e");
      }
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to save image: ${e.toString()}",
      );
      print("Error in _handleSaveImage: $e");
    }
  }

  Future<void> _handleDeleteMeal(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          title: Text(
            'Delete Meal Entry',
            style: TextStyle(color: context.textColor),
          ),
          content: Text(
            'Are you sure you want to delete this meal entry? This action cannot be undone.',
            style: TextStyle(color: context.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.textColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                AppDialogs.showLoadingDialog(
                  title: "Deleting Meal",
                  message: "Removing meal from records...",
                );

                String userId = userModel.userId;
                final nutritionRecordRepo = NutritionRecordRepo();
                final recordTime = nutritionRecord.recordTime ?? DateTime.now();

                QueryStatus result = await nutritionRecordRepo.deleteMealEntryByTime(
                  userId,
                  recordTime,
                  recordTime,
                );

                if (result == QueryStatus.SUCCESS) {
                  AppDialogs.hideDialog();
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                  AppDialogs.showSuccessSnackbar(
                    title: "Success",
                    message: "Meal deleted successfully!",
                  );
                  
                  ScannerController scannerController = Get.put(ScannerController());
                  await scannerController.getRecordByDate(userId, recordTime);
                } else {
                  AppDialogs.hideDialog();
                  AppDialogs.showErrorSnackbar(
                    title: "Error",
                    message: "Failed to delete meal. Please try again.",
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}