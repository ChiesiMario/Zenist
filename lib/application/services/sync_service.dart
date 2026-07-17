import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/dropbox_datasource.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../presentation/providers/todo_provider.dart';
import '../../domain/entities/todo.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(dropboxDataSourceProvider),
    ref.read(todoRepositoryProvider),
  );
});

class SyncService {
  final DropboxDataSource _dropbox;
  final TodoRepository _repo;

  SyncService(this._dropbox, this._repo);

  Future<void> syncWithDropbox() async {
    if (!await _dropbox.isLoggedIn()) return;
    
    final syncStartTime = DateTime.now();

    // 1. 獲取本地所有資料 (包含已標記為刪除的)
    final localTodos = await _repo.getTodos(includeDeleted: true);
    final localMap = {for (var t in localTodos) t.id: t};

    // 2. 下載遠端備份
    final remoteJsonString = await _dropbox.downloadBackup();
    Map<String, Todo> remoteMap = {};
    if (remoteJsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(remoteJsonString);
        for (var item in decoded) {
          final t = Todo.fromJson(item as Map<String, dynamic>);
          remoteMap[t.id] = t;
        }
      } catch (e) {
        print('Error decoding remote backup: $e');
        throw Exception('Remote backup is corrupted: $e');
      }
    }

    // 3. LWW (Last-Write-Wins) 合併邏輯
    final mergedTodos = <Todo>[];
    final allKeys = {...localMap.keys, ...remoteMap.keys};

    for (final id in allKeys) {
      final local = localMap[id];
      final remote = remoteMap[id];

      if (local != null && remote != null) {
        if (local.updatedAt.isAfter(remote.updatedAt)) {
          mergedTodos.add(local);
        } else {
          mergedTodos.add(remote);
        }
      } else if (local != null) {
        mergedTodos.add(local);
      } else if (remote != null) {
        mergedTodos.add(remote);
      }
    }

    // 4. 將合併後的資料寫回本地，同時處理樂觀鎖 (Optimistic Concurrency Control)
    final finalUploadTodos = <Todo>[];
    
    for (final todo in mergedTodos) {
      final currentLocal = await _repo.getTodo(todo.id);
      
      // 如果本地的更新時間「嚴格晚於」同步開始的時間，代表在同步期間被修改了
      if (currentLocal != null && currentLocal.updatedAt.isAfter(syncStartTime)) {
        // 保留本地最新修改，不覆寫本地資料庫
        finalUploadTodos.add(currentLocal);
      } else {
        // 否則，將合併後的結果寫入本地
        await _repo.saveTodo(todo);
        finalUploadTodos.add(todo);
      }
    }

    // 5. 將最終確認的資料重新上傳至 Dropbox
    final List<Map<String, dynamic>> jsonList = finalUploadTodos
        .map((t) => t.toJson())
        .toList();
    await _dropbox.uploadBackup(jsonEncode(jsonList));
  }
}
