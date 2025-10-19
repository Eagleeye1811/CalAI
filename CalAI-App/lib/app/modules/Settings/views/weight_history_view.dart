import 'package:flutter/material.dart';
import 'package:CalAI/app/constants/colors.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

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
  // Sample data - Replace with actual database fetch
  final List<WeightEntry> _weightHistory = [
    WeightEntry(date: DateTime.now().subtract(Duration(days: 90)), weight: 75.5),
    WeightEntry(date: DateTime.now().subtract(Duration(days: 60)), weight: 74.2),
    WeightEntry(date: DateTime.now().subtract(Duration(days: 30)), weight: 73.0),
    WeightEntry(date: DateTime.now().subtract(Duration(days: 15)), weight: 72.5),
    WeightEntry(date: DateTime.now().subtract(Duration(days: 7)), weight: 72.0),
    WeightEntry(date: DateTime.now(), weight: 71.8),
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchWeightHistory();
  }

  Future<void> _fetchWeightHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Fetch weight history from database
      // Example: await FirebaseUserRepo().getWeightHistory(widget.userId);
      
      await Future.delayed(Duration(milliseconds: 500)); // Simulate loading
      
    } catch (e) {
      print('Error fetching weight history: $e');
    } finally {
      setState(() => _isLoading = false);
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
    if (index == _weightHistory.length - 1) return Colors.grey;
    
    final currentWeight = _weightHistory[index].weight;
    final previousWeight = _weightHistory[index + 1].weight;
    final change = currentWeight - previousWeight;
    
    if (change == 0) return Colors.grey;
    if (change > 0) return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: MealAIColors.blackText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Weight History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: MealAIColors.blackText,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _weightHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No weight history yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Start tracking your weight progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
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

                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isLatest
                            ? Border.all(color: MealAIColors.blackText, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                                  ? MealAIColors.blackText
                                  : Colors.grey[100],
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
                                        ? Colors.white
                                        : MealAIColors.blueGrey,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd').format(entry.date),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isLatest
                                        ? Colors.white
                                        : MealAIColors.blackText,
                                  ),
                                ),
                                Text(
                                  DateFormat('yyyy').format(entry.date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isLatest
                                        ? Colors.white70
                                        : MealAIColors.blueGrey,
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
                                        color: MealAIColors.blackText,
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
                                          color: MealAIColors.blackText,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Current',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
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