import 'package:sqlite3/sqlite3.dart';

late final Database db;

void initDatabase() {
  db = sqlite3.open('gezir33.db');

  db.execute(
    "CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, first_name TEXT, username TEXT, service_username TEXT);",
  );
  try {
    db.execute("ALTER TABLE users ADD COLUMN blocked INTEGER DEFAULT 0");
  } catch (_) {}
  try {
    db.execute("ALTER TABLE users ADD COLUMN service_username TEXT");
  } catch (_) {}
  try {
    db.execute("ALTER TABLE users ADD COLUMN service_volume TEXT");
  } catch (_) {}

  try {
    db.execute("ALTER TABLE users ADD COLUMN service_expiry TEXT");
  } catch (_) {}

  try {
    db.execute("ALTER TABLE users ADD COLUMN service_status TEXT DEFAULT 'inactive'");
  } catch (_) {}
  try {
    db.execute("ALTER TABLE users ADD COLUMN DateTime INTEGER DEFAULT 0");
  } catch (_) {}
  try {
    db.execute("ALTER TABLE users ADD COLUMN orders_count INTEGER DEFAULT 0");
  } catch (_) {}

  print("Database Ready ✅");
}
