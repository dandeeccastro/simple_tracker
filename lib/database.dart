import "package:path/path.dart";
import "package:sqflite/sqflite.dart";

import "dart:async";

class TrackerDatabase {
  static final seeder = [
    Activity(id: 1,name: "Coding"),
    Activity(id: 2,name: "Working"),
    Activity(id: 3,name: "Streaming"),
    Activity(id: 4,name: "Studying")
  ];

  static final Future<Database> database = getDatabasesPath().then((String path) {
    return openDatabase(join(path, "activities.db"), version: 1,
        onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE activities(id INTEGER PRIMARY KEY, name TEXT)");
    });
  });

  static Future<void> insertActivity(Activity activity) async {
    final Database db = await database;
    await db.insert("activities", activity.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> seedDatabase() async {
    List<Activity> seed = seeder;
    final Database db = await database;
    for (Activity item in seed) {
      await db.insert("activities", item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<List<Activity>> activities() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query("activities");

    return List.generate(maps.length, (i) {
      return Activity(
        id: maps[i]['id'],
        name: maps[i]['name'],
      );
    });
  }
}

// Model for activities that are trackable
class Activity {
  final int id;
  final String name;

  Activity({this.id, this.name});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
    };
  }
}
