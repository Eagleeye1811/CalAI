import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/components/dialogs.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/models/AI/nutrition_output.dart';
import 'package:CalAI/app/constants/enums.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/repo/nutrition_record_repo.dart';
import 'nutrition_detail_page.dart';
import 'package:CalAI/app/repo/saved_foods_repo.dart';
import 'create_meal_page.dart';
import 'package:CalAI/app/repo/custom_foods_repo.dart';
import 'create_food_page.dart';
import 'package:CalAI/app/repo/meals_repo.dart';
import 'manual_food_entry_page.dart';

class FoodDatabasePage extends StatefulWidget {
  final int initialTabIndex;
  
  const FoodDatabasePage({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<FoodDatabasePage> createState() => _FoodDatabasePageState();
}

class _FoodDatabasePageState extends State<FoodDatabasePage> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tabs = ['All', 'My meals', 'My foods', 'Saved scans'];
  
  List<Map<String, dynamic>> _savedFoods = [];
  bool _loadingSavedFoods = false;

  List<Map<String, dynamic>> _myMeals = [];
  bool _loadingMeals = false;

  List<Map<String, dynamic>> _customFoods = [];
  bool _loadingCustomFoods = false;
  
  // Sample food database - Replace with actual API call
  final List<Map<String, dynamic>> _allFoods = [
    {
      'name': 'Chicken Breast',
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fat': 3.6,
      'fiber': 0,
      'sugar': 0,
      'sodium': 74,
      'serving': '100g',
    },
    {
      'name': 'Brown Rice',
      'calories': 112,
      'protein': 2.6,
      'carbs': 24,
      'fat': 0.9,
      'fiber': 1.8,
      'sugar': 0.4,
      'sodium': 5,
      'serving': '1 cup cooked',
    },
    {
      'name': 'Broccoli',
      'calories': 55,
      'protein': 3.7,
      'carbs': 11,
      'fat': 0.6,
      'fiber': 2.4,
      'sugar': 2.2,
      'sodium': 64,
      'serving': '1 cup',
    },
    {
      'name': 'Salmon',
      'calories': 206,
      'protein': 22,
      'carbs': 0,
      'fat': 13,
      'fiber': 0,
      'sugar': 0,
      'sodium': 59,
      'serving': '100g',
    },
    {
      'name': 'Greek Yogurt',
      'calories': 59,
      'protein': 10,
      'carbs': 3.6,
      'fat': 0.4,
      'fiber': 0,
      'sugar': 3.2,
      'sodium': 36,
      'serving': '100g',
    },
    {
      'name': 'Banana',
      'calories': 89,
      'protein': 1.1,
      'carbs': 23,
      'fat': 0.3,
      'fiber': 2.6,
      'sugar': 12,
      'sodium': 1,
      'serving': '1 medium',
    },
    {
      'name': 'Almonds',
      'calories': 164,
      'protein': 6,
      'carbs': 6,
      'fat': 14,
      'fiber': 3.5,
      'sugar': 1.2,
      'sodium': 0,
      'serving': '1 oz (28g)',
    },
    {
      'name': 'Oatmeal',
      'calories': 71,
      'protein': 2.5,
      'carbs': 12,
      'fat': 1.5,
      'fiber': 1.7,
      'sugar': 0.4,
      'sodium': 49,
      'serving': '1/2 cup dry',
    },
    {
      'name': 'Avocado',
      'calories': 160,
      'protein': 2,
      'carbs': 8.5,
      'fat': 15,
      'fiber': 7,
      'sugar': 0.7,
      'sodium': 7,
      'serving': '1/2 avocado',
    },
    {
      'name': 'Sweet Potato',
      'calories': 86,
      'protein': 1.6,
      'carbs': 20,
      'fat': 0.1,
      'fiber': 3,
      'sugar': 4.2,
      'sodium': 55,
      'serving': '1 medium',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    
    // Load saved foods if starting on "Saved scans" tab
    if (_selectedTabIndex == 3) {
      _loadSavedFoods();
    }

    // Load meals if starting on "My meals" tab
    if (_selectedTabIndex == 1) {
      _loadMeals();
    }
    
    // Load custom foods if starting on "My foods" tab
    if (_selectedTabIndex == 2) {
      _loadCustomFoods();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedTabIndex == 3) {
      _loadSavedFoods();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
      // Use a post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedTabIndex == 3) {
          _loadSavedFoods();
        }
      });
  }
  

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFoods() async {
    setState(() {
      _loadingSavedFoods = true;
    });

    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        setState(() {
          _loadingSavedFoods = false;
        });
        return;
      }

