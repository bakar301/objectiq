class HistoryItem {
  final String id;
  final DateTime date;
  final String? context;
  final String? summary;
  final String? food;
  final String? recipeSummary;
  final int? calories;
  final String? error;

  HistoryItem({
    required this.id,
    required this.date,
    this.context,
    this.summary,
    this.food,
    this.recipeSummary,
    this.calories,
    this.error,
  });
}
