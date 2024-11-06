class Member {
  final String id;
  final String name;
  int totalMeals;

  Member({
    required this.id,
    required this.name,
    this.totalMeals = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalMeals': totalMeals,
    };
  }
} 