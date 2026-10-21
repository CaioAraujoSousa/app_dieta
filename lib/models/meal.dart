class Meal {
  final int? id;
  final String period; // 'cafe', 'almoco', 'lanche', 'jantar', 'ceia'
  final String option; // 'A' ou 'B'
  final String title;
  final String time;
  final String ingredients;
  final String instructions;
  final int minCalories;
  final int maxCalories;
  final int minProtein;
  final int maxProtein;

  Meal({
    this.id,
    required this.period,
    required this.option,
    required this.title,
    required this.time,
    required this.ingredients,
    required this.instructions,
    required this.minCalories,
    required this.maxCalories,
    required this.minProtein,
    required this.maxProtein,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period': period,
      'option': option,
      'title': title,
      'time': time,
      'ingredients': ingredients,
      'instructions': instructions,
      'minCalories': minCalories,
      'maxCalories': maxCalories,
      'minProtein': minProtein,
      'maxProtein': maxProtein,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      period: map['period'],
      option: map['option'],
      title: map['title'],
      time: map['time'],
      ingredients: map['ingredients'],
      instructions: map['instructions'],
      minCalories: map['minCalories'],
      maxCalories: map['maxCalories'],
      minProtein: map['minProtein'],
      maxProtein: map['maxProtein'],
    );
  }
}