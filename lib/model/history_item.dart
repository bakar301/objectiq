class HistoryItem {
  final String id;
  final String imagePath;
  final DateTime date;
  final String? context;
  final String? food;
  final String? summary;
  final int? calories;
  final String? recipe;
  final String? error;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.date,
    this.context,
    this.food,
    this.summary,
    this.calories,
    this.recipe,
    this.error,
  });
}
