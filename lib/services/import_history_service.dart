import 'package:hive/hive.dart';

import '../models/import_history.dart';

class ImportHistoryService {
  static const String boxName = 'import_history';

  static Box<ImportHistory> get _box {
    return Hive.box<ImportHistory>(boxName);
  }

  static List<ImportHistory> getAll() {
    final items = _box.values.toList();

    items.sort(
      (first, second) => second.importedAt.compareTo(first.importedAt),
    );

    return items;
  }

  static ImportHistory? getById(String id) {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return _box.get(normalizedId);
  }

  static Future<void> save(ImportHistory history) async {
    final normalizedId = history.id.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError('Import history ID cannot be empty.');
    }

    await _box.put(normalizedId, history);
  }

  static Future<void> delete(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _box.delete(normalizedId);
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}
