import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  final String id;
  final String memberId;
  final DateTime date;
  final int regularMeals;
  final int guestMeals;
  final bool hasBreakfast;
  final int guestBreakfast;
  final double mealRate;
  final double breakfastRate;

  MealEntry({
    required this.id,
    required this.memberId,
    required this.date,
    this.regularMeals = 0,
    this.guestMeals = 0,
    this.hasBreakfast = false,
    this.guestBreakfast = 0,
    this.mealRate = 0.0,
    this.breakfastRate = 8.0, // Default breakfast rate
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'date': date.toIso8601String(),
      'regularMeals': regularMeals,
      'guestMeals': guestMeals,
      'hasBreakfast': hasBreakfast,
      'guestBreakfast': guestBreakfast,
      'mealRate': mealRate,
      'breakfastRate': breakfastRate,
      'totalCost': calculateTotalCost(),
      'createdAt': FieldValue.serverTimestamp(),
      'month': date.month,
      'year': date.year,
    };
  }

  double calculateTotalCost() {
    return (regularMeals + guestMeals) * mealRate +
           ((hasBreakfast ? 1 : 0) + guestBreakfast) * breakfastRate;
  }

  static MealEntry fromMap(String id, Map<String, dynamic> map) {
    return MealEntry(
      id: id,
      memberId: map['memberId'],
      date: DateTime.parse(map['date']),
      regularMeals: map['regularMeals'] ?? 0,
      guestMeals: map['guestMeals'] ?? 0,
      hasBreakfast: map['hasBreakfast'] ?? false,
      guestBreakfast: map['guestBreakfast'] ?? 0,
      mealRate: (map['mealRate'] as num?)?.toDouble() ?? 0.0,
      breakfastRate: (map['breakfastRate'] as num?)?.toDouble() ?? 8.0,
    );
  }
} 