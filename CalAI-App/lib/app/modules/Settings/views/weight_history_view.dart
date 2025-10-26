import 'package:flutter/material.dart';
import 'package:calai/app/constants/colors.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:calai/app/repo/firebase_user_repo.dart';

class WeightHistoryView extends StatefulWidget {
  final String userId;

  const WeightHistoryView({
    super.key,
    required this.userId,
  });

  @override
  State<WeightHistoryView> createState() => _WeightHistoryViewState();
}

class _WeightHistoryViewState extends State<WeightHistoryView> {
  // Weight history list - will be populated from Firebase
  final List<WeightEntry> _weightHistory = [];

  bool _isLoading = true; // Changed: Initialize as true

  @override
  void initState() {
    super.initState();
    // Call after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWeightHistory();
    });
  }

  Future<void> _fetchWeightHistory() async {
    try {
      final firebaseRepo = FirebaseUserRepo();
      final history = await firebaseRepo.getWeightHistory(widget.userId);
      
      if (mounted) {
        setState(() {
          _weightHistory.clear();
          _weightHistory.addAll(
            history.map((entry) => WeightEntry(
              date: entry['date'] as DateTime,
              weight: entry['weight'] as double,
            )).toList()
          );
        });
      }
    } catch (e) {
      print('Error fetching weight history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load weight history'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getWeightChange(int index) {
    if (index == _weightHistory.length - 1) return '';
    
    final currentWeight = _weightHistory[index].weight;
    final previousWeight = _weightHistory[index + 1].weight;
    final change = currentWeight - previousWeight;
    
    if (change == 0) return '→ No change';
    if (change > 0) return '↑ +${change.abs().toStringAsFixed(1)} kg';
    return '↓ -${change.abs().toStringAsFixed(1)} kg';
  }

  Color _getWeightChangeColor(int index) {
    if (index == _weightHistory.length - 1) return context.textColor.withOpacity(0.5);
    
    final currentWeight = _weightHistory[index].weight;
    final previousWeight = _weightHistory[index + 1].weight;
    final change = currentWeight - previousWeight;
    
    if (change == 0) return context.textColor.withOpacity(0.5);
    if (change > 0) return Colors.red;
    return Colors.green;
  }

  Future<void> _showAddWeightDialog() async {
    final TextEditingController weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            final isDarkMode = Theme.of(builderContext).brightness == Brightness.dark;
            
            return AlertDialog(
              backgroundColor: builderContext.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Add Weight Entry',
                style: TextStyle(
                  color: builderContext.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    autofocus: true,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: builderContext.textColor),
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      labelStyle: TextStyle(color: builderContext.textColor.withOpacity(0.7)),
                      hintText: 'e.g., 72.5',
                      hintStyle: TextStyle(color: builderContext.textColor.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.monitor_weight, color: builderContext.textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: builderContext.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(builderContext).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: builderContext.tileColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: builderContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: isDarkMode
                                  ? ColorScheme.dark(
                                      primary: builderContext.textColor,
                                      onPrimary: builderContext.cardColor,
                                      onSurface: builderContext.textColor,
                                      surface: builderContext.cardColor,
                                    )
                                  : ColorScheme.light(
                                      primary: builderContext.textColor,
                                      onPrimary: builderContext.cardColor,
                                      onSurface: builderContext.textColor,
                                      surface: builderContext.cardColor,
                                    ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: builderContext.textColor,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: builderContext.borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: builderContext.tileColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: builderContext.textColor.withOpacity(0.7), size: 20),
                              SizedBox(width: 2.w),
                              Text(
                                DateFormat('MMM dd, yyyy').format(selectedDate),
                                style: TextStyle(
                                  color: builderContext.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.edit_calendar, color: builderContext.textColor.withOpacity(0.5), size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: builderContext.textColor.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (weightController.text.isEmpty) {
                      Navigator.pop(dialogContext, {
                        'error': 'Please enter a weight',
                      });
                      return;
                    }

                    final weight = double.tryParse(weightController.text);
                    if (weight == null || weight <= 0 || weight > 300) {
                      Navigator.pop(dialogContext, {
                        'error': 'Please enter a valid weight (1-300 kg)',
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'weight': weight,
                      'date': selectedDate,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(builderContext).colorScheme.primary,
                    foregroundColor: Theme.of(builderContext).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    
    // Dispose controller after frame to avoid disposal during widget teardown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      weightController.dispose();
    });

    // Handle the result after dialog is closed
    if (result != null && mounted) {
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (result.containsKey('weight')) {
        final weight = result['weight'] as double;
        final date = result['date'] as DateTime;

        // Save to Firebase
        try {
          final firebaseRepo = FirebaseUserRepo();
          await firebaseRepo.addWeightEntry(widget.userId, weight, date);
          
          setState(() {
            _weightHistory.add(WeightEntry(date: date, weight: weight));
            _weightHistory.sort((a, b) => b.date.compareTo(a.date));
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Weight entry added successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add weight entry'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Weight History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.textColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWeightDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        label: Text(
          'Add Weight',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _weightHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: context.textColor.withOpacity(0.3),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No weight history yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Start tracking your weight progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textColor.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        onPressed: _showAddWeightDialog,
                        icon: Icon(Icons.add),
                        label: Text('Add First Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _weightHistory.length,
                  itemBuilder: (context, index) {
                    final entry = _weightHistory[index];
                    final isLatest = index == 0;
                    final weightChange = _getWeightChange(index);
                    final changeColor = _getWeightChangeColor(index);

                    return Dismissible(
                      key: Key('${entry.date.toString()}_${entry.weight}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, color: Colors.white, size: 32),
                            SizedBox(height: 0.5.h),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              backgroundColor: context.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                'Delete Entry?',
                                style: TextStyle(
                                  color: context.textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete this weight entry from ${DateFormat('MMM dd, yyyy').format(entry.date)}?',
                                style: TextStyle(color: context.textColor),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: context.textColor),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        final deletedEntry = entry;
                        final deletedIndex = index;
                        
                        // TODO: Delete from Firebase
                        // final firebaseRepo = FirebaseUserRepo();
                        // await firebaseRepo.deleteWeightEntry(widget.userId, entry.date);
                        
                        setState(() {
                          _weightHistory.removeAt(index);
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Weight entry deleted'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () {
                                setState(() {
                                  _weightHistory.insert(deletedIndex, deletedEntry);
                                });
                                // TODO: Re-add to Firebase if deleted
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isLatest
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: context.textColor.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Date section
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: isLatest
                                    ? Theme.of(context).colorScheme.primary
                                    : context.tileColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('MMM').format(entry.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isLatest
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : context.textColor.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd').format(entry.date),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isLatest
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : context.textColor,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('yyyy').format(entry.date),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isLatest
                                          ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                          : context.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 4.w),
                            // Weight info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${entry.weight.toStringAsFixed(1)} kg',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: context.textColor,
                                        ),
                                      ),
                                      if (isLatest) ...[
                                        SizedBox(width: 2.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2.w,
                                            vertical: 0.5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Current',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (weightChange.isNotEmpty) ...[
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      weightChange,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: changeColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({
    required this.date,
    required this.weight,
  });
}