class HistoryItem {
  final String id;
  final String imagePath;
  final DateTime date;
  // New fields added from FastAPI result.
  final String? context;
  final String? summary;
  final String? name;
  final String? color;
  final String? food;
  final String? calories;
  final String? recipe;
  final String? error;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.date,
    this.context,
    this.name,
    this.color,
    this.summary,
    this.food,
    this.calories,
    this.recipe,
    this.error,
  });
}
