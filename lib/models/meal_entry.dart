import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  final String id;
  final String memberId;
  final DateTime date;
  final int mealCount;
  final bool hasBreakfast;
  final int guestMealCount;
  final int guestBreakfastCount;

  MealEntry({
    required this.id,
    required this.memberId,
    required this.date,
    required this.mealCount,
    required this.hasBreakfast,
    this.guestMealCount = 0,
    this.guestBreakfastCount = 0,
  }) : assert(mealCount >= 0, 'Meal count must be non-negative');

  factory MealEntry.fromMap(String id, Map<String, dynamic> map) {
    return MealEntry(
      id: id,
      memberId: map['memberId'] as String,
      date: DateTime.parse(map['date']),
      mealCount: (map['mealCount'] as num?)?.toInt() ?? 0,
      hasBreakfast: map['hasBreakfast'] as bool? ?? false,
      guestMealCount: (map['guestMealCount'] as num?)?.toInt() ?? 0,
      guestBreakfastCount: (map['guestBreakfastCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'date': date.toIso8601String(),
      'mealCount': mealCount,
      'hasBreakfast': hasBreakfast,
      'guestMealCount': guestMealCount,
      'guestBreakfastCount': guestBreakfastCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
} 