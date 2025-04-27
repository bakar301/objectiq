class HistoryItem {
  final String id;
  final DateTime date;
  final String? context;
  final String? summary;
  final String? error;

  HistoryItem({
    required this.id,
    required this.date,
    this.context,
    this.summary,
    this.error,
  });
}
