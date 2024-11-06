import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime joinDate;
  final int totalMeals;
  final int totalBreakfasts;
  final int totalGuestMeals;
  final int totalGuestBreakfasts;
  final double balance;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.joinDate,
    required this.totalMeals,
    required this.totalBreakfasts,
    this.totalGuestMeals = 0,
    this.totalGuestBreakfasts = 0,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'joinDate': joinDate.toIso8601String(),
      'totalMeals': totalMeals,
      'totalBreakfasts': totalBreakfasts,
      'totalGuestMeals': totalGuestMeals,
      'totalGuestBreakfasts': totalGuestBreakfasts,
      'balance': balance,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Member.fromMap(String id, Map<String, dynamic> map) {
    return Member(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      joinDate: DateTime.parse(map['joinDate']),
      totalMeals: (map['totalMeals'] as num?)?.toInt() ?? 0,
      totalBreakfasts: (map['totalBreakfasts'] as num?)?.toInt() ?? 0,
      totalGuestMeals: (map['totalGuestMeals'] as num?)?.toInt() ?? 0,
      totalGuestBreakfasts: (map['totalGuestBreakfasts'] as num?)?.toInt() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Update member's balance and create a transaction
  static Future<void> updateBalanceWithTransaction({
    required String memberId,
    required double amount,
    required String category,
    required String description,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Update member balance
    final memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
    batch.update(memberRef, {
      'balance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create transaction
    final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
    batch.set(transactionRef, {
      'memberId': memberId,
      'amount': amount,
      'type': amount >= 0 ? 'income' : 'expense',
      'category': category,
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Update meal counts
  static Future<void> updateMealCounts({
    required String memberId,
    required int meals,
    required int breakfasts,
    required double mealRate,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
    
    // Calculate total cost
    final totalCost = (meals * mealRate) + (breakfasts * (mealRate * 0.5));

    batch.update(memberRef, {
      'totalMeals': FieldValue.increment(meals),
      'totalBreakfasts': FieldValue.increment(breakfasts),
      'balance': FieldValue.increment(-totalCost),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create meal transaction
    final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
    batch.set(transactionRef, {
      'memberId': memberId,
      'amount': totalCost,
      'type': 'expense',
      'category': 'meal',
      'description': 'Meals: $meals, Breakfasts: $breakfasts',
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Get real-time member data
  static Stream<Member> getMember(String memberId) {
    return FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((doc) => Member.fromMap(doc.id, doc.data()!));
  }

  // Get all members
  static Stream<List<Member>> getAllMembers() {
    return FirebaseFirestore.instance
        .collection('members')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get total balance of all members
  static Stream<double> getTotalBalance() {
    return FirebaseFirestore.instance
        .collection('members')
        .snapshots()
        .map((snapshot) {
      double totalBalance = 0;
      for (var doc in snapshot.docs) {
        final balance = (doc.data()['balance'] as num?)?.toDouble() ?? 0;
        totalBalance += balance;
      }
      return totalBalance;
    });
  }

  // Get member statistics
  static Stream<Map<String, dynamic>> getMemberStats(String memberId) {
    return FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((doc) {
      final data = doc.data()!;
      return {
        'totalMeals': data['totalMeals'] ?? 0,
        'totalBreakfasts': data['totalBreakfasts'] ?? 0,
        'balance': data['balance'] ?? 0.0,
      };
    });
  }

  // Delete member and related data
  static Future<void> deleteMember(String memberId) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Delete member
    final memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
    batch.delete(memberRef);

    // Delete related transactions
    final transactionsQuery = await FirebaseFirestore.instance
        .collection('transactions')
        .where('memberId', isEqualTo: memberId)
        .get();
    
    for (var doc in transactionsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete related meals
    final mealsQuery = await FirebaseFirestore.instance
        .collection('meals')
        .where('memberId', isEqualTo: memberId)
        .get();
    
    for (var doc in mealsQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
} 