import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_provider.dart';

class TodoItemWidget extends ConsumerStatefulWidget {
  final Todo todo;

  const TodoItemWidget({super.key, required this.todo});

  @override
  ConsumerState<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends ConsumerState<TodoItemWidget> {
  bool _isHovered = false;

  bool get _isOverdue {
    if (widget.todo.dueDate == null) return false;
    if (widget.todo.isCompleted) return false;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return widget.todo.dueDate!.isBefore(todayStart);
  }

  bool get _isToday {
    if (widget.todo.dueDate == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return !widget.todo.dueDate!.isBefore(todayStart) && widget.todo.dueDate!.isBefore(todayEnd);
  }

  String _getRepeatUnitLabel(String unit) {
    switch (unit) {
      case 'day': return '天';
      case 'week': return '周';
      case 'month': return '月';
      case 'year': return '年';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.todo.isCompleted ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: ShadTheme.of(context).colorScheme.border.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: ShadContextMenu(
        items: [
          ShadContextMenuItem(
            onPressed: () {
              ref.read(todoNotifierProvider.notifier).toggleTodo(widget.todo);
            },
            trailing: Icon(widget.todo.isCompleted ? LucideIcons.xCircle : LucideIcons.checkCircle, size: 16),
            child: Text(widget.todo.isCompleted ? 'Mark as Uncompleted' : 'Mark as Completed'),
          ),
          ShadContextMenuItem(
            onPressed: () {
              ref.read(todoNotifierProvider.notifier).deleteTodo(widget.todo.id);
            },
            trailing: Icon(LucideIcons.trash2, size: 16, color: ShadTheme.of(context).colorScheme.destructive),
            child: Text('Delete', style: TextStyle(color: ShadTheme.of(context).colorScheme.destructive)),
          ),
        ],
        child: Dismissible(
          key: Key(widget.todo.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            ref.read(todoNotifierProvider.notifier).deleteTodo(widget.todo.id);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: ShadTheme.of(context).colorScheme.destructive,
            child: Icon(LucideIcons.trash2, color: ShadTheme.of(context).colorScheme.destructiveForeground),
          ),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                ref.read(todoNotifierProvider.notifier).toggleTodo(widget.todo);
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Opacity(
                          opacity: widget.todo.isCompleted ? 1.0 : 0.4,
                          child: ShadCheckbox(
                            value: widget.todo.isCompleted,
                            onChanged: (v) {
                              ref.read(todoNotifierProvider.notifier).toggleTodo(widget.todo);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: ShadTheme.of(context).textTheme.p.copyWith(
                                    color: widget.todo.isCompleted ? ShadTheme.of(context).colorScheme.mutedForeground : ShadTheme.of(context).colorScheme.foreground,
                                    decoration: widget.todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                              child: Text(widget.todo.title),
                            ),
                            if ((widget.todo.dueDate != null && !_isToday) || (widget.todo.repeatInterval != null && widget.todo.repeatUnit != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (widget.todo.dueDate != null && !_isToday)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.calendarClock,
                                            size: 12,
                                            color: _isOverdue
                                                ? ShadTheme.of(context).colorScheme.destructive
                                                : ShadTheme.of(context).colorScheme.mutedForeground,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM d, yyyy').format(widget.todo.dueDate!),
                                            style: ShadTheme.of(context).textTheme.muted.copyWith(
                                              fontSize: 12,
                                              color: _isOverdue
                                                  ? ShadTheme.of(context).colorScheme.destructive
                                                  : ShadTheme.of(context).colorScheme.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (widget.todo.repeatInterval != null && widget.todo.repeatUnit != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.repeat,
                                            size: 12,
                                            color: ShadTheme.of(context).colorScheme.mutedForeground,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '每 ${widget.todo.repeatInterval} ${_getRepeatUnitLabel(widget.todo.repeatUnit!)}',
                                            style: ShadTheme.of(context).textTheme.muted.copyWith(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
