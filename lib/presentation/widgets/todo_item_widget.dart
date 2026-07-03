import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_provider.dart';

class TodoItemWidget extends ConsumerWidget {
  final Todo todo;

  const TodoItemWidget({super.key, required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.black, // 保持無彩色，以強烈的黑色表示刪除
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      child: InkWell(
        onTap: () {
          ref.read(todoNotifierProvider.notifier).toggleTodo(todo);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: todo.isCompleted ? AppColors.black : AppColors.transparent,
                  border: Border.all(
                    color: todo.isCompleted ? AppColors.black : AppColors.gray400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4), // 幾何方塊
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check, size: 16, color: AppColors.white)
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: todo.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                  child: Text(todo.title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
