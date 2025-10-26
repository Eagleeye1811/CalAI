import 'package:calai/app/modules/Analytics/views/analytics_view.dart';
import 'package:calai/app/modules/Chat/Views/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:calai/app/controllers/user_controller.dart';
import 'package:lottie/lottie.dart';
import 'package:calai/app/constants/colors.dart';
import 'package:calai/app/modules/Home/views/home_view.dart';
import 'package:calai/app/modules/Scanner/views/scan_view.dart';
import 'package:calai/app/modules/Settings/views/settings.dart';  
import 'package:calai/app/modules/DashBoard/view/widgets/action_menu_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper widget to reduce repetition
  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData selectedIcon,
    required IconData unselectedIcon,
  }) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 26,
              color: isSelected
                  ? context.textColor
                  : context.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? context.textColor
                    : context.textColor.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: context.isDarkMode  
          ? Brightness.light 
          : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: context.surfaceColor,
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
        height: 65,
        color: context.cardColor,
        elevation: 20,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              index: 0,
              label: 'Home',
              selectedIcon: Icons.home,
              unselectedIcon: Icons.home_outlined,
            ),
            _buildNavItem(
              index: 1,
              label: 'Progress',
              selectedIcon: Icons.insert_chart,
              unselectedIcon: Icons.insert_chart_outlined,
            ),
            _buildNavItem(
              index: 2,
              label: 'Settings',
              selectedIcon: Icons.settings,
              unselectedIcon: Icons.settings_outlined,
            ),
            // Scan button with plus icon
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Show action menu bottom sheet
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ActionMenuBottomSheet(),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.textColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.textColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    size: 32,
                    color: context.cardColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(),
          AnalyticsView(),
          SettingsView(),
        ],
      ),
    );
  }
}