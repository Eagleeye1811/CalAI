import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:CalAI/app/controllers/user_controller.dart';
import 'package:CalAI/app/modules/Scanner/views/enhanced_scan_view.dart';

enum ScanType { scanFood, barcode, foodLabel, gallery }

class ScanOptionsSheet extends StatelessWidget {
  const ScanOptionsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Scan Food',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 20),
          
          // 4 options in a row
          Row(
            children: [
              Expanded(
                child: _buildScanOption(
                  context: context,
                  icon: Icons.camera_alt,
                  title: 'Scan Food',
                  color: Colors.blue,
                  scanType: ScanType.scanFood,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildScanOption(
                  context: context,
                  icon: Icons.qr_code_scanner,
                  title: 'Barcode',
                  color: Colors.orange,
                  scanType: ScanType.barcode,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildScanOption(
                  context: context,
                  icon: Icons.label,
                  title: 'Food Label',
                  color: Colors.green,
                  scanType: ScanType.foodLabel,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildScanOption(
                  context: context,
                  icon: Icons.photo_library,
                  title: 'Gallery',
                  color: Colors.purple,
                  scanType: ScanType.gallery,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildScanOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required ScanType scanType,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        try {
          final userController = Get.find<UserController>();
          Get.to(() => EnhancedScanView(scanType: ScanType.scanFood)); 
        } catch (_) {
          Get.to(() => EnhancedScanView(scanType: scanType));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}