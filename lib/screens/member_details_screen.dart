import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:meal/models/meal_entry.dart';

class MemberDetailsScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final double mealRate;

  const MemberDetailsScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.mealRate,
  });

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Map<String, dynamic>> _mealEvents = {};
  bool _hasBreakfast = false;
  final Map<String, GlobalKey<AnimatedListState>> _listKeys = {};
  bool _isMealHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMealEvents();
  }

  Future<void> _loadMealEvents() async {
    final meals = await FirebaseFirestore.instance
        .collection('meals')
        .where('memberId', isEqualTo: widget.memberId)
        .get();

    setState(() {
      _mealEvents = {
        for (var meal in meals.docs)
          DateTime.parse(meal.data()['date']): {
            'id': meal.id,
            'mealCount': (meal.data()['mealCount'] as num?)?.toInt() ?? 0,
            'hasBreakfast': meal.data()['hasBreakfast'] as bool? ?? false,
            'guestMealCount': (meal.data()['guestMealCount'] as num?)?.toInt() ?? 0,
            'guestBreakfastCount': (meal.data()['guestBreakfastCount'] as num?)?.toInt() ?? 0,
          }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                widget.memberName[0],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.memberName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show member stats
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      icon: Icons.restaurant,
                      title: 'Total Meals',
                      value: '32',
                      color: Colors.blue,
                    ),
                    _buildSummaryCard(
                      icon: Icons.breakfast_dining,
                      title: 'Breakfasts',
                      value: '12',
                      color: Colors.orange,
                    ),
                    _buildSummaryCard(
                      icon: Icons.people,
                      title: 'Guest Meals',
                      value: '5',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            // Calendar Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, 
                          color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Meal Calendar',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime(DateTime.now().year, DateTime.now().month, 1),
                      lastDay: DateTime.now(),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      enabledDayPredicate: (day) {
                        final now = DateTime.now();
                        return day.month == now.month && 
                               day.year == now.year && 
                               day.isBefore(now.add(const Duration(days: 1)));
                      },
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                        if (selectedDay.isAfter(DateTime.now())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot select future dates'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        
                        if (_mealEvents.containsKey(normalizedDay)) {
                          final eventData = _mealEvents[normalizedDay]!;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Header with Date and Close Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TweenAnimationBuilder(
                                              duration: const Duration(milliseconds: 500),
                                              tween: Tween<double>(begin: 0, end: 1),
                                              builder: (context, double value, child) {
                                                return Opacity(
                                                  opacity: value,
                                                  child: child,
                                                );
                                              },
                                              child: const Text(
                                                'Meal Details',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              DateFormat('MMMM dd, yyyy').format(selectedDay),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          onPressed: () => Navigator.pop(context),
                                          icon: const Icon(Icons.close),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                            padding: const EdgeInsets.all(12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),

                                    // Meal Summary
                                    _buildModernOptionContainer(
                                      icon: Icons.restaurant_menu,
                                      title: 'Meal Summary',
                                      subtitle: 'Regular and guest meals',
                                      child: Column(
                                        children: [
                                          _buildDetailRow(
                                            Icons.restaurant,
                                            'Regular Meals',
                                            '${eventData['mealCount']} meals',
                                            color: _getMealColor(eventData['mealCount'] as int? ?? 0),
                                          ),
                                          if (eventData['guestMealCount'] > 0)
                                            _buildDetailRow(
                                              Icons.people,
                                              'Guest Meals',
                                              '${eventData['guestMealCount']} meals',
                                              color: Colors.blue,
                                            ),
                                          if (eventData['hasBreakfast'] == true)
                                            _buildDetailRow(
                                              Icons.free_breakfast,
                                              'Breakfast',
                                              'Yes${eventData['guestBreakfastCount'] > 0 ? ' (+${eventData['guestBreakfastCount']} guest)' : ''}',
                                              color: Colors.orange,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              if (eventData['id'] != null) {
                                                final mealEntry = MealEntry(
                                                  id: eventData['id']!,
                                                  memberId: widget.memberId,
                                                  date: selectedDay,
                                                  mealCount: (eventData['mealCount'] as num?)?.toInt() ?? 0,
                                                  hasBreakfast: eventData['hasBreakfast'] as bool? ?? false,
                                                  guestMealCount: (eventData['guestMealCount'] as num?)?.toInt() ?? 0,
                                                  guestBreakfastCount: (eventData['guestBreakfastCount'] as num?)?.toInt() ?? 0,
                                                );
                                                _showMealEntryDialog(selectedDay, mealEntry);
                                              }
                                            },
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit Entry'),
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              if (eventData['id'] != null) {
                                                _deleteMeal(
                                                  eventData['id']!,
                                                  (eventData['mealCount'] as num?)?.toInt() ?? 0,
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
                                            label: const Text('Delete'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
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
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _showMealEntryDialog(selectedDay);
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) {
                        final normalizedDay = DateTime(day.year, day.month, day.day);
                        if (_mealEvents.containsKey(normalizedDay)) {
                          final eventData = _mealEvents[normalizedDay]!;
                          final regularMeals = eventData['mealCount'] as int? ?? 0;
                          final guestMeals = eventData['guestMealCount'] as int? ?? 0;
                          final totalMeals = regularMeals + guestMeals;
                          
                          final hasBreakfast = eventData['hasBreakfast'] as bool? ?? false;
                          final guestBreakfast = eventData['guestBreakfastCount'] as int? ?? 0;
                          final totalBreakfast = (hasBreakfast ? 1 : 0) + guestBreakfast;

                          final events = <String>[];
                          if (totalMeals > 0) events.add('$totalMeals🍽️');
                          if (totalBreakfast > 0) events.add('$totalBreakfast🍳');
                          return events;
                        }
                        return [];
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Meal History
            Card(
              margin: const EdgeInsets.all(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  initiallyExpanded: _isMealHistoryExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _isMealHistoryExpanded = expanded);
                  },
                  title: Row(
                    children: [
                      Icon(Icons.history, 
                        color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Meal History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('meals')
                            .where('memberId', isEqualTo: widget.memberId)
                            .orderBy('date', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: TextStyle(color: Colors.red[400]),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.no_meals_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No meal history found',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final mealData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                                final date = DateTime.parse(mealData['date'] as String);
                                final mealCount = (mealData['mealCount'] as num?)?.toInt() ?? 0;
                                final hasBreakfast = mealData['hasBreakfast'] as bool? ?? false;
                                final guestMealCount = (mealData['guestMealCount'] as num?)?.toInt() ?? 0;
                                final guestBreakfastCount = (mealData['guestBreakfastCount'] as num?)?.toInt() ?? 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    clipBehavior: Clip.antiAlias,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        title: Text(
                                          DateFormat('MMMM d, y').format(date),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (mealCount > 0 || guestMealCount > 0)
                                              Text(
                                                'Meals: $mealCount' +
                                                (guestMealCount > 0 ? ' (+$guestMealCount guest)' : ''),
                                              ),
                                            if (hasBreakfast || guestBreakfastCount > 0)
                                              Text(
                                                'Breakfast: ${hasBreakfast ? "1" : "0"}' +
                                                (guestBreakfastCount > 0 ? ' (+$guestBreakfastCount guest)' : ''),
                                              ),
                                          ],
                                        ),
                                        trailing: Text(
                                          '৳${((mealCount + guestMealCount) * widget.mealRate).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMealEntryDialog(DateTime.now()),
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
    );
  }

  void _showMealEntryDialog(DateTime selectedDay, [MealEntry? existingEntry]) {
    int selectedMealCount = existingEntry?.mealCount ?? 0;
    bool hasBreakfast = existingEntry?.hasBreakfast ?? false;
    bool hasGuestMeal = existingEntry?.guestMealCount != null && 
                        existingEntry!.guestMealCount > 0;
    bool hasGuestBreakfast = existingEntry?.guestBreakfastCount != null && 
                            existingEntry!.guestBreakfastCount > 0;
    int guestMealCount = existingEntry?.guestMealCount ?? 1;
    int guestBreakfastCount = existingEntry?.guestBreakfastCount ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with Date and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: child,
                              );
                            },
                            child: Text(
                              existingEntry != null ? 'Edit Meal Entry' : 'Add Meal Entry',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(selectedDay),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Regular Meals Section
                  _buildModernOptionContainer(
                    icon: Icons.restaurant_menu,
                    title: 'Regular Meals',
                    subtitle: 'Select number of meals',
                    child: Container(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [0, 1, 2, 3].map((count) {
                          final isSelected = selectedMealCount == count;
                          return TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween<double>(begin: 0.8, end: isSelected ? 1.1 : 1.0),
                            builder: (context, double scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: InkWell(
                              onTap: () => setDialogState(() => selectedMealCount = count),
                              child: Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      count.toString(),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'meal${count != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Breakfast Option
                  _buildModernOptionContainer(
                    icon: Icons.free_breakfast,
                    title: 'Breakfast',
                    subtitle: '৳ 8.00 per breakfast',
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SwitchListTile(
                        title: Text(
                          hasBreakfast ? 'Including Breakfast' : 'No Breakfast',
                          style: TextStyle(
                            color: hasBreakfast ? Theme.of(context).primaryColor : Colors.grey,
                            fontWeight: hasBreakfast ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        value: hasBreakfast,
                        onChanged: (value) => setDialogState(() => hasBreakfast = value),
                        activeColor: Theme.of(context).primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Guest Options
                  _buildModernOptionContainer(
                    icon: Icons.people_outline,
                    title: 'Guest Options',
                    subtitle: 'Add meals for guests',
                    child: Column(
                      children: [
                        // Guest Meals Switch
                        SwitchListTile(
                          title: const Text(
                            'Include Guest Meals',
                            style: TextStyle(fontSize: 16),
                          ),
                          value: hasGuestMeal,
                          onChanged: (value) => setDialogState(() => hasGuestMeal = value),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        // Guest Meals Counter
                        if (hasGuestMeal)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Meals Count',
                                  style: TextStyle(fontSize: 16),
                                ),
                                _buildCounter(
                                  count: guestMealCount,
                                  onDecrement: () => setDialogState(() {
                                    if (guestMealCount > 1) guestMealCount--;
                                  }),
                                  onIncrement: () => setDialogState(() => guestMealCount++),
                                ),
                              ],
                            ),
                          ),

                        // Guest Breakfast Switch
                        SwitchListTile(
                          title: const Text(
                            'Include Guest Breakfast',
                            style: TextStyle(fontSize: 16),
                          ),
                          value: hasGuestBreakfast,
                          onChanged: (value) => setDialogState(() => hasGuestBreakfast = value),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),

                        // Guest Breakfast Counter
                        if (hasGuestBreakfast)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Breakfast Count',
                                  style: TextStyle(fontSize: 16),
                                ),
                                _buildCounter(
                                  count: guestBreakfastCount,
                                  onDecrement: () => setDialogState(() {
                                    if (guestBreakfastCount > 1) guestBreakfastCount--;
                                  }),
                                  onIncrement: () => setDialogState(() => guestBreakfastCount++),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Submit Button
                  FilledButton(
                    onPressed: () {
                      if (existingEntry != null) {
                        final updatedEntry = MealEntry(
                          id: existingEntry.id,
                          memberId: widget.memberId,
                          date: selectedDay,
                          mealCount: selectedMealCount,
                          hasBreakfast: hasBreakfast,
                          guestMealCount: hasGuestMeal ? guestMealCount : 0,
                          guestBreakfastCount: hasGuestBreakfast ? guestBreakfastCount : 0,
                        );
                        _updateMeal(updatedEntry);
                      } else {
                        _addMeal(
                          selectedDay,
                          selectedMealCount,
                          hasBreakfast,
                          guestMealCount: hasGuestMeal ? guestMealCount : 0,
                          guestBreakfastCount: hasGuestBreakfast ? guestBreakfastCount : 0,
                        );
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      existingEntry != null ? 'Update Entry' : 'Add Entry',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOptionContainer({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _addMeal(
    DateTime date,
    int mealCount,
    bool hasBreakfast, {
    int guestMealCount = 0,
    int guestBreakfastCount = 0,
  }) async {
    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      await FirebaseFirestore.instance.collection('meals').add({
        'memberId': widget.memberId,
        'date': normalizedDate.toIso8601String(),
        'mealCount': mealCount,
        'hasBreakfast': hasBreakfast,
        'guestMealCount': guestMealCount,
        'guestBreakfastCount': guestBreakfastCount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId)
          .update({
        'totalMeals': FieldValue.increment(mealCount),
        if (hasBreakfast) 'totalBreakfasts': FieldValue.increment(1 + guestBreakfastCount),
      });

      setState(() {
        _mealEvents[normalizedDate] = {
          'mealCount': mealCount,
          'hasBreakfast': hasBreakfast,
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added: $mealCount meals' +
              (guestMealCount > 0 ? ' ($guestMealCount guest meals)' : '') +
              (hasBreakfast ? ' + breakfast' : '') +
              (guestBreakfastCount > 0 ? ' ($guestBreakfastCount guest breakfasts)' : ''),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding meal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteMeal(String mealId, int mealCount) async {
    try {
      await FirebaseFirestore.instance.collection('meals').doc(mealId).delete();
      
      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId)
          .update({
        'totalMeals': FieldValue.increment(-mealCount),
      });

      await _loadMealEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting meal: $e')),
        );
      }
    }
  }

  Future<void> _updateMeal(MealEntry meal) async {
    try {
      await FirebaseFirestore.instance
          .collection('meals')
          .doc(meal.id)
          .update(meal.toMap());

      if (mounted) {
        setState(() {
          _listKeys[meal.id]?.currentState?.insertItem(0);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      await _loadMealEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating meal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildCounter({
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: count > 1 ? onDecrement : null,
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(8),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Padding(
            key: ValueKey<int>(count),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onIncrement,
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, {Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey[700])!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color ?? Colors.grey[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color ?? Colors.black87,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealColor(int mealCount) {
    if (mealCount == 0) return Colors.red;
    if (mealCount == 1) return Colors.orange;
    if (mealCount == 2) return Colors.green;
    return Colors.blue;
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 