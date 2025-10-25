import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/models/Auth/user.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/controllers/theme_controller.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/modules/Settings/views/adjust_goals.dart';
import 'package:CalAI/app/repo/firebase_user_repo.dart';
import 'weight_history_view.dart';
import 'edit_profile.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool isCaloriesBurnedEnabled = false;

  late ScannerController _scannerController;
  late String _userId;

  DateTime _selectedDate = DateTime.now();
  String _selectedLanguage = 'English';
  bool _isEditingName = false;
  late TextEditingController _nameController;
  String _tempName = '';
  late AuthController authController;
  final FirebaseUserRepo _userRepository = FirebaseUserRepo();

  UserModel? userModel;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    _scannerController = Get.find<ScannerController>();
    _nameController = TextEditingController();

    if (!authController.isAuthenticated) {
      setState(() {
        _errorMessage = 'User not authenticated. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    _userId = authController.userId!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder(
        future: _userRepository.getUserById(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: context.textColor,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            UserModel? userModel = snapshot.data;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. User Profile Box
                    _buildProfileBox(userModel!),
                    SizedBox(height: 2.h),
                    
                    // 2. Invite Friends Box
                    _buildInviteFriendsBox(),
                    SizedBox(height: 2.h),
                    
                    // 3. Personal Info Section
                    _buildSectionTitle('Personal'),
                    _buildMenuBox([
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Personal details',
                        onTap: () async {
                          if (userModel == null) return;
                          
                          final result = await Get.to(() => EditUserBasicInfoView(
                            userBasicInfo: userModel!.userInfo!,
                            userModel: userModel!,
                          ));

                          // Refresh if profile was updated
                          if (result != null && mounted) {
                            final updatedUser = await _userRepository.getUserById(_userId);
                            if (updatedUser != null) {
                              setState(() {
                                userModel = updatedUser;
                              });
                            }
                          }
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.restaurant_outlined,
                        title: 'Adjust macronutrients',
                        onTap: () {
                          if (userModel == null) return;
                          
                          Get.to(() => AdjustGoalsView(
                                userMacros: userModel!.userInfo!.userMacros,
                                userBasicInfo: userModel!.userInfo,
                                userModel: userModel!,
                              ));
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.flag_outlined,
                        title: 'Goal & current weight',
                        onTap: () async {
                          if (userModel == null) return;
                          
                          final result = await Get.to(() => EditUserBasicInfoView(
                                userBasicInfo: userModel!.userInfo!,
                                userModel: userModel!,
                              ));

                          // Refresh if profile was updated
                          if (result != null && mounted) {
                            final updatedUser = await _userRepository.getUserById(_userId);
                            if (updatedUser != null) {
                              setState(() {
                                userModel = updatedUser;
                              });
                            }
                          }
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'Weight History',
                        onTap: () {
                          if (userModel == null) return;
                          
                          Get.to(() => WeightHistoryView(
                                userId: userModel!.userId,
                              ));
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: _selectedLanguage,
                        onTap: () {
                          _showLanguageDialog();
                        },
                        showDivider: false,
                      ),
                    ]),
                    SizedBox(height: 2.h),
                    
                    // 4. Preferences Section
                    _buildSectionTitle('Preferences'),
                    _buildMenuBox([
                      // Theme Toggle with GetX
                      Obx(() {
                        final themeController = Get.find<ThemeController>();
                        String currentMode = themeController.isDarkMode ? 'Dark' : 'Light';
                        
                        return _buildMenuItemWithDropdown(
                          icon: Icons.brightness_6_outlined,
                          title: 'Appearance',
                          value: currentMode,
                          options: ['Light', 'Dark'],
                          onChanged: (String? newValue) async {
                            if (newValue != null) {
                              bool shouldBeDark = newValue == 'Dark';
                              if (themeController.isDarkMode != shouldBeDark) {
                                await themeController.toggleTheme();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Theme changed to $newValue mode'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        );
                      }),
                      _buildToggleMenuItem(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Add Burned Calories',
                        subtitle: 'Add burned calories to daily goal',
                        value: isCaloriesBurnedEnabled,
                        onChanged: (value) {
                          setState(() {
                            isCaloriesBurnedEnabled = value;
                          });
                        },
                      ),
                      _buildToggleMenuItem(
                        icon: Icons.sync_outlined,
                        title: 'Rollover calories',
                        subtitle: 'Carry unused calories to next day',
                        value: false,
                        onChanged: (value) {
                          // TODO: Implement rollover calories
                        },
                        showDivider: false,
                      ),
                    ]),
                    SizedBox(height: 2.h),
                    
                    // 5. Legal & Support Section
                    _buildSectionTitle('Legal & Support'),
                    _buildMenuBox([
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms and Conditions',
                        onTap: () {
                          // TODO: Open terms and conditions
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          // TODO: Open privacy policy
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.email_outlined,
                        title: 'Support Email',
                        subtitle: 'support@calai.com',
                        onTap: () {
                          // TODO: Open email client
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.lightbulb_outline,
                        title: 'Feature Request',
                        onTap: () {
                          // TODO: Open feature request form
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        onTap: () {
                          _showDeleteAccountDialog();
                        },
                        showDivider: false,
                      ),
                    ]),
                    SizedBox(height: 2.h),
                    
                    // 6. Logout Button
                    _buildLogoutButton(),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Profile Box
  Widget _buildProfileBox(UserModel userModel) {
    int age = userModel.userInfo?.age ?? 0;
    String name = userModel.name;
    
    if (!_isEditingName && _nameController.text.isEmpty) {
      _nameController.text = name;
    }
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        border: _isEditingName 
            ? Border.all(color: context.textColor, width: 2) 
            : null,
        boxShadow: [
          BoxShadow(
            color: context.textColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Image Circle
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              // Name and Age
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isEditingName
                        ? TextField(
                            controller: _nameController,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 0.5.h,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: context.borderColor),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: context.textColor),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditingName = true;
                                _tempName = name;
                              });
                            },
                            child: Text(
                              name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                          ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '$age years old',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isEditingName)
                Icon(Icons.edit, color: context.textColor.withOpacity(0.5), size: 20),
            ],
          ),
          // Done and Cancel buttons when editing
          if (_isEditingName) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingName = false;
                      _nameController.text = _tempName;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textColor.withOpacity(0.6),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: () => _saveName(userModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.textColor,
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.cardColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Save Name Method
  Future<void> _saveName(UserModel userModel) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final updatedUserModel = userModel.copyWith(
        name: _nameController.text.trim(),
      );
      
      await _userRepository.updateUserData(updatedUserModel);
      
      setState(() {
        _isEditingName = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Invite Friends Box
  Widget _buildInviteFriendsBox() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, color: Colors.white, size: 32),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Friends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  'Share CalAI with friends',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.textColor.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Menu Box Container
  Widget _buildMenuBox(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: context.textColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // Menu Item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              children: [
                Icon(icon, color: context.textColor.withOpacity(0.7), size: 24),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? context.textColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 0.3.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.textColor.withOpacity(0.4), size: 20),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, indent: 15.w, endIndent: 4.w, color: context.borderColor),
        ],
      ),
    );
  }

  // Toggle Menu Item
  Widget _buildToggleMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: Row(
            children: [
              Icon(icon, color: context.textColor.withOpacity(0.7), size: 24),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 0.3.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.blue,
                activeTrackColor: Colors.blue.withOpacity(0.5),
                inactiveThumbColor: context.textColor.withOpacity(0.4),
                inactiveTrackColor: context.textColor.withOpacity(0.3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 15.w, endIndent: 4.w, color: context.borderColor),
      ],
    );
  }

  Widget _buildMenuItemWithDropdown({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            children: [
              Icon(icon, color: context.textColor.withOpacity(0.7), size: 24),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.textColor,
                  ),
                ),
              ),
              // Dropdown on the right
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.borderColor),
                ),
                child: DropdownButton<String>(
                  value: value,
                  underline: SizedBox(),
                  isDense: true,
                  icon: Icon(Icons.arrow_drop_down, color: context.textColor.withOpacity(0.7)),
                  dropdownColor: context.cardColor,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textColor,
                  ),
                  items: options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 15.w, endIndent: 4.w, color: context.borderColor),
      ],
    );
  }

  // Logout Button
  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        // REMOVED: SignInBloc - implement auth logic differently.add(const SignOutRequired());
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(color: context.textColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: context.textColor, size: 22),
            SizedBox(width: 2.w),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Delete Account Dialog
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          title: Text('Delete Account', style: TextStyle(color: context.textColor)),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: TextStyle(color: context.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: context.textColor)),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement account deletion
                Navigator.pop(dialogContext);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Language',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 3.h),
                _buildLanguageOption('🇺🇸', 'English'),
                _buildLanguageOption('🇪🇸', 'Español'),
                _buildLanguageOption('🇵🇹', 'Português'),
                _buildLanguageOption('🇫🇷', 'Français'),
                _buildLanguageOption('🇩🇪', 'Deutsch'),
                _buildLanguageOption('🇮🇹', 'Italiano'),
                _buildLanguageOption('🇮🇳', 'हिन्दी (Hindi)'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String flag, String language) {
    bool isSelected = _selectedLanguage == language;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to $language'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        margin: EdgeInsets.only(bottom: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? context.textColor : context.tileColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.textColor : context.borderColor,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: TextStyle(fontSize: 28),
            ),
            SizedBox(width: 4.w),
            Text(
              language,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? context.cardColor : context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: context.textColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: context.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationItem(
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: context.textColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textColor.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: context.textColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: context.textColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.all(context.textColor),
        ),
      ],
    );
  }
}