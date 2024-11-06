import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meal/screens/shopping_screen.dart';
import 'package:meal/screens/savings_screen.dart';
import 'package:meal/screens/meal_screen.dart';
import 'package:meal/screens/extra_screen.dart';
import 'package:meal/screens/transaction_history_screen.dart';
import 'package:meal/models/transaction.dart' show MessTransaction;
import 'package:intl/intl.dart';
import 'package:meal/screens/transaction_detail_screen.dart';
import 'package:meal/screens/member_management_screen.dart';
import 'package:meal/models/member.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Add a stream to get members from Firestore
  Stream<List<String>> _getMembersStream() {
    return FirebaseFirestore.instance
        .collection('members')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList());
  }

  // Add this method to _HomeScreenState class
  Stream<Map<String, dynamic>> _getMealSummaryStream() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('category', isEqualTo: 'meal')
        .snapshots()
        .map((snapshot) {
      double totalMealExpense = 0;
      int totalMeals = 0;
      int totalBreakfasts = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final amount = (data['amount'] as num).toDouble();
          final mealCount = (data['mealCount'] as num?)?.toInt() ?? 0;
          final breakfastCount = (data['breakfastCount'] as num?)?.toInt() ?? 0;

          totalMealExpense += amount;
          totalMeals += mealCount;
          totalBreakfasts += breakfastCount;
        } catch (e) {
          print('Error processing meal transaction: $e');
        }
      }

      // Calculate meal rate
      final double mealRate = totalMeals > 0 ? totalMealExpense / totalMeals : 0.0;

      return {
        'mealRate': mealRate,
        'totalMeals': totalMeals,
        'totalBreakfasts': totalBreakfasts,
        'totalExpense': totalMealExpense,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text('Mess Manager', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          )
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _getMembersStream(),
        builder: (context, membersSnapshot) {
          if (!membersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinancialSummary(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildRecentTransactions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return StreamBuilder<Map<String, double>>(
      stream: MessTransaction.getFinancialSummary(),
      builder: (context, summarySnapshot) {
        return StreamBuilder<double>(
          stream: Member.getTotalBalance(),
          builder: (context, balanceSnapshot) {
            if (!summarySnapshot.hasData && !balanceSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final summary = summarySnapshot.data ?? {
              'income': 0,
              'expenses': 0,
              'shopping': 0,
              'meals': 0,
              'extra': 0,
              'deposits': 0,
            };
            final totalBalance = balanceSnapshot.data ?? 0;
            
            // Calculate percentage change
            final income = summary['income'] ?? 0;
            final expenses = summary['expenses'] ?? 0;
            double percentageChange = 0;
            
            if (expenses > 0) {
              percentageChange = ((income - expenses) / expenses) * 100;
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Financial Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Details'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '৳${totalBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    percentageChange >= 0 ? Icons.trending_up : Icons.trending_down,
                                    color: percentageChange >= 0 ? Colors.greenAccent[100] : Colors.redAccent[100],
                                    size: 16
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${percentageChange.abs().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: percentageChange >= 0 ? Colors.greenAccent[100] : Colors.redAccent[100],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFinancialIndicator(
                                'Income',
                                '+৳${summary['income']?.toStringAsFixed(2)}',
                                Icons.arrow_upward,
                                Colors.green,
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white24,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              child: _buildFinancialIndicator(
                                'Expenses',
                                '-৳${summary['expenses']?.toStringAsFixed(2)}',
                                Icons.arrow_downward,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Shopping',
                          '-৳${summary['shopping']?.toStringAsFixed(2)}',
                          Icons.shopping_bag_rounded,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Meal Rate',
                          '',
                          Icons.restaurant_menu,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Extra',
                          '-৳${summary['extra']?.toStringAsFixed(2)}',
                          Icons.receipt_rounded,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Deposits',
                          '+৳${summary['deposits']?.toStringAsFixed(2)}',
                          Icons.savings_rounded,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFinancialIndicator(String title, String amount, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String amount, IconData icon, Color color) {
    if (title == 'Meal Rate') {
      return StreamBuilder<Map<String, dynamic>>(
        stream: _getMealSummaryStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final mealRate = data['mealRate'] as double;
          final totalMeals = data['totalMeals'] as int;
          final totalBreakfasts = data['totalBreakfasts'] as int;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meal Rate',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Meals: $totalMeals | Breakfast: $totalBreakfasts',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '৳${mealRate.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return MessTransaction.fromMap(doc.id, data);
        }).toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (transactions.isEmpty)
                const Center(
                  child: Text('No recent transactions'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionItem(transaction);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(MessTransaction transaction) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: transaction.type == 'income' ? Colors.green : Colors.red,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: transaction.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.icon,
                color: transaction.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${transaction.type == 'income' ? '+' : '-'}৳${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: transaction.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionButton(
                  'Members',
                  Icons.people_rounded,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MemberManagementScreen()),
                  ),
                ),
                _buildQuickActionButton(
                  'Add Meal',
                  Icons.restaurant_rounded,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MealScreen()),
                  ),
                ),
                _buildQuickActionButton(
                  'Shopping',
                  Icons.shopping_bag_rounded,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShoppingScreen()),
                  ),
                ),
                _buildQuickActionButton(
                  'Extra Cost',
                  Icons.receipt_long_rounded,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExtraScreen()),
                  ),
                ),
                _buildQuickActionButton(
                  'Savings',
                  Icons.savings_rounded,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SavingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 100,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> addTransaction(String title, double amount, String category, String memberName, String description) async {
    try {
      final memberSnapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('name', isEqualTo: memberName)
          .limit(1)
          .get();

      if (memberSnapshot.docs.isEmpty) {
        throw Exception('Member not found');
      }

      final memberId = memberSnapshot.docs.first.id;
      final type = (category.toLowerCase() == 'savings' || 
                   category.toLowerCase() == 'deposit') ? 'income' : 'expense';

      final Map<String, dynamic> transactionData = {
        'title': title,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'type': type,
        'category': category.toLowerCase(),
        'memberName': memberName,
        'description': description,
        'memberId': memberId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add meal count if it's a meal transaction
      if (category.toLowerCase() == 'meal') {
        // Extract meal count from description or set default
        double mealCount = 1.0;  // Default value
        if (description.contains('meals:')) {
          try {
            final countStr = description.split('meals:')[1].trim().split(' ')[0];
            mealCount = double.parse(countStr);
          } catch (e) {
            print('Error parsing meal count: $e');
          }
        }
        transactionData['mealCount'] = mealCount;
      }

      final batch = FirebaseFirestore.instance.batch();
      
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transactionRef, transactionData);

      final memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
      batch.update(memberRef, {
        'balance': FieldValue.increment(type == 'income' ? amount : -amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }
} 