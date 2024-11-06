import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SavingsHistoryScreen extends StatefulWidget {
  const SavingsHistoryScreen({super.key});

  @override
  State<SavingsHistoryScreen> createState() => _SavingsHistoryScreenState();
}

class _SavingsHistoryScreenState extends State<SavingsHistoryScreen> {
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
            'balance': FieldValue.increment(-(entry['amount'] as num).toDouble()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('savings')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final entry = doc.data() as Map<String, dynamic>;
              final date = DateTime.parse(entry['date']);

              return Dismissible(
                key: Key(doc.id),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 