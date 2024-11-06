import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:meal/screens/extra_history_screen.dart';
import 'package:meal/models/transaction.dart';

class ExtraScreen extends StatefulWidget {
  const ExtraScreen({super.key});

  @override
  State<ExtraScreen> createState() => _ExtraScreenState();
}

class _ExtraScreenState extends State<ExtraScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMember;
  DateTime _selectedDate = DateTime.now();
  final _costController = TextEditingController();
  final _itemNameController = TextEditingController();
  
  final _editFormKey = GlobalKey<FormState>();
  String? _editSelectedMember;
  DateTime _editSelectedDate = DateTime.now();
  final _editCostController = TextEditingController();
  final _editItemNameController = TextEditingController();

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
            labelText: 'Member',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: members.map((member) {
            return DropdownMenuItem(value: member, child: Text(member));
          }).toList(),
          onChanged: (value) => setState(() => _selectedMember = value),
          validator: (value) => value == null ? 'Please select a member' : null,
        );
      },
    );
  }

  void _showEditDialog(DocumentSnapshot doc) {
    final entry = doc.data() as Map<String, dynamic>;
    _editSelectedMember = entry['shopperName'];
    _editSelectedDate = DateTime.parse(entry['date']);
    _editCostController.text = entry['cost'].toString();
    _editItemNameController.text = entry['itemName'];

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
                    'Edit Extra Cost',
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

                        return DropdownButtonFormField<String>(
                          value: _editSelectedMember,
                          decoration: const InputDecoration(
                            labelText: 'Paid By',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: snapshot.data!.map((member) {
                            return DropdownMenuItem(value: member, child: Text(member));
                          }).toList(),
                          onChanged: (value) => setState(() => _editSelectedMember = value),
                          validator: (value) =>
                              value == null ? 'Please select a member' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _editItemNameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _editCostController,
                      decoration: const InputDecoration(
                        labelText: 'Cost',
                        prefixText: '৳ ',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter the cost';
                        if (double.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(DateFormat('MMMM dd, yyyy').format(_editSelectedDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _editSelectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2025),
                        );
                        if (date != null) {
                          setState(() => _editSelectedDate = date);
                        }
                      },
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
                                    'itemName': _editItemNameController.text,
                                    'cost': double.parse(_editCostController.text),
                                    'date': _editSelectedDate.toIso8601String(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Extra cost updated successfully'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error updating extra cost: $e'),
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
        title: const Text('Extra Expenses'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 
                    AppBar().preferredSize.height - 
                    MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                // Add Extra Cost Form
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
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
                                    Icons.add_card,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Add New Expense',
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
                              controller: _itemNameController,
                              decoration: InputDecoration(
                                labelText: 'Item Name',
                                prefixIcon: const Icon(Icons.shopping_bag),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'Please enter the item name' : null,
                            ),
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
                              onPressed: _handleExtraSubmit,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Extra Cost'),
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
                ),

                // Extra Costs History
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('extra')
                        .orderBy('date', descending: true)
                        .limit(2)
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
                                  'Recent Expenses',
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
                                        builder: (context) => ExtraHistoryScreen(
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
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: Icon(Icons.delete, color: Colors.red.shade700),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Expense'),
                                        content: const Text('Are you sure you want to delete this expense?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    try {
                                      await doc.reference.delete();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Expense deleted successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error deleting expense: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
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
                                          entry['shopperName'][0],
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        entry['itemName'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Paid by: ${entry['shopperName']}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                          Text(
                                            DateFormat('MMMM dd, yyyy').format(date),
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        '৳ ${entry['cost'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                      onTap: () => _showEditDialog(doc),
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
          ),
        ),
      ),
    );
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

  Future<void> _handleExtraSubmit() async {
    if (_formKey.currentState!.validate() && _selectedMember != null) {
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
        final transactionId = await MessTransaction.addExtraTransaction(
          memberId: memberId,
          memberName: _selectedMember!,
          amount: double.parse(_costController.text),
          description: _itemNameController.text,
        );

        // Then add the extra entry
        await FirebaseFirestore.instance.collection('extra').add({
          'shopperName': _selectedMember,
          'itemName': _itemNameController.text,
          'cost': double.parse(_costController.text),
          'date': _selectedDate.toIso8601String(),
          'transactionId': transactionId, // Store the transaction ID for reference
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _resetForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Extra cost added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding extra cost: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    _costController.clear();
    _itemNameController.clear();
    setState(() {
      _selectedMember = null;
      _selectedDate = DateTime.now();
    });
  }
} 