// lib/provider/history_provider.dart
import 'package:flutter/foundation.dart';
import 'package:objectiq/model/history_item.dart';
import 'package:objectiq/provider/databasehelper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryProvider with ChangeNotifier {
  final List<HistoryItem> _items = [];
  final _db = DatabaseHelper();

  List<HistoryItem> get items => List.unmodifiable(_items);

  Future<void> loadHistory() async {
    // Ensure user is logged in
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Fetch from local SQLite
    _items
      ..clear()
      ..addAll(await _db.fetchAll());
    notifyListeners();
  }

  Future<void> fetchLatestHistory() async {
    await loadHistory();
  }

  Future<void> addItem(HistoryItem newItem) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Update in-memory list
    _items.insert(0, newItem);
    notifyListeners();

    // Persist locally
    await _db.insertItem(newItem);
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((it) => it.id == id);
    notifyListeners();
    await _db.deleteItem(id);
  }

  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _db.clearAll();
  }
}
