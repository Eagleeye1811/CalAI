import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';

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
      final authController = Get.find<AuthController>();  // ✅ Use GetX

      scannerController.processNutritionQueryRequest(
          authController.userId!,  // ✅ Correct
          imageFile,
          _selectedscanMode,
          context);
      Navigator.pop(context);
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanner Guide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• Camera: Take a photo of your meal'),
            SizedBox(height: 8),
            Text('• Gallery: Select from your photos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
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
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.fastfood_outlined,
                size: 80,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Choose an option',
              style: TextStyle(color: Colors.white, fontSize: 18),
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
          Text(label, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
