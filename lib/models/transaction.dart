import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String type;
  final String category;
  final String memberName;
  final String description;
  final IconData icon;

  MessTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.memberName,
    required this.description,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.toLowerCase(),
      'category': category.toLowerCase(),
      'memberName': memberName,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static MessTransaction fromMap(String id, Map<String, dynamic> map) {
    IconData getIconForCategory(String category) {
      switch (category) {
        case 'shopping':
          return Icons.shopping_bag_rounded;
        case 'meal':
          return Icons.restaurant_rounded;
        case 'extra':
          return Icons.receipt_long_rounded;
        case 'savings':
          return Icons.savings_rounded;
        case 'deposit':
          return Icons.account_balance_wallet_rounded;
        default:
          return Icons.attach_money_rounded;
      }
    }

    return MessTransaction(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? '',
      memberName: map['memberName'] ?? '',
      description: map['description'] ?? '',
      icon: getIconForCategory(map['category'] ?? ''),
    );
  }

  static Future<void> addTransactionWithMemberUpdate({
    required String memberId,
    required String title,
    required double amount,
    required String category,
    required String memberName,
    required String description,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
    
    final transaction = MessTransaction(
      id: transactionRef.id,
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: category == 'savings' || category == 'deposit' ? 'income' : 'expense',
      category: category,
      memberName: memberName,
      description: description,
      icon: Icons.attach_money,
    );

    // Update transaction
    batch.set(transactionRef, {
      ...transaction.toMap(),
      'memberId': memberId,
    });

    // Update member balance
    final memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
    batch.update(memberRef, {
      'balance': FieldValue.increment(
        transaction.type == 'income' ? amount : -amount
      ),
    });

    await batch.commit();
  }

  static Future<void> deleteTransactionWithMemberUpdate(String transactionId) async {
    final transactionDoc = await FirebaseFirestore.instance
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!transactionDoc.exists) return;

    final data = transactionDoc.data()!;
    final memberId = data['memberId'] as String;
    final amount = (data['amount'] as num).toDouble();
    final type = data['type'] as String;

    final batch = FirebaseFirestore.instance.batch();

    // Delete transaction
    batch.delete(transactionDoc.reference);

    // Update member balance
    final memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
    batch.update(memberRef, {
      'balance': FieldValue.increment(
        type == 'income' ? -amount : amount
      ),
    });

    await batch.commit();
  }

  static Stream<Map<String, double>> getFinancialSummary() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      Map<String, double> summary = {
        'income': 0.0,
        'expenses': 0.0,
        'shopping': 0.0,
        'meals': 0.0,
        'extra': 0.0,
        'deposits': 0.0,
        'totalMealCount': 0.0,
      };

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final amount = (data['amount'] as num).toDouble();
          final type = data['type']?.toString().toLowerCase() ?? '';
          final category = data['category']?.toString().toLowerCase() ?? '';

          print('Processing transaction: Type=$type, Category=$category, Amount=$amount');

          if (type == 'income') {
            summary['income'] = (summary['income'] ?? 0) + amount;
            if (category == 'deposit' || category == 'savings') {
              summary['deposits'] = (summary['deposits'] ?? 0) + amount;
            }
          } else if (type == 'expense') {
            summary['expenses'] = (summary['expenses'] ?? 0) + amount;
            
            switch (category) {
              case 'shopping':
                summary['shopping'] = (summary['shopping'] ?? 0) + amount;
                break;
              case 'meal':
                summary['meals'] = (summary['meals'] ?? 0) + amount;
                // Get meal count from transaction data
                final mealCount = data['mealCount'] != null ? 
                  (data['mealCount'] as num).toDouble() : 1.0;  // Default to 1 if not specified
                summary['totalMealCount'] = (summary['totalMealCount'] ?? 0) + mealCount;
                break;
              case 'extra':
                summary['extra'] = (summary['extra'] ?? 0) + amount;
                break;
            }
          }
        } catch (e) {
          print('Error processing transaction: $e');
          continue;
        }
      }

      print('Final summary: $summary');
      return summary;
    });
  }

  Color get color {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Future<String> addShoppingTransaction({
    required String memberId,
    required String memberName,
    required double amount,
    required String description,
  }) async {
    final docRef = await FirebaseFirestore.instance.collection('transactions').add({
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'type': 'expense',
      'category': 'shopping',
      'title': 'Shopping Expense',
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update member balance
    await FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .update({
      'balance': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  static Future<String> addSavingsTransaction({
    required String memberId,
    required String memberName,
    required double amount,
    required String description,
  }) async {
    final docRef = await FirebaseFirestore.instance.collection('transactions').add({
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'type': 'income',
      'category': 'savings',
      'title': 'Savings Deposit',
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update member balance
    await FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .update({
      'balance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  static Future<String> addExtraTransaction({
    required String memberId,
    required String memberName,
    required double amount,
    required String description,
  }) async {
    final docRef = await FirebaseFirestore.instance.collection('transactions').add({
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'type': 'expense',
      'category': 'extra',
      'title': description,
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update member balance
    await FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .update({
      'balance': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  static Future<void> addTransaction(
    String title,
    double amount,
    String category,
    String memberName,
    String description,
  ) async {
    final transaction = MessTransaction(
      id: '',
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: category == 'savings' || category == 'deposit' ? 'income' : 'expense',
      category: category,
      memberName: memberName,
      description: description,
      icon: Icons.attach_money,
    );

    await FirebaseFirestore.instance
        .collection('transactions')
        .add(transaction.toMap());
  }

  static Future<String> addMealTransaction({
    required String memberId,
    required String memberName,
    required double amount,
    required int mealCount,
    required int breakfastCount,
    required String description,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
    
    // Create meal transaction
    final transactionData = {
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'type': 'expense',
      'category': 'meal',
      'title': 'Meal Expense',
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'mealCount': mealCount,
      'breakfastCount': breakfastCount,
    };
    
    batch.set(transactionRef, transactionData);

    // Update member's meal counts
    final memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
    batch.update(memberRef, {
      'balance': FieldValue.increment(-amount),
      'totalMeals': FieldValue.increment(mealCount),
      'totalBreakfasts': FieldValue.increment(breakfastCount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return transactionRef.id;
  }

  static Stream<Map<String, dynamic>> getMealSummary() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('category', isEqualTo: 'meal')
        .snapshots()
        .map((snapshot) {
      final Map<String, dynamic> summary = {
        'currentMonth': <String, dynamic>{
          'mealCount': 0,
          'guestMealCount': 0,
          'breakfastCount': 0,
          'guestBreakfastCount': 0,
          'totalExpense': 0.0,
          'mealRate': 0.0,
          'breakfastRate': 0.0,
        },
        'allTime': <String, dynamic>{
          'mealCount': 0,
          'guestMealCount': 0,
          'breakfastCount': 0,
          'guestBreakfastCount': 0,
          'totalExpense': 0.0,
          'mealRate': 0.0,
          'breakfastRate': 0.0,
        },
        'monthlyData': <String, Map<String, dynamic>>{},
      };

      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final mealData = data['mealData'] as Map<String, dynamic>;
          final amount = (data['amount'] as num).toDouble();
          final month = mealData['month'] as int;
          final year = mealData['year'] as int;

          // Update all-time statistics
          _updateSummarySection(summary['allTime'] as Map<String, dynamic>, mealData, amount);

          // Update current month statistics
          if (month == currentMonth && year == currentYear) {
            _updateSummarySection(summary['currentMonth'] as Map<String, dynamic>, mealData, amount);
          }

          // Update monthly breakdown
          final monthKey = '$year-${month.toString().padLeft(2, '0')}';
          if (!(summary['monthlyData'] as Map<String, dynamic>).containsKey(monthKey)) {
            (summary['monthlyData'] as Map<String, dynamic>)[monthKey] = {
              'mealCount': 0,
              'guestMealCount': 0,
              'breakfastCount': 0,
              'guestBreakfastCount': 0,
              'totalExpense': 0.0,
              'mealRate': 0.0,
              'breakfastRate': 0.0,
            };
          }
          
          _updateSummarySection(
            (summary['monthlyData'] as Map<String, dynamic>)[monthKey] as Map<String, dynamic>,
            mealData,
            amount,
          );

        } catch (e) {
          print('Error processing meal transaction: $e');
        }
      }

      // Calculate rates for all sections
      _calculateRates(summary['allTime'] as Map<String, dynamic>);
      _calculateRates(summary['currentMonth'] as Map<String, dynamic>);
      (summary['monthlyData'] as Map<String, dynamic>).forEach((key, data) {
        _calculateRates(data as Map<String, dynamic>);
      });

      return summary;
    });
  }

  static void _updateSummarySection(
    Map<String, dynamic> section,
    Map<String, dynamic> mealData,
    double amount,
  ) {
    // Helper function to safely get int values
    int getIntValue(Map<String, dynamic> map, String key) {
      return (map[key] as num?)?.toInt() ?? 0;
    }

    // Update counts
    section['mealCount'] = getIntValue(section, 'mealCount') + 
                          getIntValue(mealData, 'mealCount');
    
    section['guestMealCount'] = getIntValue(section, 'guestMealCount') + 
                               getIntValue(mealData, 'guestMealCount');
    
    section['breakfastCount'] = getIntValue(section, 'breakfastCount') + 
                               getIntValue(mealData, 'breakfastCount');
    
    section['guestBreakfastCount'] = getIntValue(section, 'guestBreakfastCount') + 
                                    getIntValue(mealData, 'guestBreakfastCount');
    
    // Update expense
    section['totalExpense'] = (section['totalExpense'] as num?)?.toDouble() ?? 0.0 + amount;
  }

  static void _calculateRates(Map<String, dynamic> section) {
    final totalMeals = (section['mealCount'] as num?)?.toInt() ?? 0 +
                       (section['guestMealCount'] as num?)?.toInt() ?? 0;
    
    final totalBreakfasts = (section['breakfastCount'] as num?)?.toInt() ?? 0 +
                           (section['guestBreakfastCount'] as num?)?.toInt() ?? 0;
    
    final totalExpense = (section['totalExpense'] as num?)?.toDouble() ?? 0.0;

    // Calculate meal rate
    section['mealRate'] = totalMeals > 0 ? totalExpense / totalMeals : 0.0;
    
    // Calculate breakfast rate (fixed at 8.0)
    section['breakfastRate'] = 8.0;
  }
} 