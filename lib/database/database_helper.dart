import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform;
import '../models/hike.dart';
import '../models/observation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('m_hike.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;

    // Handle different platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop platforms, use application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      path = join(appDocDir.path, filePath);
    } else {
      // For mobile platforms, use default databases path
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tạo bảng Hikes
    await db.execute('''
      CREATE TABLE hikes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        date TEXT NOT NULL,
        parkingAvailable INTEGER NOT NULL,
        length REAL NOT NULL,
        difficulty TEXT NOT NULL,
        description TEXT,
        estimatedDuration TEXT,
        equipment TEXT,
        bannerImagePath TEXT
        latitude REAL,
        longitude REAL
      )
    ''');

    // Tạo bảng Observations
    await db.execute('''
      CREATE TABLE observations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hikeId INTEGER NOT NULL,
        observation TEXT NOT NULL,
        time TEXT NOT NULL,
        comments TEXT,
        imagePath TEXT,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (hikeId) REFERENCES hikes(id) ON DELETE CASCADE
      )
    ''');
  }

  // CRUD Operations cho Hikes
  Future<int> createHike(Hike hike) async {
    final db = await instance.database;
    return await db.insert('hikes', hike.toMap());
  }

  Future<List<Hike>> getAllHikes() async {
    final db = await instance.database;
    final result = await db.query('hikes', orderBy: 'date DESC');
    return result.map((json) => Hike.fromMap(json)).toList();
  }

  Future<Hike?> getHike(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'hikes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Hike.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateHike(Hike hike) async {
    final db = await instance.database;
    return db.update(
      'hikes',
      hike.toMap(),
      where: 'id = ?',
      whereArgs: [hike.id],
    );
  }

  Future<int> deleteHike(int id) async {
    final db = await instance.database;
    return await db.delete(
      'hikes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllHikes() async {
    final db = await instance.database;
    await db.delete('hikes');
    await db.delete('observations');
  }

  // Search hikes by name
  Future<List<Hike>> searchHikesByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'hikes',
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
    );
    return result.map((json) => Hike.fromMap(json)).toList();
  }

  // CRUD Operations cho Observations
  Future<int> createObservation(Observation observation) async {
    final db = await instance.database;
    return await db.insert('observations', observation.toMap());
  }

  Future<List<Observation>> getObservationsForHike(int hikeId) async {
    final db = await instance.database;
    final result = await db.query(
      'observations',
      where: 'hikeId = ?',
      whereArgs: [hikeId],
      orderBy: 'time DESC',
    );
    return result.map((json) => Observation.fromMap(json)).toList();
  }

  Future<int> updateObservation(Observation observation) async {
    final db = await instance.database;
    return db.update(
      'observations',
      observation.toMap(),
      where: 'id = ?',
      whereArgs: [observation.id],
    );
  }

  Future<int> deleteObservation(int id) async {
    final db = await instance.database;
    return await db.delete(
      'observations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Advanced search
  Future<List<Hike>> advancedSearch({
    String? name,
    String? location,
    String? dateFrom,
    String? dateTo,
    double? minLength,
    double? maxLength,
    String? difficulty,
    bool? parkingAvailable,
  }) async {
    final db = await instance.database;

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    // Name search (partial match)
    if (name != null && name.isNotEmpty) {
      whereConditions.add('name LIKE ?');
      whereArgs.add('%$name%');
    }

    // Location search (partial match)
    if (location != null && location.isNotEmpty) {
      whereConditions.add('location LIKE ?');
      whereArgs.add('%$location%');
    }

    // Date range search
    if (dateFrom != null && dateFrom.isNotEmpty) {
      whereConditions.add('date >= ?');
      whereArgs.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      whereConditions.add('date <= ?');
      whereArgs.add(dateTo);
    }

    // Length range search
    if (minLength != null) {
      whereConditions.add('length >= ?');
      whereArgs.add(minLength);
    }
    if (maxLength != null) {
      whereConditions.add('length <= ?');
      whereArgs.add(maxLength);
    }

    // Difficulty search (exact match)
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'All') {
      whereConditions.add('difficulty = ?');
      whereArgs.add(difficulty);
    }

    // Parking availability search
    if (parkingAvailable != null) {
      whereConditions.add('parkingAvailable = ?');
      whereArgs.add(parkingAvailable ? 1 : 0);
    }

    // Build the WHERE clause
    String whereClause = whereConditions.isEmpty
        ? ''
        : whereConditions.join(' AND ');

    final result = await db.query(
      'hikes',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return result.map((json) => Hike.fromMap(json)).toList();
  }

  // Get all unique locations for filter dropdown
  Future<List<String>> getAllLocations() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT location FROM hikes ORDER BY location'
    );
    return result.map((row) => row['location'] as String).toList();
  }

  // Get all unique difficulties for filter dropdown
  Future<List<String>> getAllDifficulties() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT difficulty FROM hikes ORDER BY difficulty'
    );
    return result.map((row) => row['difficulty'] as String).toList();
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add imagePath column to existing tables
      await db.execute('ALTER TABLE hikes ADD COLUMN imagePath TEXT');
      await db.execute('ALTER TABLE observations ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE hikes ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE hikes ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE observations ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE observations ADD COLUMN longitude REAL');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}