import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:objectiq/model/history_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'history.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            context TEXT,
            summary TEXT,
            food TEXT,
            recipeSummary TEXT,
            calories NUMERIC,
            error TEXT,
            date TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE history ADD COLUMN food TEXT');
          await db.execute('ALTER TABLE history ADD COLUMN recipeSummary TEXT');
          await db.execute(
              'ALTER TABLE history ADD COLUMN calories NUMERIC DEFAULT 0');
        }
      },
    );
    return _db!;
  }

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> insertItem(HistoryItem item) async {
    final db = await database;
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    int? safeCalories;
    if (item.calories is int) {
      safeCalories = item.calories;
    } else if (item.calories is String) {
      safeCalories = int.tryParse(item.calories as String);
    }

    await db.insert('history', {
      'id': item.id,
      'user_id': userId,
      'context': item.context,
      'summary': item.summary,
      'food': item.food,
      'recipeSummary': item.recipeSummary,
      'calories': safeCalories,
      'error': item.error,
      'date': item.date.toIso8601String(),
    });
  }

  Future<List<HistoryItem>> fetchAll() async {
    final db = await database;
    final userId = _currentUserId;
    if (userId == null) return [];
    final maps = await db.query(
      'history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps
        .map((row) => HistoryItem(
              id: row['id'] as String,
              context: row['context'] as String?,
              summary: row['summary'] as String?,
              food: row['food'] as String?,
              recipeSummary: row['recipeSummary'] as String?,
              calories: row['calories'] as int?,
              error: row['error'] as String?,
              date: DateTime.parse(row['date'] as String),
            ))
        .toList();
  }

  Future<HistoryItem?> fetchLatest() async {
    final db = await database;
    final userId = _currentUserId;
    if (userId == null) return null;
    final maps = await db.query(
      'history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final row = maps.first;
    return HistoryItem(
      id: row['id'] as String,
      context: row['context'] as String?,
      summary: row['summary'] as String?,
      food: row['food'] as String?,
      recipeSummary: row['recipeSummary'] as String?,
      calories: row['calories'] as int?,
      error: row['error'] as String?,
      date: DateTime.parse(row['date'] as String),
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    final userId = _currentUserId;
    if (userId == null) return;
    await db.delete(
      'history',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    final userId = _currentUserId;
    if (userId == null) return;
    await db.delete(
      'history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
