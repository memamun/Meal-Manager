class ShoppingEntry {
  final String id;
  final String memberId;
  final String shopperName;
  final double cost;
  final DateTime date;

  ShoppingEntry({
    required this.id,
    required this.memberId,
    required this.shopperName,
    required this.cost,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'shopperName': shopperName,
      'cost': cost,
      'date': date.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
} 