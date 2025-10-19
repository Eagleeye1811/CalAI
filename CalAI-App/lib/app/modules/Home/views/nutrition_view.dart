import 'package:CalAI/app/components/dialogs.dart';
import 'package:CalAI/app/constants/enums.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/repo/nutrition_record_repo.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/AI/nutrition_output.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/utility/date_utility.dart';
import 'package:CalAI/app/repo/saved_foods_repo.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
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

  // Check if food is already saved
  Future<void> _checkIfSaved() async {
    try {
      final authController = Get.find<AuthController>();  // ✅ CHANGED
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

  // Toggle save status
  Future<void> _toggleSave() async {
    try {
      final authController = Get.find<AuthController>();  // ✅ CHANGED
      if (!authController.isAuthenticated) return;

      final userId = authController.userId!;
      final totals = _calculateCurrentTotals();
      final foodName = nutritionRecord.nutritionOutput?.response?.foodName ?? 'Unknown Food';
      
      final repo = SavedFoodsRepo();
      
      if (_isSaved) {
        // Unsave
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
        // Save
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

  @override
  Widget build(BuildContext context) {
    if (nutritionRecord.nutritionOutput?.response == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nutrition Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'No nutrition data available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _isSaved),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image with dark overlay
          _buildHeaderImage(),
          
          // Main content
          Column(
            children: [
              // Custom AppBar
              _buildCustomAppBar(context),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 180), // Space for image header
                      
                      // White card with rounded top corners
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header section with bookmark, time, name, quantity
                            _buildFoodHeader(foodName, timeStamp),
                            
                            SizedBox(height: 24),
                            
                            // Calories box
                            _buildCaloriesBox(totals['calories']!),
                            
                            SizedBox(height: 16),
                            
                            // Macros carousel
                            _buildMacrosCarousel(totals),
                            
                            SizedBox(height: 8),
                            
                            // Carousel indicators
                            _buildCarouselIndicators(),
                            
                            SizedBox(height: 32),
                            
                            // Ingredients section
                            _buildIngredientsSection(response),
                            
                            SizedBox(height: 24),
                            
                            // Feedback section
                            _buildFeedbackSection(),
                            
                            SizedBox(height: 24),
                            
                            // Bottom buttons
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
          color: Colors.black87,
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
                  // Dark overlay
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
            // Back button
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
            
            // Title
            Text(
              'Nutrition',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Action buttons
            Row(
              children: [
                // Share button
                GestureDetector(
                  onTap: () {
                    // TODO: Implement share
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
                // Menu button
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
          // Bookmark icon and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _toggleSave,
                child: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  size: 28,
                  color: Colors.black,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Food name and quantity selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food name
              Expanded(
                child: Text(
                  foodName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              
              SizedBox(width: 16),
              
              // Quantity selector
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black, width: 1.5),
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
                      child: Icon(Icons.remove, size: 20, color: Colors.black),
                    ),
                    SizedBox(width: 20),
                    Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                      child: Icon(Icons.add, size: 20, color: Colors.black),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 48,
              color: Colors.black,
            ),
            SizedBox(height: 12),
            Text(
              '$calories',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Calories',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          // Page 1: Protein, Carbs, Fats
          _buildMacrosPage1(totals),
          // Page 2: Fiber, Sugar, Sodium
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
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
            color: _currentPage == index ? Colors.black : Colors.grey[300],
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
                  color: Colors.black,
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
                    color: Colors.grey[600],
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
                  color: Color(0xFFF5F5F5),
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
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '${ingredient.calories ?? 0} cal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 24, color: Colors.black),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'How did Cal AI do?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
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
                  color: _thumbsDownPressed ? Colors.red.shade100 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _thumbsDownPressed ? Colors.red : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.thumb_down_outlined,
                  size: 20,
                  color: _thumbsDownPressed ? Colors.red : Colors.black,
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
                  color: _thumbsUpPressed ? Colors.green.shade100 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _thumbsUpPressed ? Colors.green : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.thumb_up_outlined,
                  size: 20,
                  color: _thumbsUpPressed ? Colors.green : Colors.black,
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
          // Fix button
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Implement fix functionality
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Fix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // Done button
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context, _isSaved);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
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

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.black),
              title: Text('Edit', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleDeleteMeal(context);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteMeal(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Meal Entry'),
          content: const Text(
            'Are you sure you want to delete this meal entry? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
                  Navigator.of(context).pop();
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