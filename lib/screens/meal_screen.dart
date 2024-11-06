import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meal/screens/member_details_screen.dart';
import 'package:rxdart/rxdart.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  String _sortBy = 'name';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Meal Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.sort_rounded,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              onSelected: (value) => setState(() => _sortBy = value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 22),
                      SizedBox(width: 12),
                      Text('Sort by Name'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'meals',
                  child: Row(
                    children: [
                      Icon(Icons.restaurant, size: 22),
                      SizedBox(width: 12),
                      Text('Sort by Meals'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'balance',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 22),
                      SizedBox(width: 12),
                      Text('Sort by Balance'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _getCombinedStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    'Loading data...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final totalMeals = data['totalMeals'] as int;
          final totalBreakfasts = data['totalBreakfasts'] as int;
          final mealRate = data['mealRate'] as double;
          final breakfastCost = data['breakfastCost'] as double;
          final members = data['members'] as List<DocumentSnapshot>;
          final memberSavings = data['memberSavings'] as Map<String, double>;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Meals',
                        totalMeals.toString(),
                        Icons.restaurant_rounded,
                        Colors.orange,
                        'Rate: ৳${mealRate.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Breakfasts',
                        totalBreakfasts.toString(),
                        Icons.free_breakfast_rounded,
                        Colors.brown,
                        'Cost: ৳${breakfastCost.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _buildMembersList(members, memberSavings, mealRate),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<Map<String, dynamic>> _getCombinedStream() {
    return Rx.combineLatest4(
      FirebaseFirestore.instance.collection('members').snapshots(),
      FirebaseFirestore.instance.collection('shopping').snapshots(),
      FirebaseFirestore.instance.collection('extra').snapshots(),
      FirebaseFirestore.instance.collection('savings').snapshots(),
      (membersSnapshot, shoppingSnapshot, extraSnapshot, savingsSnapshot) {
        int totalMeals = 0;
        int totalBreakfasts = 0;
        double totalExpenses = 0.0;
        Map<String, double> memberSavings = {};

        final members = membersSnapshot.docs;
        for (var doc in members) {
          final data = doc.data() as Map<String, dynamic>;
          totalMeals += (data['totalMeals'] as num?)?.toInt() ?? 0;
          totalBreakfasts += (data['totalBreakfasts'] as num?)?.toInt() ?? 0;
        }

        final double totalBreakfastCost = totalBreakfasts * 8.0;

        for (var doc in shoppingSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalExpenses += (data['cost'] as num?)?.toDouble() ?? 0.0;
        }
        for (var doc in extraSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalExpenses += (data['cost'] as num?)?.toDouble() ?? 0.0;
        }

        final double mealOnlyExpenses = totalExpenses - totalBreakfastCost;
        final double mealRate = totalMeals > 0 ? mealOnlyExpenses / totalMeals : 0.0;

        for (var doc in savingsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['memberName'] as String? ?? '';
          if (name.isNotEmpty) {
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            memberSavings[name] = (memberSavings[name] ?? 0.0) + amount;
          }
        }

        return {
          'totalMeals': totalMeals,
          'totalBreakfasts': totalBreakfasts,
          'totalExpenses': totalExpenses,
          'mealOnlyExpenses': mealOnlyExpenses,
          'breakfastCost': totalBreakfastCost,
          'mealRate': mealRate,
          'members': members,
          'memberSavings': memberSavings,
        };
      },
    );
  }

  Widget _buildMembersList(
    List<DocumentSnapshot> members,
    Map<String, double> memberSavings,
    double mealRate
  ) {
    if (_sortBy == 'meals') {
      members.sort((a, b) {
        final aMeals = (a.data() as Map<String, dynamic>)['totalMeals'] as num;
        final bMeals = (b.data() as Map<String, dynamic>)['totalMeals'] as num;
        return bMeals.compareTo(aMeals);
      });
    } else if (_sortBy == 'balance') {
      members.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aBalance = _calculateBalance(aData, memberSavings[aData['name']] ?? 0, mealRate);
        final bBalance = _calculateBalance(bData, memberSavings[bData['name']] ?? 0, mealRate);
        return bBalance.compareTo(aBalance);
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: members.length,
      itemBuilder: (context, index) => _buildMemberCard(
        members[index],
        memberSavings,
        mealRate,
      ),
    );
  }

  double _calculateBalance(
    Map<String, dynamic> memberData,
    double savings,
    double mealRate
  ) {
    final totalMeals = memberData['totalMeals'] as num;
    final totalBreakfasts = (memberData['totalBreakfasts'] ?? 0) as int;
    final mealCost = totalMeals * mealRate;
    final breakfastCost = totalBreakfasts * 8.0;
    return savings - (mealCost + breakfastCost);
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    DocumentSnapshot memberSnapshot,
    Map<String, double> memberSavings,
    double mealRate
  ) {
    final memberData = memberSnapshot.data() as Map<String, dynamic>;
    final name = memberData['name'] as String? ?? 'Unknown';
    final totalMeals = (memberData['totalMeals'] as num?)?.toInt() ?? 0;
    final totalBreakfasts = (memberData['totalBreakfasts'] as num?)?.toInt() ?? 0;
    
    final double mealCost = totalMeals * mealRate;
    final double breakfastCost = totalBreakfasts * 8.0;
    final double totalCost = mealCost + breakfastCost;
    final double savings = memberSavings[name] ?? 0.0;
    final double balance = savings - totalCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberDetailsScreen(
                memberId: memberSnapshot.id,
                memberName: name,
                mealRate: mealRate,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name[0],
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalMeals meals',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.free_breakfast,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalBreakfasts breakfasts',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      'Balance',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}