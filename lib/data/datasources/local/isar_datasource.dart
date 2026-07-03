import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/todo_model.dart';

class IsarDataSource {
  late Future<Isar> db;

  IsarDataSource() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [TodoModelSchema],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
