class HistoryItem {
  final String id;
  final String imagePath;
  final DateTime date;
  final List<String> tags;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.date,
    required this.tags,
  });
}
