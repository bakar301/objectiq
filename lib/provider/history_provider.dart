import 'package:flutter/foundation.dart';
import 'package:objectiq/model/history_item.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryProvider with ChangeNotifier {
  final List<HistoryItem> _items = [];

  List<HistoryItem> get items => [..._items];

  void addItem(HistoryItem newItem) {
    _items.insert(0, newItem);
    notifyListeners();
    // _insertItemToDatabase(newItem);
  }

  // Future<void> _insertItemToDatabase(HistoryItem item) async {
  //   final client = Supabase.instance.client;

  //   final response = await client.from('object_iq').insert({
  //     'user_id': Supabase.instance.client.auth.currentUser
  //         ?.id, // if you're using Supabase Auth
  //     item.id: 'id',
  //     item.imagePath: 'image_path',
  //     item.date.toIso8601String(): 'date',
  //     item.context: 'context',
  //     item.food: 'food',
  //     item.summary: 'summary',
  //     item.calories: 'calories',
  //     item.recipe: 'recipe',
  //     item.error: 'error',
  //   }).select();
  // }

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

// class NoteDatabase{
//      final client = Supabase.instance.client.from('object_iq');
    


    
   
//     Future<void> createobjectiq(Note newNote) async {
//       await client.insert(newNote.toMap());
//     }
// }