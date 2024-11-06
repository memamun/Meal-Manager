import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ShoppingHistoryScreen extends StatefulWidget {
  final Function(DocumentSnapshot) onEdit;

  const ShoppingHistoryScreen({
    super.key,
    required this.onEdit,
  });

  @override
  State<ShoppingHistoryScreen> createState() => _ShoppingHistoryScreenState();
}

class _ShoppingHistoryScreenState extends State<ShoppingHistoryScreen> {
  String _sortBy = 'date';
  bool _ascending = false;

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

  Query<Map<String, dynamic>> _getQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('shopping');
    
    switch (_sortBy) {
      case 'date':
        query = query.orderBy('date', descending: !_ascending);
        break;
      case 'cost':
        query = query.orderBy('cost', descending: !_ascending);
        break;
      case 'shopper':
        query = query.orderBy('shopperName', descending: !_ascending);
        break;
    }
    
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sort Options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                // Sort Options
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SortChip(
                          label: 'Date',
                          selected: _sortBy == 'date',
                          ascending: _ascending,
                          onSelected: () => setState(() {
                            if (_sortBy == 'date') {
                              _ascending = !_ascending;
                            } else {
                              _sortBy = 'date';
                              _ascending = false;
                            }
                          }),
                        ),
                        const SizedBox(width: 8),
                        _SortChip(
                          label: 'Amount',
                          selected: _sortBy == 'cost',
                          ascending: _ascending,
                          onSelected: () => setState(() {
                            if (_sortBy == 'cost') {
                              _ascending = !_ascending;
                            } else {
                              _sortBy = 'cost';
                              _ascending = false;
                            }
                          }),
                        ),
                        const SizedBox(width: 8),
                        _SortChip(
                          label: 'Shopper',
                          selected: _sortBy == 'shopper',
                          ascending: _ascending,
                          onSelected: () => setState(() {
                            if (_sortBy == 'shopper') {
                              _ascending = !_ascending;
                            } else {
                              _sortBy = 'shopper';
                              _ascending = false;
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        child: const Icon(Icons.delete_outline_rounded, 
                          color: Color(0xFFFF3B30), 
                          size: 28
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Shopping Entry'),
                            content: const Text('Are you sure you want to delete this shopping entry?'),
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
                          onTap: () => widget.onEdit(doc),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, 
                                    vertical: 8
                                  ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool ascending;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.ascending,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF6B4EFF) : Colors.grey[700],
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 4),
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: const Color(0xFF6B4EFF),
            ),
          ],
        ],
      ),
      backgroundColor: selected 
        ? const Color(0xFF6B4EFF).withOpacity(0.1)
        : Colors.grey[200],
      side: selected
        ? BorderSide(color: const Color(0xFF6B4EFF).withOpacity(0.5))
        : null,
      onPressed: onSelected,
    );
  }
} 