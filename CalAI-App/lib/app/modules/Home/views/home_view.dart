import 'package:CalAI/app/components/empty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sizer/sizer.dart';
import 'package:timeline_date_picker_plus/timeline_date_picker_plus.dart';
import 'package:CalAI/app/components/nutritionTrackerCard.dart'
    show NutritionTrackerCard;
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/AI/nutrition_record.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/controllers/user_controller.dart';
import 'package:CalAI/app/modules/Home/component/nutrition_card.dart';
import 'package:CalAI/app/modules/Home/views/nutrition_view.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/modules/Settings/views/settings.dart';
import 'package:CalAI/app/repo/firebase_user_repo.dart';
import 'package:CalAI/app/repo/nutrition_record_repo.dart';
import 'package:CalAI/app/utility/registry_service.dart';
import 'package:CalAI/app/components/custom_date_selector.dart';
import 'package:CalAI/app/components/streak_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  late ScannerController _scannerController;
  late String _userId;

  DateTime _selectedDate = DateTime.now();

  late AuthController authController;
  final FirebaseUserRepo _userRepository = FirebaseUserRepo();

  UserModel? userModel;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentStreak = 0;
  bool _showLeftView = true;
  int _waterConsumed = 0;
  Map<String, bool> _calendarActivityMap = {};
  final int _waterGoal = 2500;

  @override
  void initState() {
    super.initState();
    _scannerController = Get.put(ScannerController());
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _calculateStreak();
      _loadCalendarActivity();
    }
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        setState(() {
          _errorMessage = 'User not authenticated. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      _userId = authController.userId!;

      final userController = Get.find<UserController>();

      if (userController.hasUser) {
        setState(() {
          userModel = userController.userModel;
          _isLoading = false;
        });
        _scannerController.selectedDate = _selectedDate;
        _updateNutritionValues(userController.userModel);
        _fetchRecords();
        _calculateStreak();
        _loadCalendarActivity();
      } else {
        await userController.loadUser(_userId);
        
        if (userController.hasUser) {
          setState(() {
            userModel = userController.userModel;
            _isLoading = false;
          });
          _scannerController.selectedDate = _selectedDate;
          _updateNutritionValues(userController.userModel);
          _fetchRecords();
          _calculateStreak();
          _loadCalendarActivity();
        } else {
          setState(() {
            _errorMessage = 'Failed to load user data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _fetchRecords() {
    if (_userId.isNotEmpty) {
      _scannerController.getRecordByDate(
          _userId, _scannerController.selectedDate);
      _calculateStreak();
    }
  }

  Future<void> _calculateStreak() async {
    if (_userId.isEmpty) return;
    
    try {
      int streak = 0;
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      
      // First check if today has activity
      final todayData = await serviceLocator<NutritionRecordRepo>()
          .getNutritionData(_userId, todayNormalized);
      
      // If today has no activity, check if yesterday has activity
      // This makes the streak more forgiving (you have grace until end of day)
      DateTime startDate = todayNormalized;
      if (todayData.dailyRecords.isEmpty) {
        // Check yesterday
        final yesterday = todayNormalized.subtract(Duration(days: 1));
        final yesterdayData = await serviceLocator<NutritionRecordRepo>()
            .getNutritionData(_userId, yesterday);
        
        if (yesterdayData.dailyRecords.isEmpty) {
          // No activity today or yesterday - streak is 0
          if (mounted) {
            setState(() {
              _currentStreak = 0;
            });
          }
          return;
        } else {
          // Start counting from yesterday
          startDate = yesterday;
        }
      }
      
      // Count backwards from start date
      for (int i = 0; i < 365; i++) {
        final checkDate = startDate.subtract(Duration(days: i));
        final dailyData = await serviceLocator<NutritionRecordRepo>()
            .getNutritionData(_userId, checkDate);
        
        if (dailyData.dailyRecords.isNotEmpty) {
          streak++;
        } else {
          // Streak broken - stop counting
          break;
        }
      }
      
      if (mounted) {
        setState(() {
          _currentStreak = streak;
        });
      }
    } catch (e) {
      print('Error calculating streak: $e');
    }
  }

  void _updateNutritionValues(UserModel? userModel) {
    if (userModel != null && userModel.userInfo != null) {
      _scannerController.updateNutritionValues(
        maxCalories: userModel.userInfo!.userMacros.calories,
        maxFat: userModel.userInfo!.userMacros.fat,
        maxProtein: userModel.userInfo!.userMacros.protein,
        maxCarb: userModel.userInfo!.userMacros.carbs,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.apple,
              color: MealAIColors.blackText,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'CalAI',
              style: TextStyle(
                color: MealAIColors.blackText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // WRAPPED IN GetBuilder TO UPDATE AUTOMATICALLY
                    GetBuilder<ScannerController>(
            builder: (controller) {
              return GestureDetector(
                onTap: () async {
                  // Recalculate streak and get real week activity
                  await _calculateStreak();
                  final weekActivity = await _calculateWeekActivity();
                  
                  // Show dialog with smooth animation
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                    barrierColor: Colors.black54,
                    transitionDuration: Duration(milliseconds: 300),
                    pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
                      return StreakDialog(
                        streakCount: _currentStreak,
                        weekActivity: weekActivity,
                      );
                    },
                    transitionBuilder: (context, animation, secondaryAnimation, child) {
                      // Smooth fade + scale animation
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                          child: child,
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(right: 16),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$_currentStreak',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFFF5F5F5),
              Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: MealAIColors.selectedTile,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(
                color: MealAIColors.blackText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MealAIColors.selectedTile,
              ),
            ),
          ],
        ),
      );
    }

    if (userModel == null) {
      return Center(
        child: Text(
          'User data not available',
          style: TextStyle(
            color: MealAIColors.blackText,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView(
      physics: BouncingScrollPhysics(),
      children: [
        SizedBox(height: 2.h),
        _buildDateScroller(),
        _buildNutritionTracker(),
        SizedBox(height: 2.h),
        _buildMealsList(),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildDateScroller() {
    return CustomDateSelector(
      selectedDate: _selectedDate,
      datesWithActivity: _calendarActivityMap,
      onDateSelected: (date) {
        setState(() {
          _selectedDate = date;
        });
        _scannerController.selectedDate = _selectedDate;
        _scannerController.getRecordByDate(_userId, date);
      },
    );
  }

  Widget _buildNutritionTracker() {
    return Column(
      children: [
        SizedBox(
          height: 380,
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
              _buildPage3(),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? MealAIColors.blackText
                    : MealAIColors.grey.withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPage1() {
    return GetBuilder<ScannerController>(
      builder: (controller) {
        return NutritionTrackerCard(
          maximumCalories: controller.maximumCalories.value,
          consumedCalories: controller.consumedCalories.value,
          burnedCalories: controller.burnedCalories.value,
          maximumFat: controller.maximumFat.value,
          consumedFat: controller.consumedFat.value,
          maximumProtein: controller.maximumProtein.value,
          consumedProtein: controller.consumedProtein.value,
          maximumCarb: controller.maximumCarb.value,
          consumedCarb: controller.consumedCarb.value,
          showLeftView: _showLeftView,
          onToggle: () {
            setState(() {
              _showLeftView = !_showLeftView;
            });
          },
        );
      },
    );
  }

  Widget _buildPage2() {
    return GetBuilder<ScannerController>(
      builder: (controller) {
        int fiber = controller.consumedFiber.value;
        int maxFiber = 30;
        int sugar = controller.consumedSugar.value;
        int maxSugar = 50;
        int sodium = controller.consumedSodium.value;
        int maxSodium = 2300;
        int healthScore = 75;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNutrientBox(
                      'Fiber',
                      fiber,
                      maxFiber,
                      Icons.grain,
                      Colors.brown,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildNutrientBox(
                      'Sugar',
                      sugar,
                      maxSugar,
                      Icons.cookie_outlined,
                      Colors.pink,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildNutrientBox(
                      'Sodium',
                      sodium,
                      maxSodium,
                      Icons.water_drop_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildHealthScoreBox(healthScore),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage3() {
    return GetBuilder<ScannerController>(
      builder: (controller) {
        int steps = 0;
        int caloriesBurned = controller.burnedCalories.value;
        int waterConsumed = 0;
        int waterGoal = 2500;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActivityBox(
                      'Steps',
                      '$steps',
                      Icons.directions_walk,
                      Colors.blue,
                      subtitle: 'Today',
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildActivityBox(
                      'Burned',
                      '$caloriesBurned kcal',
                      Icons.local_fire_department,
                      Colors.deepOrange,
                      subtitle: 'Activities',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildWaterLevelBox(_waterConsumed, _waterGoal),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutrientBox(
    String label,
    int consumed,
    int maximum,
    IconData icon,
    Color color,
  ) {
    double percentage = maximum > 0 ? (consumed / maximum).clamp(0.0, 1.0) : 0.0;
    bool exceeded = consumed > maximum;
    int left = (maximum - consumed).clamp(0, maximum);

    return GestureDetector(
      onTap: () {
        setState(() {
          _showLeftView = !_showLeftView;
        });
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.w),
          border: Border.all(
            color: Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            if (_showLeftView) ...[
              Text(
                '$left${label == "Sodium" ? "mg" : "g"}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '$label left',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$consumed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: exceeded ? Colors.red : Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: ' /$maximum${label == "Sodium" ? "mg" : "g"}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$label eaten',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 2.h),
            CircularPercentIndicator(
              radius: 35,
              lineWidth: 6,
              animation: true,
              animationDuration: 800,
              percent: percentage,
              backgroundColor: Colors.grey[200]!,
              progressColor: exceeded ? Colors.red : color,
              circularStrokeCap: CircularStrokeCap.round,
              center: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualWaterEntry() async {
    final TextEditingController waterController = TextEditingController(
      text: _waterConsumed.toString(),
    );
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Set Water Intake',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: waterController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount (ml)',
                  hintText: 'Enter water intake',
                  prefixIcon: Icon(Icons.local_drink, color: Colors.blue),
                  suffixText: 'ml',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Goal: $_waterGoal ml',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final int? newAmount = int.tryParse(waterController.text);
                if (newAmount != null && newAmount >= 0) {
                  setState(() {
                    _waterConsumed = newAmount;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Set',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHealthScoreBox(int score) {
    int scoreOutOf10 = (score / 10).round();
    double progress = scoreOutOf10 / 10.0;
    
    Color scoreColor = score >= 75
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;
    
    String caption = score >= 75
        ? 'Excellent! Keep it up! 🎉'
        : score >= 50
            ? 'Good, but room for improvement'
            : 'Consider healthier choices';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: Color(0xFFE8E8E8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '$scoreOutOf10/10',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 55,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '5',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '10',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Based on your nutrition intake',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCalendarActivity() async {
    if (_userId.isEmpty) return;
    
    final now = DateTime.now();
    final dates = List.generate(7, (index) {
      return now.subtract(Duration(days: 3 - index));
    });
    
    // Fetch records for each date in the calendar
    for (var date in dates) {
      try {
        final repo = serviceLocator<NutritionRecordRepo>();
        final dailyData = await repo.getNutritionData(_userId, date);
        
        if (dailyData.dailyRecords.isNotEmpty) {
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          if (mounted) {
            setState(() {
              _calendarActivityMap[dateKey] = true;
            });
          }
        }
      } catch (e) {
        print('Error loading calendar activity for $date: $e');
      }
    }
  }

  Future<List<bool>> _calculateWeekActivity() async {
    if (_userId.isEmpty) return List.filled(7, false);
    
    try {
      final today = DateTime.now();
      final List<bool> weekActivity = [];
      
      // Calculate for the past 7 days (Sunday to Saturday)
      // Get the most recent Sunday
      final mostRecentSunday = today.subtract(Duration(days: today.weekday % 7));
      
      for (int i = 0; i < 7; i++) {
        final checkDate = mostRecentSunday.add(Duration(days: i));
        final dailyData = await serviceLocator<NutritionRecordRepo>()
            .getNutritionData(_userId, checkDate);
        
        weekActivity.add(dailyData.dailyRecords.isNotEmpty);
      }
      
      return weekActivity;
    } catch (e) {
      print('Error calculating week activity: $e');
      return List.filled(7, false);
    }
  }

  Widget _buildActivityBox(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            height: 95,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 48),
                if (subtitle != null) ...[
                  SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterLevelBox(int consumed, int goal) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.water_drop,
              color: Colors.blue,
              size: 28,
            ),
          ),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Water',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '${consumed} ml',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: () {
              _showManualWaterEntry();
            },
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_waterConsumed >= 250) {
                  _waterConsumed -= 250;
                }
              });
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.remove,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: () {
              setState(() {
                _waterConsumed += 250;
              });
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, right: 4.w),
          child: Row(
            children: [
              Text(
                "Recently uploaded",
                style: TextStyle(
                  color: MealAIColors.blackText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        GetBuilder<ScannerController>(
          builder: (controller) {
            if (controller.isLoading && controller.dailyRecords.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: MealAIColors.selectedTile,
                ),
              );
            }

            if (controller.dailyRecords.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmptyIllustrations(
                    removeHeightValue: true,
                    title: "No meals recorded",
                    message: "Start tracking your nutrition",
                    imagePath: "assets/svg/empty.svg",
                    width: 50.w,
                    height: 40.h,
                  )
                ],
              );
            }

            return ListView.builder(
              itemCount: controller.dailyRecords.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
              itemBuilder: (context, index) {
                NutritionRecord record = controller.dailyRecords[index];
                return NutritionCard(
                  nutritionRecord: record,
                  userModel: userModel!,
                );
              },
            );
          },
        ),
      ],
    );
  }
}