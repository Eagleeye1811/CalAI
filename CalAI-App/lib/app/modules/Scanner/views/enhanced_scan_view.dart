import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/controllers/auth_controller.dart';
import 'package:CalAI/app/modules/Scanner/controller/scanner_controller.dart';
import 'package:CalAI/app/modules/DashBoard/view/widgets/scan_options_sheet.dart';
import 'package:CalAI/app/modules/Scanner/views/scan_view.dart';

class EnhancedScanView extends StatefulWidget {
  final ScanType scanType;
  
  const EnhancedScanView({Key? key, required this.scanType}) : super(key: key);

  @override
  State<EnhancedScanView> createState() => _EnhancedScanViewState();
}

class _EnhancedScanViewState extends State<EnhancedScanView> {
  final ImagePicker _picker = ImagePicker();
  bool _torchOn = false;
  ScanType _currentScanType = ScanType.scanFood;

  @override
  void initState() {
    super.initState();
    _currentScanType = widget.scanType;
    
    // If gallery is selected, open it immediately
    if (_currentScanType == ScanType.gallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openGallery();
      });
    }
  }

  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _processImage(File(image.path));
    }
  }

  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _processImage(File(image.path));
    } else {
      // If user cancels gallery, go back
      Navigator.pop(context);
    }
  }

  void _processImage(File imageFile) {
    final ScannerController scannerController = Get.find<ScannerController>();
    final authController = Get.find<AuthController>();

    // Convert ScanType to ScanMode
    ScanMode scanMode;
    switch (_currentScanType) {
      case ScanType.barcode:
        scanMode = ScanMode.barcode;
        break;
      case ScanType.gallery:
        scanMode = ScanMode.gallery;
        break;
      default:
        scanMode = ScanMode.food;
    }

    scannerController.processNutritionQueryRequest(
      authController.userId!,  
      imageFile,
      scanMode,
      context,
    );
    Navigator.pop(context);
  }

  void _showInfoDialog() {
    String infoText = '';
    switch (_currentScanType) {
      case ScanType.scanFood:
        infoText = '📸 Point your camera at the food\n\n'
            '✓ Ensure good lighting\n'
            '✓ Capture the entire plate\n'
            '✓ Avoid shadows';
        break;
      case ScanType.barcode:
        infoText = '🔲 Scan the barcode on the package\n\n'
            '✓ Hold steady\n'
            '✓ Align barcode in frame\n'
            '✓ Ensure barcode is clear';
        break;
      case ScanType.foodLabel:
        infoText = '🏷️ Capture the nutrition label\n\n'
            '✓ Keep label flat\n'
            '✓ Ensure all text is visible\n'
            '✓ Avoid glare and blur';
        break;
      case ScanType.gallery:
        infoText = '📷 Select a photo from your gallery\n\n'
            '✓ Choose clear images\n'
            '✓ Food should be visible\n'
            '✓ Good lighting preferred';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('How to Scan'),
          ],
        ),
        content: Text(infoText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder (you can integrate camera plugin here)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getScanIcon(),
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(height: 16),
                Text(
                  _getScanTitle(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Top bar with close and info buttons
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  // Info button
                  GestureDetector(
                    onTap: _showInfoDialog,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.info_outline, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: 40, top: 20, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 4 scan type options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScanTypeButton(
                        icon: Icons.camera_alt,
                        label: 'Scan Food',
                        scanType: ScanType.scanFood,
                      ),
                      _buildScanTypeButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Barcode',
                        scanType: ScanType.barcode,
                      ),
                      _buildScanTypeButton(
                        icon: Icons.label,
                        label: 'Label',
                        scanType: ScanType.foodLabel,
                      ),
                      _buildScanTypeButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        scanType: ScanType.gallery,
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  
                  // Bottom row: Torch, Capture, (Spacer)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Torch button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _torchOn = !_torchOn;
                          });
                          // TODO: Implement actual torch control with camera plugin
                          Get.snackbar(
                            'Torch',
                            _torchOn ? 'Torch On' : 'Torch Off',
                            duration: Duration(seconds: 1),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _torchOn 
                                ? Colors.yellow.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _torchOn ? Colors.yellow : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                            color: _torchOn ? Colors.yellow : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      
                      // Capture button
                      GestureDetector(
                        onTap: _currentScanType == ScanType.gallery 
                            ? _openGallery 
                            : _openCamera,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      
                      // Spacer to balance layout
                      SizedBox(width: 56),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTypeButton({
    required IconData icon,
    required String label,
    required ScanType scanType,
  }) {
    final bool isSelected = _currentScanType == scanType;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentScanType = scanType;
        });
        if (scanType == ScanType.gallery) {
          _openGallery();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getScanIcon() {
    switch (_currentScanType) {
      case ScanType.scanFood:
        return Icons.camera_alt;
      case ScanType.barcode:
        return Icons.qr_code_scanner;
      case ScanType.foodLabel:
        return Icons.label;
      case ScanType.gallery:
        return Icons.photo_library;
    }
  }

  String _getScanTitle() {
    switch (_currentScanType) {
      case ScanType.scanFood:
        return 'Point at your food';
      case ScanType.barcode:
        return 'Scan barcode';
      case ScanType.foodLabel:
        return 'Capture nutrition label';
      case ScanType.gallery:
        return 'Select from gallery';
    }
  }
}