import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/utilisateur.dart';
import '../models/glycemie.dart';
import '../models/tension.dart';
import '../models/cholesterol.dart';
import '../models/imc.dart';
import '../models/medicament.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    debugPrint('🔵 Initialisation de la base de données...');
    _database = await _initDB('healthify.db');
    debugPrint('✅ Base de données initialisée');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Table Utilisateur
    await db.execute('''
      CREATE TABLE utilisateur (
        id $idType,
        nom $textType,
        email $textType,
        age $intType,
        taille $realType,
        dateCreation $textType
      )
    ''');

    // Table Glycemie
    await db.execute('''
      CREATE TABLE glycemie (
        id $idType,
        userId $textType,
        valeur $realType,
        moment $textType,
        dateMesure $textType,
        remarque TEXT
      )
    ''');

    // Table Tension
    await db.execute('''
      CREATE TABLE tension (
        id $idType,
        userId $textType,
        systolique $intType,
        diastolique $intType,
        dateMesure $textType,
        remarque TEXT
      )
    ''');

    // Table Cholesterol
    await db.execute('''
      CREATE TABLE cholesterol (
        id $idType,
        userId $textType,
        total $realType,
        hdl $realType,
        ldl $realType,
        dateBilan $textType,
        remarque TEXT
      )
    ''');

    // Table IMC
    await db.execute('''
      CREATE TABLE imc (
        id $idType,
        userId $textType,
        taille $realType,
        poids $realType,
        imc $realType,
        dateMesure $textType
      )
    ''');

    // Table Medicament
    await db.execute('''
      CREATE TABLE medicament (
        id $idType,
        userId $textType,
        nom $textType,
        periode $textType,
        dateAjout $textType,
        estActif $intType
      )
    ''');
  }

  // ========== CRUD UTILISATEUR ==========
  
  Future<int> createUtilisateur(Utilisateur utilisateur) async {
    final db = await database;
    return await db.insert('utilisateur', utilisateur.toMap());
  }

  Future<Utilisateur?> getUtilisateur(int id) async {
    final db = await database;
    final maps = await db.query(
      'utilisateur',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Utilisateur.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUtilisateur(Utilisateur utilisateur) async {
    final db = await database;
    return await db.update(
      'utilisateur',
      utilisateur.toMap(),
      where: 'id = ?',
      whereArgs: [utilisateur.id],
    );
  }

  // ========== CRUD GLYCEMIE ==========
  
  Future<int> createGlycemie(Glycemie glycemie) async {
    final db = await database;
    return await db.insert('glycemie', glycemie.toMap());
  }

  Future<List<Glycemie>> getGlycemiesByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'glycemie',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateMesure DESC',
    );

    return maps.map((map) => Glycemie.fromMap(map)).toList();
  }

  Future<Glycemie?> getLastGlycemie(String userId) async {
    final db = await database;
    final maps = await db.query(
      'glycemie',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateMesure DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Glycemie.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateGlycemie(Glycemie glycemie) async {
    final db = await database;
    return await db.update(
      'glycemie',
      glycemie.toMap(),
      where: 'id = ?',
      whereArgs: [glycemie.id],
    );
  }

  Future<int> deleteGlycemie(int id) async {
    final db = await database;
    return await db.delete(
      'glycemie',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD TENSION ==========
  
  Future<int> createTension(Tension tension) async {
    debugPrint('🔵 createTension() appelé');
    final db = await database;
    debugPrint('✅ Database obtenue');
    final result = await db.insert('tension', tension.toMap());
    debugPrint('✅ Tension insérée avec ID: $result');
    return result;
  }

  Future<List<Tension>> getTensionsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'tension',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateMesure DESC',
    );

    return maps.map((map) => Tension.fromMap(map)).toList();
  }

  Future<Tension?> getLastTension(String userId) async {
    final db = await database;
    final maps = await db.query(
      'tension',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateMesure DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Tension.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTension(Tension tension) async {
    final db = await database;
    return await db.update(
      'tension',
      tension.toMap(),
      where: 'id = ?',
      whereArgs: [tension.id],
    );
  }

  Future<int> deleteTension(int id) async {
    final db = await database;
    return await db.delete(
      'tension',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD CHOLESTEROL ==========
  
  Future<int> createCholesterol(Cholesterol cholesterol) async {
    final db = await database;
    return await db.insert('cholesterol', cholesterol.toMap());
  }

  Future<List<Cholesterol>> getCholesterolsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'cholesterol',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateBilan DESC',
    );

    return maps.map((map) => Cholesterol.fromMap(map)).toList();
  }

  Future<Cholesterol?> getLastCholesterol(String userId) async {
    final db = await database;
    final maps = await db.query(
      'cholesterol',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateBilan DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Cholesterol.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCholesterol(Cholesterol cholesterol) async {
    final db = await database;
    return await db.update(
      'cholesterol',
      cholesterol.toMap(),
      where: 'id = ?',
      whereArgs: [cholesterol.id],
    );
  }

  Future<int> deleteCholesterol(int id) async {
    final db = await database;
    return await db.delete(
      'cholesterol',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD IMC ==========
  
  Future<int> createIMC(IMC imc) async {
    final db = await database;
    return await db.insert('imc', imc.toMap());
  }

  Future<List<IMC>> getIMCsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'imc',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateMesure DESC',
    );

    return maps.map((map) => IMC.fromMap(map)).toList();
  }

  Future<IMC?> getLastIMC(String userId) async {
    final db = await database;
    final maps = await db.query(
      'imc',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateMesure DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return IMC.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateIMC(IMC imc) async {
    final db = await database;
    return await db.update(
      'imc',
      imc.toMap(),
      where: 'id = ?',
      whereArgs: [imc.id],
    );
  }

  Future<int> deleteIMC(int id) async {
    final db = await database;
    return await db.delete(
      'imc',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD MEDICAMENT ==========
  
  Future<int> createMedicament(Medicament medicament) async {
    final db = await database;
    return await db.insert('medicament', medicament.toMap());
  }

  Future<List<Medicament>> getMedicamentsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'medicament',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateAjout DESC',
    );

    return maps.map((map) => Medicament.fromMap(map)).toList();
  }

  Future<List<Medicament>> getActiveMedicaments(String userId) async {
    final db = await database;
    final maps = await db.query(
      'medicament',
      where: 'userId = ? AND estActif = ?',
      whereArgs: [userId, 1],
      orderBy: 'dateAjout DESC',
    );

    return maps.map((map) => Medicament.fromMap(map)).toList();
  }

  Future<int> updateMedicament(Medicament medicament) async {
    final db = await database;
    return await db.update(
      'medicament',
      medicament.toMap(),
      where: 'id = ?',
      whereArgs: [medicament.id],
    );
  }

  Future<int> deleteMedicament(int id) async {
    final db = await database;
    return await db.delete(
      'medicament',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== UTILITAIRES ==========

  Future close() async {
    final db = await database;
    db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'healthify.db');
    await databaseFactory.deleteDatabase(path);
  }
}