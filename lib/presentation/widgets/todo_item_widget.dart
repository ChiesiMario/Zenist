import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_provider.dart';
import '../../core/localization/translations.dart';
import '../providers/settings_provider.dart';

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

  String _getRepeatUnitLabel(String unit, String locale) {
    switch (unit) {
      case 'day': return Translations.tr('unit_day', locale);
      case 'week': return Translations.tr('unit_week', locale);
      case 'month': return Translations.tr('unit_month', locale);
      case 'year': return Translations.tr('unit_year', locale);
      default: return '';
    }
  }

  void _showEditDialog(String locale) {
    final textController = TextEditingController(text: widget.todo.title);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.tr('edit', locale),
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const SizedBox(height: 16),
                ShadInput(
                  controller: textController,
                  autofocus: true,
                  onSubmitted: (value) {
                    ref.read(todoNotifierProvider.notifier).updateTodoTitle(widget.todo, value);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShadButton.outline(
                      child: Text(Translations.tr('cancel', locale)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    ShadButton(
                      child: Text(Translations.tr('confirm', locale)),
                      onPressed: () {
                        ref.read(todoNotifierProvider.notifier).updateTodoTitle(widget.todo, textController.text);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(Offset position, String locale) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) _showEditDialog(locale);
            });
          },
          child: Row(
            children: [
              const Icon(LucideIcons.edit2, size: 16),
              const SizedBox(width: 8),
              Text(Translations.tr('edit', locale)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            ref.read(todoNotifierProvider.notifier).deleteTodo(widget.todo.id);
          },
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16, color: ShadTheme.of(context).colorScheme.destructive),
              const SizedBox(width: 8),
              Text(Translations.tr('delete', locale), style: TextStyle(color: ShadTheme.of(context).colorScheme.destructive)),
            ],
          ),
        ),
      ],
      color: ShadTheme.of(context).colorScheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: ShadTheme.of(context).colorScheme.border, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsProvider).locale;

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
              onSecondaryTapDown: (details) {
                _showContextMenu(details.globalPosition, locale);
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
                                            '${Translations.tr('every', locale)}${widget.todo.repeatInterval} ${_getRepeatUnitLabel(widget.todo.repeatUnit!, locale)}',
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
    ));
  }
}
