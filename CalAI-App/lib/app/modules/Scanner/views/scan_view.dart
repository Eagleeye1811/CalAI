import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sizer/sizer.dart';
import 'package:calai/app/constants/colors.dart';
import 'package:calai/app/controllers/auth_controller.dart';
import 'package:calai/app/modules/Scanner/controller/scanner_controller.dart';

enum ScanMode { food, barcode, gallery }

class MealAiCamera extends StatefulWidget {
  MealAiCamera({super.key});

  @override
  State<MealAiCamera> createState() => _MealAiCameraState();
}

class _MealAiCameraState extends State<MealAiCamera> {
  ScanMode _selectedscanMode = ScanMode.food;
  final ImagePicker _picker = ImagePicker();

  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      File imageFile = File(image.path);

      final ScannerController scannerController = Get.find<ScannerController>();
      final authController = Get.find<AuthController>();  

      scannerController.processNutritionQueryRequest(
          authController.userId!,  
          imageFile,
          _selectedscanMode,
          context);
    }
  }

  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File imageFile = File(image.path);

      final ScannerController scannerController = Get.find<ScannerController>();
      final authController = Get.find<AuthController>();

      scannerController.processNutritionQueryRequest(
          authController.userId!,
          imageFile,
          _selectedscanMode,
          context);
      Navigator.pop(context);
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('Scanner Guide', style: TextStyle(color: context.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Camera: Take a photo of your meal', 
              style: TextStyle(color: context.textColor)),
            SizedBox(height: 8),
            Text('• Gallery: Select from your photos',
              style: TextStyle(color: context.textColor)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Got it', style: TextStyle(color: context.textColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: context.textColor),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.fastfood_outlined,
                size: 80,
                color: context.textColor.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Choose an option',
              style: TextStyle(color: context.textColor, fontSize: 18),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(Icons.camera_alt, 'Camera', _openCamera),
                _buildButton(Symbols.image_rounded, 'Gallery', _openGallery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MealAIColors.darkSuccess,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          SizedBox(height: 10),
          Text(label, style: TextStyle(color: context.textColor)),
        ],
      ),
    );
  }
}