import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meal/screens/shopping_screen.dart';
import 'package:meal/screens/extra_screen.dart';
import 'package:meal/screens/savings_screen.dart';
import 'package:meal/screens/meal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final members = [
    'Sajeb',
    'Nahid',
    'Mamun',
    'Rakib',
    'Mostakim',
    'Ferose',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Mess Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Meals'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Shopping'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShoppingScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Extra Costs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExtraScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Savings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      'Total Members',
                      '6',
                      Icons.group,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('members').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        
                        int totalMeals = 0;
                        for (var doc in snapshot.data!.docs) {
                          final memberData = doc.data() as Map<String, dynamic>;
                          totalMeals += (memberData['totalMeals'] as num).toInt();
                        }
                        
                        return _buildQuickStatCard(
                          'Total Meals',
                          '$totalMeals',
                          Icons.restaurant,
                          Colors.orange,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // New row for Meal Rate
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('members').snapshots(),
                      builder: (context, mealsSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('shopping').snapshots(),
                          builder: (context, shoppingSnapshot) {
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('extra').snapshots(),
                              builder: (context, extraSnapshot) {
                                if (!mealsSnapshot.hasData || 
                                    !shoppingSnapshot.hasData || 
                                    !extraSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                // Calculate total meals and breakfasts
                                int totalMeals = 0;
                                int totalBreakfasts = 0;
                                for (var doc in mealsSnapshot.data!.docs) {
                                  final memberData = doc.data() as Map<String, dynamic>;
                                  totalMeals += (memberData['totalMeals'] as num).toInt();
                                  totalBreakfasts += (memberData['totalBreakfasts'] ?? 0) as int;
                                }

                                // Calculate total breakfast cost
                                final totalBreakfastCost = totalBreakfasts * 8.0;

                                // Calculate total expenses
                                double totalExpenses = 0;
                                for (var doc in shoppingSnapshot.data!.docs) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  totalExpenses += (data['cost'] as num).toDouble();
                                }
                                for (var doc in extraSnapshot.data!.docs) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  totalExpenses += (data['cost'] as num).toDouble();
                                }

                                // Calculate meal rate (excluding breakfast costs)
                                final mealOnlyExpenses = totalExpenses - totalBreakfastCost;
                                final mealRate = totalMeals > 0 ? mealOnlyExpenses / totalMeals : 0;

                                return _buildQuickStatCard(
                                  'Meal Rate',
                                  '৳ ${mealRate.toStringAsFixed(2)}',
                                  Icons.calculate,
                                  Colors.green,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Financial Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('savings').snapshots(),
                        builder: (context, savingsSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('shopping').snapshots(),
                            builder: (context, shoppingSnapshot) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('extra').snapshots(),
                                builder: (context, extraSnapshot) {
                                  if (!savingsSnapshot.hasData || 
                                      !shoppingSnapshot.hasData || 
                                      !extraSnapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }

                                  double totalSavings = 0;
                                  for (var doc in savingsSnapshot.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    totalSavings += (data['amount'] as num).toDouble();
                                  }

                                  double totalExpenses = 0;
                                  for (var doc in shoppingSnapshot.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    totalExpenses += (data['cost'] as num).toDouble();
                                  }
                                  for (var doc in extraSnapshot.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    totalExpenses += (data['cost'] as num).toDouble();
                                  }

                                  final balance = totalSavings - totalExpenses;

                                  return Column(
                                    children: [
                                      _buildFinancialRow(
                                        'Total Savings',
                                        totalSavings,
                                        Icons.savings,
                                        Colors.blue,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildFinancialRow(
                                        'Total Expenses',
                                        totalExpenses,
                                        Icons.shopping_cart,
                                        Colors.orange,
                                      ),
                                      const Divider(),
                                      _buildFinancialRow(
                                        'Balance',
                                        balance,
                                        Icons.account_balance_wallet,
                                        balance >= 0 ? Colors.green : Colors.red,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String title, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title),
        const Spacer(),
        Text(
          '৳ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
} 