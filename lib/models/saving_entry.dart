import 'package:cloud_firestore/cloud_firestore.dart';

class SavingEntry {
  final String id;
  final String memberName;
  final double amount;
  final DateTime date;

  SavingEntry({
    required this.id,
    required this.memberName,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberName': memberName,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
} 