      final userId = authController.userId!;
      final repo = SavedFoodsRepo();
      final foods = await repo.getSavedFoods(userId);

      setState(() {
        _savedFoods = foods;
        _loadingSavedFoods = false;
      });
    } catch (e) {
      print("Error loading saved foods: $e");
      setState(() {
        _loadingSavedFoods = false;
      });
    }
  }

  Future<void> _loadMeals() async {
    setState(() {
      _loadingMeals = true;
    });

    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        setState(() {
          _loadingMeals = false;
        });
        return;
      }

      final userId = authController.userId!;
      final repo = MealsRepo();
      final meals = await repo.getUserMeals(userId);

      setState(() {
        _myMeals = meals;
        _loadingMeals = false;
      });
    } catch (e) {
      print("Error loading meals: $e");
      setState(() {
        _loadingMeals = false;
      });
    }
  }

  Future<void> _loadCustomFoods() async {
    setState(() {
      _loadingCustomFoods = true;
    });

    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        setState(() {
          _loadingCustomFoods = false;
        });
        return;
      }

      final userId = authController.userId!;
      final repo = CustomFoodsRepo();
      final foods = await repo.getUserCustomFoods(userId);

      setState(() {
        _customFoods = foods;
        _loadingCustomFoods = false;
      });
    } catch (e) {
      print("Error loading custom foods: $e");
      setState(() {
        _loadingCustomFoods = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterFoods() {
    if (_searchController.text.isEmpty) {
      return _allFoods;
    } else {
      return _allFoods
          .where((food) => food['name']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }
  }

  List<Map<String, dynamic>> _filterSavedFoods() {
    if (_searchController.text.isEmpty) {
        return _savedFoods;
    } else {
        return _savedFoods
            .where((food) => food['name']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
    }
  }

  Future<void> _addFoodToLog(Map<String, dynamic> food) async {
    try {
      AppDialogs.showLoadingDialog(
        title: "Adding Food",
        message: "Adding ${food['name']} to your meals...",
      );

      // Get user ID from AuthController
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
    
      // Get scanner controller
      final scannerController = Get.find<ScannerController>();

      // Convert all numeric values to int properly
      final calories = (food['calories'] as num).toInt();
      final protein = (food['protein'] as num).toInt();
      final carbs = (food['carbs'] as num).toInt();
      final fat = (food['fat'] as num).toInt();
      final fiber = (food['fiber'] as num).toInt();
      final sugar = (food['sugar'] as num).toInt();
      final sodium = (food['sodium'] as num).toInt();

      // Create ingredient
      final ingredient = Ingredient(
        name: food['name'],
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
        healthScore: 7,
        healthComments: 'Added from food database',
      );

      // Create nutrition response
      final nutritionResponse = NutritionResponse(
        foodName: food['name'],
        portion: food['serving'],
        portionSize: 1.0,
        confidenceScore: 100,
        ingredients: [ingredient],
        overallHealthScore: 7,
        overallHealthComments: 'Logged from food database',
      );

      // Create nutrition output
      final nutritionOutput = NutritionOutput(
        response: nutritionResponse,
        status: 1,
        message: 'Food added from database',
      );

      // Create nutrition record
      final nutritionRecord = NutritionRecord(
        nutritionOutput: nutritionOutput,
        recordTime: DateTime.now(),
        processingStatus: ProcessingStatus.COMPLETED,
      );

      // Add to daily records
      scannerController.dailyRecords.insert(0, nutritionRecord);
      
      // Update consumed values
      scannerController.consumedCalories.value += calories;
      scannerController.consumedProtein.value += protein;
      scannerController.consumedCarb.value += carbs;
      scannerController.consumedFat.value += fat;
      scannerController.consumedFiber.value += fiber;
      scannerController.consumedSugar.value += sugar;
      scannerController.consumedSodium.value += sodium;
      
      // Update existing nutrition records
      if (scannerController.existingNutritionRecords != null) {
        scannerController.existingNutritionRecords!.dailyRecords.insert(0, nutritionRecord);
        scannerController.existingNutritionRecords!.dailyConsumedCalories += calories;
        scannerController.existingNutritionRecords!.dailyConsumedProtein += protein;
        scannerController.existingNutritionRecords!.dailyConsumedCarb += carbs;
        scannerController.existingNutritionRecords!.dailyConsumedFat += fat;
        
        // Handle nullable fields
        scannerController.existingNutritionRecords!.dailyConsumedFiber = 
            (scannerController.existingNutritionRecords!.dailyConsumedFiber ?? 0) + fiber;
        scannerController.existingNutritionRecords!.dailyConsumedSugar = 
            (scannerController.existingNutritionRecords!.dailyConsumedSugar ?? 0) + sugar;
        scannerController.existingNutritionRecords!.dailyConsumedSodium = 
            (scannerController.existingNutritionRecords!.dailyConsumedSodium ?? 0) + sodium;
        
        // Save to Firestore database
        final repo = NutritionRecordRepo();
        final result = await repo.saveNutritionData(
          scannerController.existingNutritionRecords!,
          userId,
        );
        
        if (result != QueryStatus.SUCCESS) {
          throw Exception("Failed to save to database");
        }
      }
      
      // Notify all GetBuilder listeners to update UI
      scannerController.update();
      
      await Future.delayed(Duration(milliseconds: 300));

      AppDialogs.hideDialog();

      AppDialogs.showSuccessSnackbar(
        title: "Success",
        message: "${food['name']} added to your meals!",
      );

      await Future.delayed(Duration(milliseconds: 500));
      Get.back();
      
    } catch (e) {
      AppDialogs.hideDialog();
      AppDialogs.showErrorSnackbar(
        title: "Error",
        message: "Failed to add food: $e",
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
          icon: Icon(Icons.arrow_back, color: context.textColor, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Log food',
          style: TextStyle(
            color: context.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          _buildTabs(),
          
          // Search box (show for "All" and "Saved scans" tabs)
          if (_selectedTabIndex == 0 || _selectedTabIndex == 3) ...[
            SizedBox(height: 16),
            _buildSearchBox(),
            // ADD THIS: Extra spacing after search box for Saved scans tab
            if (_selectedTabIndex == 3)
              SizedBox(height: 20),  // Increased gap for Saved scans
          ],
          
          // Content
          Expanded(
            child: Stack(
              children: [
                _buildTabContent(),
                // Bottom buttons for specific tabs
                if (_selectedTabIndex == 0)
                  _buildAllTabBottomButtons()
                else if (_selectedTabIndex == 1)
                  _buildMyMealsBottomButton()
                else if (_selectedTabIndex == 2)
                  _buildMyFoodsBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
              
              // Load appropriate data based on tab
              if (index == 1) {
                _loadMeals();
              } else if (index == 2) {
                _loadCustomFoods();
              } else if (index == 3) {
                _loadSavedFoods();
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: 24),
              padding: EdgeInsets.only(bottom: 12, top: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? context.textColor : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? context.textColor : context.textColor.withOpacity(0.5),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.textColor, width: 2),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Describe what you ate',
          hintStyle: TextStyle(
            color: context.textColor.withOpacity(0.5),
            fontSize: 15,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(fontSize: 15, color: context.textColor),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // All
        return _buildFoodList(_filterFoods());
      case 1: // My meals
        return _buildMyMealsTab();
      case 2: // My foods
        return _buildMyFoodsTab();
      case 3: // Saved scans
        if (_loadingSavedFoods) {
          return Center(
            child: CircularProgressIndicator(
              color: context.textColor,
            ),
          );
        }
        if (_savedFoods.isEmpty) {
          return _buildEmptyState(
            'No saved foods yet!\nSave foods from the nutrition page\nto see them here.',
          );
        }
        return RefreshIndicator(
          onRefresh: _loadSavedFoods,
          color: context.textColor,
          child: _buildFoodList(_filterSavedFoods()),
        );
      default:
        return _buildEmptyState('${_tabs[_selectedTabIndex]} coming soon!');
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTabIndex == 3 ? Icons.bookmark_outline : Icons.info_outline,
              size: 80,
              color: context.textColor.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMyMealsTab() {
    if (_loadingMeals) {
      return Center(
        child: CircularProgressIndicator(
          color: context.textColor,
        ),
      );
    }

    if (_myMeals.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant,
                size: 80,
                color: context.textColor.withOpacity(0.3),
              ),
              SizedBox(height: 16),
              Text(
                'Create Custom Meals',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Combine multiple foods into custom meals\nfor quick logging',
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

    return RefreshIndicator(
      onRefresh: _loadMeals,
      color: context.textColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _myMeals.length,
        itemBuilder: (context, index) {
          final meal = _myMeals[index];
          return _buildMealCard(meal);
        },
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  meal['name'] ?? 'Unnamed Meal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
              ),
              Icon(Icons.add_circle_outline, color: context.textColor, size: 28),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_fire_department_outlined, size: 16, color: context.textColor.withOpacity(0.7)),
              SizedBox(width: 4),
              Text(
                '${meal['totalCalories'] ?? 0} cal',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textColor.withOpacity(0.7),
                ),
              ),
              SizedBox(width: 4),
              Text(
                '•',
                style: TextStyle(color: context.textColor.withOpacity(0.5)),
              ),
              SizedBox(width: 4),
              Text(
                '${(meal['items'] as List?)?.length ?? 0} items',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyFoodsTab() {
    if (_loadingCustomFoods) {
      return Center(
        child: CircularProgressIndicator(
          color: context.textColor,
        ),
      );
    }

    if (_customFoods.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fastfood,
                size: 80,
                color: context.textColor.withOpacity(0.3),
              ),
              SizedBox(height: 16),
              Text(
                'Create Custom Foods',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add your own foods with custom\nnutrition information',
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

    return RefreshIndicator(
      onRefresh: _loadCustomFoods,
      color: context.textColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _customFoods.length,
        itemBuilder: (context, index) {
          final food = _customFoods[index];
          return _buildCustomFoodCard(food);
        },
      ),
    );
  }

  Widget _buildCustomFoodCard(Map<String, dynamic> food) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  food['description'] ?? 'Unnamed Food',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
              ),
              Icon(Icons.add_circle_outline, color: context.textColor, size: 28),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_fire_department_outlined, size: 16, color: context.textColor.withOpacity(0.7)),
              SizedBox(width: 4),
              Text(
                '${food['calories'] ?? 0} cal',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textColor.withOpacity(0.7),
                ),
              ),
              SizedBox(width: 4),
              Text(
                '•',
                style: TextStyle(color: context.textColor.withOpacity(0.5)),
              ),
              SizedBox(width: 4),
              Text(
                food['servingSize'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<Map<String, dynamic>> foods) {
    if (foods.isEmpty && _selectedTabIndex == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: context.textColor.withOpacity(0.4)),
            SizedBox(height: 16),
            Text(
              'No foods found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textColor.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: context.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _buildFoodItem(food);
      },
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    return GestureDetector(
      onTap: () async {
        final result = await Get.to(() => NutritionDetailPage(food: food));
        if (_selectedTabIndex == 3 && result != null) {
          _loadSavedFoods();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.tileColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] ?? 'Unknown Food',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_outlined,
                        size: 16,
                        color: context.textColor.withOpacity(0.7),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${food['calories'] ?? 0} cal',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textColor.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(color: context.textColor.withOpacity(0.5)),
                      ),
                      SizedBox(width: 4),
                      Text(
                        food['serving'] ?? '1 serving',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: context.textColor, size: 28),
          ],
        ),
      ),
    );
  }

  // Bottom buttons for All tab
  Widget _buildAllTabBottomButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(
            top: BorderSide(color: context.borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Get.to(() => const ManualFoodEntryPage());
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
                      Icon(Icons.edit_outlined, color: context.textColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Manual',
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
                  AppDialogs.showSuccessSnackbar(
                    title: "Voice Log",
                    message: "Voice logging coming soon!",
                  );
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
                      Icon(Icons.mic_outlined, color: context.textColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Voice Log',
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
          ],
        ),
      ),
    );
  }

  // Bottom button for My Meals tab
  Widget _buildMyMealsBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(
            top: BorderSide(color: context.borderColor, width: 1),
          ),
        ),
        child: GestureDetector(
          onTap: () async {
            final result = await Get.to(() => const CreateMealPage());
            if (result == true) {
              _loadMeals();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.textColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: context.cardColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Create a Meal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.cardColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bottom button for My Foods tab
  Widget _buildMyFoodsBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(
            top: BorderSide(color: context.borderColor, width: 1),
          ),
        ),
        child: GestureDetector(
          onTap: () async {
            final result = await Get.to(() => const CreateFoodPage());
            if (result == true) {
              _loadCustomFoods();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.textColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: context.cardColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add Food',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.cardColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}