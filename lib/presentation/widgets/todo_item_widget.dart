import 'package:flutter/material.dart';
import 'todo_editor_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _isExpanded = false;

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
    return !widget.todo.dueDate!.isBefore(todayStart) &&
        widget.todo.dueDate!.isBefore(todayEnd);
  }

  String _getRepeatUnitLabel(String unit, String locale) {
    switch (unit) {
      case 'day':
        return Translations.tr('unit_day', locale);
      case 'week':
        return Translations.tr('unit_week', locale);
      case 'month':
        return Translations.tr('unit_month', locale);
      case 'year':
        return Translations.tr('unit_year', locale);
      default:
        return '';
    }
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
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    TodoEditorDialog(existingTodo: widget.todo),
              );
            },
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                            ref
                                .read(todoNotifierProvider.notifier)
                                .toggleTodo(widget.todo);
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
                              color: widget.todo.isCompleted
                                  ? ShadTheme.of(
                                      context,
                                    ).colorScheme.mutedForeground
                                  : ShadTheme.of(
                                      context,
                                    ).colorScheme.foreground,
                              decoration: widget.todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            child: Row(
                              children: [
                                Text(widget.todo.title),
                                if (widget.todo.subtasks.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      '${widget.todo.subtasks.where((s) => s.isCompleted).length}/${widget.todo.subtasks.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ShadTheme.of(
                                          context,
                                        ).colorScheme.mutedForeground,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.todo.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                widget.todo.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ShadTheme.of(context).textTheme.p
                                    .copyWith(
                                      fontSize: 13,
                                      color: ShadTheme.of(
                                        context,
                                      ).colorScheme.mutedForeground,
                                    ),
                              ),
                            ),
                          if (widget.todo.dueDate != null ||
                              (widget.todo.repeatInterval != null &&
                                  widget.todo.repeatUnit != null))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.calendarClock,
                                    size: 12,
                                    color: _isOverdue
                                        ? ShadTheme.of(
                                            context,
                                          ).colorScheme.destructive
                                        : ShadTheme.of(
                                            context,
                                          ).colorScheme.mutedForeground,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (() {
                                      String dateStr = '';
                                      if (widget.todo.isAnytime) {
                                        dateStr = Translations.tr(
                                          'tab_anytime',
                                          locale,
                                        );
                                      } else if (widget.todo.dueDate != null) {
                                        final date = widget.todo.dueDate!;
                                        final now = DateTime.now();
                                        final today = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        );
                                        final tomorrow = today.add(
                                          const Duration(days: 1),
                                        );
                                        final dateStart = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                        );

                                        if (dateStart == today) {
                                          dateStr = Translations.tr(
                                            'tab_today',
                                            locale,
                                          );
                                        } else if (dateStart == tomorrow) {
                                          dateStr = Translations.tr(
                                            'tomorrow',
                                            locale,
                                          );
                                        } else {
                                          dateStr = DateFormat(
                                            ref
                                                .watch(settingsProvider)
                                                .dateFormat,
                                          ).format(date);
                                        }
                                      }

                                      if (widget.todo.repeatInterval != null &&
                                          widget.todo.repeatUnit != null) {
                                        final repeatStr =
                                            '${Translations.tr('every', locale)}${widget.todo.repeatInterval} ${_getRepeatUnitLabel(widget.todo.repeatUnit!, locale)}';
                                        return dateStr.isEmpty
                                            ? repeatStr
                                            : '$dateStr · $repeatStr';
                                      }

                                      return dateStr;
                                    })(),
                                    style: ShadTheme.of(context).textTheme.muted
                                        .copyWith(
                                          fontSize: 12,
                                          color: _isOverdue
                                              ? ShadTheme.of(
                                                  context,
                                                ).colorScheme.destructive
                                              : ShadTheme.of(
                                                  context,
                                                ).colorScheme.mutedForeground,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.todo.subtasks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: GestureDetector(
                                onTap: () {}, // 阻止點擊事件向外冒泡
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isExpanded
                                              ? LucideIcons.chevronUp
                                              : LucideIcons.chevronDown,
                                          size: 14,
                                          color: ShadTheme.of(
                                            context,
                                          ).colorScheme.mutedForeground,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isExpanded
                                              ? Translations.tr(
                                                  'collapse_subtasks',
                                                  locale,
                                                )
                                              : Translations.tr(
                                                  'expand_subtasks',
                                                  locale,
                                                ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ShadTheme.of(
                                              context,
                                            ).colorScheme.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            firstCurve: Curves.easeInOutCubic,
                            secondCurve: Curves.easeInOutCubic,
                            sizeCurve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            crossFadeState:
                                (widget.todo.subtasks.isNotEmpty && _isExpanded)
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  left: 12.0,
                                ),
                                child: GestureDetector(
                                  onTap: () {}, // 阻止點擊事件向外冒泡
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: widget.todo.subtasks.map((
                                      subtask,
                                    ) {
                                      return GestureDetector(
                                        onTap: () {
                                          ref
                                              .read(
                                                todoNotifierProvider.notifier,
                                              )
                                              .toggleSubtask(
                                                widget.todo,
                                                subtask.id,
                                              );
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          key: ValueKey(subtask.id),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Opacity(
                                                opacity: subtask.isCompleted
                                                    ? 0.4
                                                    : 0.15,
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: GestureDetector(
                                                    onTap:
                                                        () {}, // 攔截點擊，不冒泡到外層 Row 的 GestureDetector
                                                    child: ShadCheckbox(
                                                      value:
                                                          subtask.isCompleted,
                                                      onChanged: (v) {
                                                        ref
                                                            .read(
                                                              todoNotifierProvider
                                                                  .notifier,
                                                            )
                                                            .toggleSubtask(
                                                              widget.todo,
                                                              subtask.id,
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  subtask.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    decoration:
                                                        subtask.isCompleted
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : TextDecoration.none,
                                                    color: ShadTheme.of(context)
                                                        .colorScheme
                                                        .mutedForeground,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            secondChild: const SizedBox(
                              width: double.infinity,
                              height: 0,
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
    );
  }
}
