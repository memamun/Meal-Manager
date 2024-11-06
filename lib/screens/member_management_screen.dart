import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import 'member_details_screen.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  void _showAddMemberDialog({bool isEditing = false, String? memberId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Member' : 'Add New Member'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Phone is required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _addMember,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMember() async {
    if (_formKey.currentState!.validate()) {
      try {
        final member = Member(
          id: '',
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          joinDate: DateTime.now(),
          totalMeals: 0,
          totalBreakfasts: 0,
          totalGuestMeals: 0,
          totalGuestBreakfasts: 0,
          balance: 0.0,
        );

        await FirebaseFirestore.instance
            .collection('members')
            .add(member.toMap());

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding member: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateMember(String memberId) async {
    if (_formKey.currentState!.validate()) {
      try {
        final memberDoc = await FirebaseFirestore.instance
            .collection('members')
            .doc(memberId)
            .get();
        
        final currentData = memberDoc.data()!;
        
        final member = Member(
          id: memberId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          joinDate: DateTime.parse(currentData['joinDate']),
          totalMeals: currentData['totalMeals'] ?? 0,
          totalBreakfasts: currentData['totalBreakfasts'] ?? 0,
          totalGuestMeals: currentData['totalGuestMeals'] ?? 0,
          totalGuestBreakfasts: currentData['totalGuestBreakfasts'] ?? 0,
          balance: (currentData['balance'] as num?)?.toDouble() ?? 0.0,
        );

        await FirebaseFirestore.instance
            .collection('members')
            .doc(memberId)
            .update(member.toMap());

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating member: $e')),
          );
        }
      }
    }
  }

  Widget _buildMemberCard(Member member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            member.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.phone),
            if (member.email.isNotEmpty) Text(member.email),
            Text(
              'Joined: ${DateFormat('MMM d, y').format(member.joinDate)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              onTap: () {
                // Delay to allow menu to close
                Future.delayed(const Duration(milliseconds: 100), () {
                  _nameController.text = member.name;
                  _phoneController.text = member.phone;
                  _emailController.text = member.email;
                  _showAddMemberDialog(isEditing: true, memberId: member.id);
                });
              },
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: Text('Delete', style: TextStyle(color: Colors.red[400])),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              onTap: () {
                // Delay to allow menu to close
                Future.delayed(const Duration(milliseconds: 100), () {
                  _showDeleteConfirmation(member);
                });
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberDetailsScreen(
                memberId: member.id,
                memberName: member.name,
                mealRate: 60.0, // You might want to make this configurable
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('members')
                    .doc(member.id)
                    .delete();
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting member: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('members').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = Member.fromMap(
                members[index].id,
                members[index].data() as Map<String, dynamic>,
              );

              return _buildMemberCard(member);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 