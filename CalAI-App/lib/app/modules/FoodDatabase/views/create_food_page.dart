import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:calai/app/constants/colors.dart';
import 'add_nutrients_page.dart';

class CreateFoodPage extends StatefulWidget {
  final Map<String, dynamic>? existingFood;
  final String? foodId;
  
  const CreateFoodPage({
    Key? key,
    this.existingFood,
    this.foodId,
  }) : super(key: key);

  @override
  State<CreateFoodPage> createState() => _CreateFoodPageState();
}

class _CreateFoodPageState extends State<CreateFoodPage> {
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();
  final TextEditingController _servingsPerContainerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingFood();
  }

  void _loadExistingFood() {
    if (widget.existingFood != null) {
      _brandNameController.text = widget.existingFood!['brandName'] ?? '';
      _descriptionController.text = widget.existingFood!['description'] ?? '';
      _servingSizeController.text = widget.existingFood!['servingSize'] ?? '';
      _servingsPerContainerController.text = widget.existingFood!['servingsPerContainer']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    _servingsPerContainerController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    // Validate all fields
    if (_brandNameController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a brand name',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a description',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_servingSizeController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter serving size',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_servingsPerContainerController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter servings per container',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Navigate to nutrients page with the basic info
    Get.to(() => AddNutrientsPage(
      brandName: _brandNameController.text,
      description: _descriptionController.text,
      servingSize: _servingSizeController.text,
      servingsPerContainer: _servingsPerContainerController.text,
      existingFood: widget.existingFood,
      foodId: widget.foodId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingFood != null ? 'Edit Food' : 'Create Custom Food',
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                children: [
                  _buildProgressDot(true),
                  Expanded(child: _buildProgressLine(false)),
                  _buildProgressDot(false),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Basic Info',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                  Text(
                    'Nutrients',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4.h),

              // Form fields
              _buildInputField(
                'Brand Name',
                'e.g., Nature Valley, Quaker',
                _brandNameController,
                Icons.business,
              ),
              
              SizedBox(height: 2.h),
              
              _buildInputField(
                'Description',
                'e.g., Crunchy Granola Bar',
                _descriptionController,
                Icons.description,
              ),
              
              SizedBox(height: 2.h),
              
              _buildInputField(
                'Serving Size',
                'e.g., 1 bar (40g)',
                _servingSizeController,
                Icons.restaurant,
              ),
              
              SizedBox(height: 2.h),
              
              _buildInputField(
                'Servings Per Container',
                'e.g., 6',
                _servingsPerContainerController,
                Icons.inventory_2,
                keyboardType: TextInputType.number,
              ),

              SizedBox(height: 4.h),

              // Next button
              _buildNextButton(),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool active) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary : context.borderColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: active 
                ? Theme.of(context).colorScheme.onPrimary 
                : context.cardColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(bool active) {
    return Container(
      height: 2,
      color: active ? Theme.of(context).colorScheme.primary : context.borderColor,
      margin: EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: context.tileColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.textColor.withOpacity(0.4), fontSize: 15),
              prefixIcon: Icon(icon, color: context.textColor.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(fontSize: 16, color: context.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Bounceable(
      onTap: _goToNextPage,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.textColor.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}