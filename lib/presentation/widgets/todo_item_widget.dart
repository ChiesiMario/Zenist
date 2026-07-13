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


  void _showDetailsDialog(String locale) {
    final textController = TextEditingController(text: widget.todo.title);
    final focusNode = FocusNode();
    DateTime? tempDueDate = widget.todo.dueDate;
    bool isConfirmingDelete = false;
    int deleteConfirmId = 0;
    bool isInputFocused = true;
    
    bool tempIsAnytime = widget.todo.isAnytime;
    bool tempRepeatEnabled = widget.todo.repeatInterval != null;
    int tempRepeatInterval = widget.todo.repeatInterval ?? 1;
    String tempRepeatUnit = widget.todo.repeatUnit ?? 'week';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateFocus() {
              if (mounted) {
                setState(() {
                  isInputFocused = focusNode.hasFocus;
                });
              }
            }
            focusNode.removeListener(updateFocus);
            focusNode.addListener(updateFocus);
            Future<void> pickDate() async {
              focusNode.unfocus();
              
              DateTime? dialogDate = tempDueDate;
              bool dialogAnytime = tempIsAnytime;
              bool dialogRepeat = tempRepeatEnabled;
              int dialogInterval = tempRepeatInterval;
              String dialogUnit = tempRepeatUnit;

              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return Dialog(
                        backgroundColor: ShadTheme.of(context).colorScheme.background,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: ShadTheme.of(context).radius,
                          side: BorderSide(color: ShadTheme.of(context).colorScheme.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: 270,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: SizedBox(
                                      width: 270,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Opacity(
                                            opacity: dialogAnytime ? 0.5 : 1.0,
                                            child: IgnorePointer(
                                              ignoring: dialogAnytime,
                                              child: Center(
                                                child: ShadCalendar(
                                                  fixedWeeks: true,
                                                  showOutsideDays: true,
                                                  decoration: const ShadDecoration(
                                                    border: ShadBorder.none,
                                                  ),
                                                  selected: dialogDate,
                                                  onChanged: (v) {
                                                    setStateDialog(() {
                                                      dialogDate = v;
                                                      dialogAnytime = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height: 40,
                                            child: dialogAnytime
                                                ? ShadButton(
                                                    onPressed: () {
                                                      setStateDialog(() {
                                                        dialogAnytime = false;
                                                      });
                                                    },
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(LucideIcons.infinity, size: 16),
                                                        const SizedBox(width: 8.0),
                                                        Text(Translations.tr('tab_anytime', locale)),
                                                      ],
                                                    ),
                                                  )
                                                : ShadButton.outline(
                                                    onPressed: () {
                                                      setStateDialog(() {
                                                        dialogAnytime = true;
                                                        dialogDate = null;
                                                        dialogRepeat = false;
                                                      });
                                                    },
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(LucideIcons.infinity, size: 16),
                                                        const SizedBox(width: 8.0),
                                                        Text(Translations.tr('tab_anytime', locale)),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Opacity(
                                    opacity: dialogAnytime ? 0.5 : 1.0,
                                    child: IgnorePointer(
                                      ignoring: dialogAnytime,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(
                                                height: 40,
                                                width: 84,
                                                child: dialogRepeat
                                                    ? ShadButton(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        onPressed: () {
                                                          setStateDialog(() {
                                                            dialogRepeat = false;
                                                          });
                                                        },
                                                        child: Text(Translations.tr('repeat', locale)),
                                                      )
                                                    : ShadButton.outline(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        onPressed: () {
                                                          setStateDialog(() {
                                                            dialogRepeat = true;
                                                          });
                                                        },
                                                        child: Text(Translations.tr('repeat', locale)),
                                                      ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Opacity(
                                                  opacity: dialogRepeat ? 1.0 : 0.5,
                                                  child: IgnorePointer(
                                                    ignoring: !dialogRepeat,
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 60,
                                                          height: 40,
                                                          child: ShadInput(
                                                            initialValue: dialogInterval.toString(),
                                                            keyboardType: TextInputType.number,
                                                            onChanged: (v) {
                                                              final val = int.tryParse(v);
                                                              if (val != null && val > 0) {
                                                                dialogInterval = val;
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: SizedBox(
                                                            height: 40,
                                                            child: ShadSelect<String>(
                                                              initialValue: dialogUnit,
                                                              options: [
                                                                ShadOption(value: 'day', child: Text(Translations.tr('unit_day', locale))),
                                                                ShadOption(value: 'week', child: Text(Translations.tr('unit_week', locale))),
                                                                ShadOption(value: 'month', child: Text(Translations.tr('unit_month', locale))),
                                                                ShadOption(value: 'year', child: Text(Translations.tr('unit_year', locale))),
                                                              ],
                                                              onChanged: (v) {
                                                                if (v != null) {
                                                                  setStateDialog(() {
                                                                    dialogUnit = v;
                                                                  });
                                                                  FocusScope.of(context).unfocus();
                                                                }
                                                              },
                                                              selectedOptionBuilder: (context, value) {
                                                                switch (value) {
                                                                  case 'day': return Text(Translations.tr('unit_day', locale));
                                                                  case 'week': return Text(Translations.tr('unit_week', locale));
                                                                  case 'month': return Text(Translations.tr('unit_month', locale));
                                                                  case 'year': return Text(Translations.tr('unit_year', locale));
                                                                  default: return const Text('');
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ShadButton.ghost(
                                        onPressed: () => Navigator.of(context).pop(null),
                                        child: Text(Translations.tr('cancel', locale)),
                                      ),
                                      const SizedBox(width: 8),
                                      ShadButton(
                                        onPressed: () {
                                          Navigator.of(context).pop({
                                            'date': dialogDate,
                                            'anytime': dialogAnytime,
                                            'repeat': dialogRepeat,
                                            'interval': dialogInterval,
                                            'unit': dialogUnit,
                                          });
                                        },
                                        child: Text(Translations.tr('confirm', locale)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  );
                },
              );
              
              if (result != null) {
                setState(() {
                  tempIsAnytime = result['anytime'] as bool;
                  tempDueDate = result['date'] as DateTime?;
                  tempRepeatEnabled = result['repeat'] as bool;
                  tempRepeatInterval = result['interval'] as int;
                  tempRepeatUnit = result['unit'] as String;
                });
                focusNode.requestFocus();
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Translations.tr('edit', locale),
                            style: ShadTheme.of(context).textTheme.h4,
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            crossFadeState: isConfirmingDelete ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            alignment: Alignment.centerRight,
                            firstChild: ShadButton.ghost(
                              child: Icon(LucideIcons.trash2, color: ShadTheme.of(context).colorScheme.mutedForeground, size: 20),
                              onPressed: () {
                                setState(() {
                                  isConfirmingDelete = true;
                                });
                                final currentId = ++deleteConfirmId;
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (mounted && currentId == deleteConfirmId) {
                                    setState(() {
                                      isConfirmingDelete = false;
                                    });
                                  }
                                });
                              },
                            ),
                            secondChild: ShadButton.destructive(
                              child: const Text('確認'),
                              onPressed: () {
                                ref.read(todoNotifierProvider.notifier).deleteTodo(widget.todo.id);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isInputFocused
                                ? ShadTheme.of(context).colorScheme.ring
                                : ShadTheme.of(context).colorScheme.border,
                            width: isInputFocused ? 2.0 : 1.0,
                          ),
                          borderRadius: ShadTheme.of(context).radius,
                        ),
                        child: TextField(
                          focusNode: focusNode,
                          controller: textController,
                          autofocus: true,
                          style: ShadTheme.of(context).textTheme.p.copyWith(
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 12, right: 12, top: 11, bottom: 11),
                            isDense: true,
                          ),
                          cursorColor: ShadTheme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: pickDate,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tempIsAnytime ? LucideIcons.infinity : LucideIcons.calendar, 
                                    size: 14, 
                                    color: ShadTheme.of(context).colorScheme.mutedForeground
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tempIsAnytime
                                        ? Translations.tr('tab_anytime', locale)
                                        : tempDueDate != null
                                            ? DateFormat(ref.watch(settingsProvider).dateFormat).format(tempDueDate!)
                                            : Translations.tr('set_due_date', locale),
                                    style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 13),
                                  ),
                                  if (tempRepeatEnabled) ...[
                                    const SizedBox(width: 6),
                                    Icon(LucideIcons.repeat, size: 14, color: ShadTheme.of(context).colorScheme.mutedForeground),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (tempDueDate != null || tempIsAnytime || tempRepeatEnabled) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  tempDueDate = null;
                                  tempIsAnytime = false;
                                  tempRepeatEnabled = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(LucideIcons.x, size: 14, color: ShadTheme.of(context).colorScheme.mutedForeground),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShadButton.outline(
                            child: Text(Translations.tr('cancel', locale)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ShadButton(
                            child: Text(Translations.tr('confirm', locale)),
                            onPressed: () {
                              final newTitle = textController.text.trim();
                              if (newTitle.isNotEmpty) {
                                ref.read(todoNotifierProvider.notifier).updateTodoDetails(
                                  widget.todo, 
                                  newTitle, 
                                  tempDueDate,
                                  isAnytime: tempIsAnytime,
                                  repeatInterval: tempRepeatEnabled ? tempRepeatInterval : null,
                                  repeatUnit: tempRepeatEnabled ? tempRepeatUnit : null,
                                );
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      focusNode.dispose();
      textController.dispose();
    });
  }


  void _showContextMenu(Offset position, String locale) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) _showDetailsDialog(locale);
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
                _showDetailsDialog(locale);
              },
              onLongPressStart: (details) {
                _showContextMenu(details.globalPosition, locale);
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
                                            DateFormat(ref.watch(settingsProvider).dateFormat).format(widget.todo.dueDate!),
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
