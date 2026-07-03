import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';

class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  final TextEditingController _controller = TextEditingController();
  int _currentIndex = 0;

  void _submit() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      ref.read(todoNotifierProvider.notifier).addTodo(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoListStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
              child: Text(
                'Tasks.',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _submit(),
                style: Theme.of(context).textTheme.bodyLarge,
                cursorColor: AppColors.black,
                decoration: InputDecoration(
                  hintText: 'Add a new task...',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.black, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: AppColors.black),
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: todosAsync.when(
                data: (todos) {
                  if (todos.isEmpty) {
                    return Center(
                      child: Text(
                        'No tasks yet.\nEnjoy the emptiness.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      return TodoItemWidget(
                        // 確保 key 與 ID 綁定，提供更好的動畫與狀態管理
                        key: ValueKey(todos[index].id),
                        todo: todos[index]
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.black)),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.black,
          unselectedItemColor: AppColors.gray400,
          selectedLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.wb_sunny_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.wb_sunny, size: 24),
              ),
              label: '今天',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.calendar_today_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.calendar_today, size: 24),
              ),
              label: '未來',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.inbox_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.inbox, size: 24),
              ),
              label: '某天',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.all_inclusive_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.all_inclusive, size: 24),
              ),
              label: '隨時',
            ),
          ],
        ),
      ),
    );
  }
}
