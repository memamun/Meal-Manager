import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:meal/screens/savings_history_screen.dart';
import 'package:meal/models/transaction.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _addFormKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
  String? _selectedMember;
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  
  // Add stream for members
  Stream<List<String>> _getMembersStream() {
    return FirebaseFirestore.instance
        .collection('members')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList());
  }

  // Update the member dropdown to use StreamBuilder
  Widget _buildMemberDropdown({
    String? value,
    required Function(String?) onChanged,
    String labelText = 'Member',
  }) {
    return StreamBuilder<List<String>>(
      stream: _getMembersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final members = snapshot.data!;
        
        return DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          items: members.map((member) {
            return DropdownMenuItem(value: member, child: Text(member));
          }).toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? 'Please select a member' : null,
        );
      },
    );
  }

  // Add this method to calculate member savings
  void _showMemberSavings() {
    Map<String, double> memberSavings = {};
    
    // Use StreamBuilder to get members
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<String>>(
        stream: _getMembersStream(),
        builder: (context, membersSnapshot) {
          if (!membersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.savings, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Member Savings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Member List
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: membersSnapshot.data!.map((member) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Text(
                                  member[0],
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  member,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '৳ ${(memberSavings[member] ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Close'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings'),
        actions: [
          IconButton(
            onPressed: _showMemberSavings,
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Member Statistics',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Add Savings Form Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _addFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.savings,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add New Savings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Form Fields
                          _buildMemberDropdown(
                            value: _selectedMember,
                            onChanged: (value) => setState(() => _selectedMember = value),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '৳ ',
                              prefixIcon: const Icon(Icons.account_balance_wallet),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter the amount';
                              if (double.tryParse(value!) == null) return 'Please enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2025),
                              );
                              if (date != null) setState(() => _selectedDate = date);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMMM dd, yyyy').format(_selectedDate),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _handleSubmit,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Savings'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Savings History Section
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('savings')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Calculate total savings
                    double totalSavings = 0;
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalSavings += (data['amount'] as num).toDouble();
                    }

                    return Column(
                      children: [
                        // Total Savings Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Savings',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '৳ ${totalSavings.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Recent Transactions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SavingsHistoryScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            
                            // Last 3 transactions
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length > 3 ? 3 : snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final doc = snapshot.data!.docs[index];
                                final entry = doc.data() as Map<String, dynamic>;
                                final date = DateTime.parse(entry['date']);

                                return Dismissible(
                                  key: Key(doc.id),
                                  background: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE5E5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30), size: 28),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) {
                                    return showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Saving Entry'),
                                        content: const Text('Are you sure you want to delete this saving entry?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) => _handleDelete(doc, entry),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                        child: Text(
                                          entry['memberName'][0],
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        entry['memberName'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        DateFormat('MMMM dd, yyyy').format(date),
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      trailing: Text(
                                        '৳ ${(entry['amount'] as num).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      onTap: () => _showEditDialog(doc),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this to your drawer items:
  // ListTile(
  //   leading: const Icon(Icons.savings),
  //   title: const Text('Savings'),
  //   onTap: () {
  //     Navigator.pop(context);
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => const SavingsScreen()),
  //     );
  //   },
  // ),

  Future<String?> getMemberId(String memberName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('members')
        .where('name', isEqualTo: memberName)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_addFormKey.currentState!.validate() && _selectedMember != null) {
      try {
        final memberId = await getMemberId(_selectedMember!);
        if (memberId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member not found')),
            );
          }
          return;
        }

        // First create the transaction
        final transactionId = await MessTransaction.addSavingsTransaction(
          memberId: memberId,
          memberName: _selectedMember!,
          amount: double.parse(_amountController.text),
          description: 'Savings deposit',
        );

        // Then add the savings entry
        await FirebaseFirestore.instance.collection('savings').add({
          'memberName': _selectedMember,
          'amount': double.parse(_amountController.text),
          'date': _selectedDate.toIso8601String(),
          'transactionId': transactionId, // Store the transaction ID for reference
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _resetForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Savings added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding savings: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    _amountController.clear();
    setState(() {
      _selectedMember = null;
      _selectedDate = DateTime.now();
    });
  }

  void _showEditDialog(DocumentSnapshot doc) {
    final entry = doc.data() as Map<String, dynamic>;
    final editAmountController = TextEditingController(
      text: (entry['amount'] as num).toString(),
    );
    String? editSelectedMember = entry['memberName'];
    DateTime editSelectedDate = DateTime.parse(entry['date']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Saving Entry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _editFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMemberDropdown(
                      value: editSelectedMember,
                      onChanged: (value) => editSelectedMember = value,
                      labelText: 'Paid By',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editAmountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '৳ ',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter the amount';
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: editSelectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2025),
                        );
                        if (date != null) editSelectedDate = date;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, 
                              color: Theme.of(context).primaryColor),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMMM dd, yyyy').format(editSelectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (_editFormKey.currentState!.validate()) {
                          try {
                            await doc.reference.update({
                              'memberName': editSelectedMember,
                              'amount': double.parse(editAmountController.text),
                              'date': editSelectedDate.toIso8601String(),
                            });
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saving entry updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating saving entry: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Update'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(DocumentSnapshot doc, Map<String, dynamic> entry) async {
    try {
      // Get the transaction ID from the savings entry
      final transactionId = entry['transactionId'];
      
      // Create a batch write
      final batch = FirebaseFirestore.instance.batch();
      
      // Delete the savings entry
      batch.delete(doc.reference);
      
      // Delete the corresponding transaction if it exists
      if (transactionId != null) {
        final transactionRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc(transactionId);
        batch.delete(transactionRef);

        // Update member balance
        final memberId = await getMemberId(entry['memberName']);
        if (memberId != null) {
          final memberRef = FirebaseFirestore.instance
              .collection('members')
              .doc(memberId);
          batch.update(memberRef, {
            'balance': FieldValue.increment(-(entry['amount'] as num).toDouble()), // Subtract the amount
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Commit the batch
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving entry deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
} 