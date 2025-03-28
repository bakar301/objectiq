import 'package:flutter/foundation.dart';
import 'package:objectiq/model/history_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryProvider with ChangeNotifier {
  final List<HistoryItem> _items = [];

  List<HistoryItem> get items => [..._items];

  void addItem(HistoryItem newItem) {
    _items.insert(0, newItem);
    notifyListeners();
    _insertItemToDatabase(newItem);
  }

  Future<void> _insertItemToDatabase(HistoryItem item) async {
    final client = Supabase.instance.client;
    final response = await client.from('objectiq').insert({
      'id': item.id, // if you're setting your own ID
      'image_path': item.imagePath,
      'date': item.date.toIso8601String(),

      'context': item.context,
      'summary': item.summary,
      'food': item.food,
      'calories': item.calories,
      'recipe': item.recipe,
      'error': item.error,
    });

    if (response.error != null) {
      if (kDebugMode) {
        print('Error inserting history: ${response.error!.message}');
      }
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    // Optionally: delete the item from the database
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
    // Optionally: clear the remote database
  }
}
