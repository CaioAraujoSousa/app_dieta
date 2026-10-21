class DailyLog {
  final int? id;
  final String date; // Formato YYYY-MM-DD
  final String mealPeriod;
  final String optionChosen;
  final double percentage; // 1.0 (100%), 0.5 (50%), 0.0 (0%)

  DailyLog({
    this.id,
    required this.date,
    required this.mealPeriod,
    required this.optionChosen,
    required this.percentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mealPeriod': mealPeriod,
      'optionChosen': optionChosen,
      'percentage': percentage,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'],
      date: map['date'],
      mealPeriod: map['mealPeriod'],
      optionChosen: map['optionChosen'],
      percentage: map['percentage'],
    );
  }
}