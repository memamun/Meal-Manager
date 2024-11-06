import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:meal/screens/shopping_history_screen.dart';
import 'package:meal/models/transaction.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _addFormKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
  String? _selectedMember;
  DateTime _selectedDate = DateTime.now();
  final _costController = TextEditingController();
  
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
  Widget _buildMemberDropdown() {
    return StreamBuilder<List<String>>(
      stream: _getMembersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final members = snapshot.data!;
        
        return DropdownButtonFormField<String>(
          value: _selectedMember,
          decoration: InputDecoration(
            labelText: 'Shopper',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: members.map((member) {
            return DropdownMenuItem(value: member, child: Text(member));
          }).toList(),
          onChanged: (value) => setState(() => _selectedMember = value),
          validator: (value) => value == null ? 'Please select a shopper' : null,
        );
      },
    );
  }

  String? _editSelectedMember;
  DateTime _editSelectedDate = DateTime.now();
  final _editCostController = TextEditingController();

  void _showEditDialog(DocumentSnapshot doc) {
    final entry = doc.data() as Map<String, dynamic>;
    _editSelectedMember = entry['shopperName'];
    _editSelectedDate = DateTime.parse(entry['date']);
    _editCostController.text = entry['cost'].toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Shopping',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _editFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreamBuilder<List<String>>(
                      stream: _getMembersStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final members = snapshot.data!;
                        
                        return DropdownButtonFormField<String>(
                          value: _editSelectedMember,
                          decoration: InputDecoration(
                            labelText: 'Shopper',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: members.map((member) {
                            return DropdownMenuItem(value: member, child: Text(member));
                          }).toList(),
                          onChanged: (value) => setState(() => _editSelectedMember = value),
                          validator: (value) => value == null ? 'Please select a shopper' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _editCostController,
                      decoration: InputDecoration(
                        labelText: 'Cost',
                        prefixText: '৳ ',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _editSelectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2025),
                        );
                        if (date != null) setState(() => _editSelectedDate = date);
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
                                  DateFormat('MMMM dd, yyyy').format(_editSelectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
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
                                    'shopperName': _editSelectedMember,
                                    'cost': double.parse(_editCostController.text),
                                    'date': _editSelectedDate.toIso8601String(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Shopping entry updated successfully'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                    _editCostController.clear();
                                  }
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error updating entry: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Expenses'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add Shopping Form
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
                            Icons.shopping_cart,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add New Shopping',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Form Fields
                    _buildMemberDropdown(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(
                        labelText: 'Cost',
                        prefixText: '৳ ',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter the cost';
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
                      onPressed: _submitForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Shopping'),
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

          // Shopping History
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shopping')
                  .orderBy('date', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    // Header with View All button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Shopping',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShoppingHistoryScreen(
                                    onEdit: _showEditDialog,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history),
                            label: const Text('View All'),
                          ),
                        ],
                      ),
                    ),

                    // Recent transactions list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final entry = doc.data() as Map<String, dynamic>;
                          final date = DateTime.parse(entry['date']);

                          return Dismissible(
                            key: Key(doc.id),
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE5E5),
                                borderRadius: BorderRadius.circular(16),
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
                                  title: const Text('Delete Shopping Entry'),
                                  content: const Text('Are you sure you want to delete this shopping entry?'),
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
                            onDismissed: (direction) async {
                              try {
                                // Get the transaction ID from the shopping entry
                                final transactionId = entry['transactionId'];
                                
                                // Create a batch write
                                final batch = FirebaseFirestore.instance.batch();
                                
                                // Delete the shopping entry
                                batch.delete(doc.reference);
                                
                                // Delete the corresponding transaction if it exists
                                if (transactionId != null) {
                                  final transactionRef = FirebaseFirestore.instance
                                      .collection('transactions')
                                      .doc(transactionId);
                                  batch.delete(transactionRef);

                                  // Update member balance
                                  final memberId = await getMemberId(entry['shopperName']);
                                  if (memberId != null) {
                                    final memberRef = FirebaseFirestore.instance
                                        .collection('members')
                                        .doc(memberId);
                                    batch.update(memberRef, {
                                      'balance': FieldValue.increment(entry['cost']), // Add back the amount
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });
                                  }
                                }

                                // Commit the batch
                                await batch.commit();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Shopping entry deleted successfully'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error deleting entry: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                onTap: () => _showEditDialog(doc),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Date Bubble
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6B4EFF).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              DateFormat('dd').format(date),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Color(0xFF6B4EFF),
                                              ),
                                            ),
                                            Text(
                                              DateFormat('MMM').format(date).toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF6B4EFF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry['shopperName'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              DateFormat('MMMM dd, yyyy').format(date),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Amount
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF4D6D).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '৳ ${entry['cost'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFFFF4D6D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_addFormKey.currentState!.validate()) {
      try {
        final cost = double.parse(_costController.text);
        
        // Add to transactions first
        final memberId = await getMemberId(_selectedMember!);
        if (memberId == null) {
          throw Exception('Member not found');
        }

        final transactionId = await MessTransaction.addShoppingTransaction(
          memberId: memberId,
          memberName: _selectedMember!,
          amount: cost,
          description: 'Shopping expenses',
        );

        // Then add to shopping collection with transaction reference
        await FirebaseFirestore.instance.collection('shopping').add({
          'shopperName': _selectedMember,
          'cost': cost,
          'date': _selectedDate.toIso8601String(),
          'transactionId': transactionId, // Store the transaction ID
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shopping entry added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    _costController.clear();
    setState(() {
      _selectedMember = null;
      _selectedDate = DateTime.now();
    });
  }

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
} 