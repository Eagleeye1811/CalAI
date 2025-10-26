import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calai/app/constants/colors.dart';

class AppDialogs {
  /// Show a minimal adding dialog
  static void showAddDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = "Add",
    String cancelText = "Cancel",
  }) {
    Get.dialog(
      Builder(
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.textColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: context.textColor,
                    size: 24,
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textColor.withOpacity(0.6),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: context.borderColor,
                            ),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            color: context.textColor.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.textColor,
                          foregroundColor: context.cardColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Show success snackbar with minimal styling
  static void showSuccessSnackbar({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final context = Get.context;
    if (context == null) return;

    Get.snackbar(
      title,
      message,
      backgroundColor: context.textColor,
      colorText: context.cardColor,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      maxWidth: 300,
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: context.cardColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: context.cardColor,
                size: 16,
              ),
            ),
          );
        },
      ),
      shouldIconPulse: false,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show error snackbar with minimal styling
  static void showErrorSnackbar({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = Get.context;
    if (context == null) return;

    Get.snackbar(
      title,
      message,
      backgroundColor: context.textColor.withOpacity(0.6),
      colorText: context.cardColor,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      maxWidth: 300,
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: context.cardColor.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error_outline,
          color: context.cardColor,
          size: 16,
        ),
      ),
      shouldIconPulse: false,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show info snackbar with minimal styling
  static void showInfoSnackbar({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final context = Get.context;
    if (context == null) return;

    Get.snackbar(
      title,
      message,
      backgroundColor: context.tileColor,
      colorText: context.textColor,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: context.textColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.info_outline,
          color: context.textColor,
          size: 16,
        ),
      ),
      shouldIconPulse: false,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show loading dialog with minimal styling
  static void showLoadingDialog({
    required String title,
    required String message,
  }) {
    Get.dialog(
      Builder(
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 300,
              maxHeight: 200,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading indicator
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.textColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Message
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textColor.withOpacity(0.6),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false, // Prevent dismissing while loading
    );
  }

  /// Hide the currently shown dialog
  static void hideDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}