import 'package:cloud_firestore/cloud_firestore.dart';

class ExtraEntry {
  final String id;
  final String shopperName;
  final String itemName;
  final double cost;
  final DateTime date;

  ExtraEntry({
    required this.id,
    required this.shopperName,
    required this.itemName,
    required this.cost,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopperName': shopperName,
      'itemName': itemName,
      'cost': cost,
      'date': date.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
} 