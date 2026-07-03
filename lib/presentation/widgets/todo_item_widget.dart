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
        color: Colors.red.shade600, // Vercel 風格的破壞性操作紅色
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      child: InkWell(
        onTap: () {
          ref.read(todoNotifierProvider.notifier).toggleTodo(todo);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: todo.isCompleted ? AppColors.black : AppColors.transparent,
                  border: Border.all(
                    color: todo.isCompleted ? AppColors.black : AppColors.divider,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6), // Vercel 常用的 6px 圓角
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: todo.isCompleted ? AppColors.vercelGray400 : AppColors.textPrimary,
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
