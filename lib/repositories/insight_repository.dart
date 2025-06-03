import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/insight_model.dart';
import '../data/default_categories.dart';

class InsightRepository {
  static const String _insightsKey = 'insights';
  static const String _categoriesKey = 'categories';
  static const int _maxInsightsPerCategory = 100;
  static Database? _database;
  static const String _insightsTable = 'insights';
  static const String _categoriesTable = 'categories';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'insights.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_insightsTable(
            id TEXT PRIMARY KEY,
            category TEXT,
            content TEXT,
            timestamp TEXT,
            metadata TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $_categoriesTable(
            name TEXT PRIMARY KEY,
            description TEXT,
            prompt TEXT,
            metrics TEXT,
            settings TEXT
          )
        ''');

        // Insert default categories
        for (final category in defaultCategories) {
          await db.insert(
            _categoriesTable,
            {
              'name': category.name,
              'description': category.description,
              'prompt': category.prompt,
              'metrics': category.metrics.join(','),
              'settings': '{}',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      },
    );
  }

  Future<List<Insight>> getInsights(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _insightsTable,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Insight(
        id: maps[i]['id'],
        category: maps[i]['category'],
        content: maps[i]['content'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        metadata: Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            maps[i]['metadata'] as Map<String, dynamic>,
          ),
        ),
      );
    });
  }

  Future<void> saveInsight(Insight insight) async {
    final db = await database;
    await db.insert(
      _insightsTable,
      {
        'id': insight.id,
        'category': insight.category,
        'content': insight.content,
        'timestamp': insight.timestamp.toIso8601String(),
        'metadata': insight.metadata.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InsightCategory>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_categoriesTable);

    return List.generate(maps.length, (i) {
      return InsightCategory(
        name: maps[i]['name'],
        description: maps[i]['description'],
        prompt: maps[i]['prompt'],
        metrics: (maps[i]['metrics'] as String).split(','),
        settings: Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            maps[i]['settings'] as Map<String, dynamic>,
          ),
        ),
      );
    });
  }

  Future<void> saveCategories(List<InsightCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _categoriesKey,
      categories.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> addCategory(InsightCategory category) async {
    final db = await database;
    await db.insert(
      _categoriesTable,
      {
        'name': category.name,
        'description': category.description,
        'prompt': category.prompt,
        'metrics': category.metrics.join(','),
        'settings': category.settings.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(InsightCategory category) async {
    final db = await database;
    await db.update(
      _categoriesTable,
      {
        'description': category.description,
        'prompt': category.prompt,
        'metrics': category.metrics.join(','),
        'settings': category.settings.toString(),
      },
      where: 'name = ?',
      whereArgs: [category.name],
    );
  }

  Future<void> deleteCategory(String categoryName) async {
    final db = await database;
    await db.delete(
      _categoriesTable,
      where: 'name = ?',
      whereArgs: [categoryName],
    );
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_categoriesKey);
    
    final categories = await getCategories();
    for (var category in categories) {
      await prefs.remove('${_insightsKey}_${category.name}');
    }
  }
} 