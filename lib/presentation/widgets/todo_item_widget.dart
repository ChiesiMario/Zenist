import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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
    List<Subtask> tempSubtasks = List.from(widget.todo.subtasks);
    if (tempSubtasks.isEmpty || tempSubtasks.last.title.trim().isNotEmpty) {
      tempSubtasks.add(Subtask(id: const Uuid().v4(), title: ''));
    }

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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (tempDueDate != null || tempIsAnytime)
                                        ShadButton.ghost(
                                          onPressed: () => Navigator.of(context).pop({'clear': true}),
                                          child: Text(Translations.tr('clear_date', locale), style: TextStyle(color: ShadTheme.of(context).colorScheme.mutedForeground)),
                                        )
                                      else
                                        const SizedBox(),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
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
                if (result['clear'] == true) {
                  setState(() {
                    tempIsAnytime = false;
                    tempDueDate = null;
                    tempRepeatEnabled = false;
                  });
                } else {
                  setState(() {
                    tempIsAnytime = result['anytime'] as bool;
                    tempDueDate = result['date'] as DateTime?;
                    tempRepeatEnabled = result['repeat'] as bool;
                    tempRepeatInterval = result['interval'] as int;
                    tempRepeatUnit = result['unit'] as String;
                  });
                }
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
                      const SizedBox(height: 16),
                      if (tempSubtasks.isNotEmpty)
                        Column(
                          children: tempSubtasks.map((subtask) => Padding(
                            key: ValueKey(subtask.id),
                            padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                            child: Row(
                              children: [
                                ShadCheckbox(
                                  value: subtask.isCompleted,
                                  onChanged: (v) {
                                    setState(() {
                                      final idx = tempSubtasks.indexOf(subtask);
                                      tempSubtasks[idx] = subtask.copyWith(isCompleted: v);
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      if (!hasFocus) {
                                        final idx = tempSubtasks.indexWhere((s) => s.id == subtask.id);
                                        if (idx != -1) {
                                          final currentSubtask = tempSubtasks[idx];
                                          if (idx == tempSubtasks.length - 1 && currentSubtask.title.trim().isNotEmpty) {
                                            setState(() {
                                              tempSubtasks.add(Subtask(id: const Uuid().v4(), title: ''));
                                            });
                                          }
                                        }
                                      }
                                    },
                                    child: TextFormField(
                                      initialValue: subtask.title,
                                      autofocus: subtask.title.isEmpty,
                                      style: TextStyle(
                                        decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                                        color: subtask.isCompleted ? ShadTheme.of(context).colorScheme.mutedForeground : ShadTheme.of(context).colorScheme.foreground,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: Translations.tr('subtask_placeholder', locale),
                                        hintStyle: TextStyle(
                                          color: ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5)
                                        ),
                                      ),
                                      onChanged: (v) {
                                        final idx = tempSubtasks.indexWhere((s) => s.id == subtask.id);
                                        if (idx != -1) {
                                          tempSubtasks[idx] = tempSubtasks[idx].copyWith(title: v);
                                        }
                                      },
                                      onFieldSubmitted: (v) {
                                        final idx = tempSubtasks.indexWhere((s) => s.id == subtask.id);
                                        if (idx == tempSubtasks.length - 1 && v.trim().isNotEmpty) {
                                          setState(() {
                                            tempSubtasks[idx] = tempSubtasks[idx].copyWith(title: v);
                                            tempSubtasks.add(Subtask(id: const Uuid().v4(), title: ''));
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                if (subtask.id == tempSubtasks.last.id && subtask.title.trim().isEmpty)
                                  const SizedBox(width: 32)
                                else
                                  ShadButton.ghost(
                                    width: 32,
                                    height: 32,
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      setState(() {
                                        tempSubtasks.removeWhere((s) => s.id == subtask.id);
                                        if (tempSubtasks.isEmpty || tempSubtasks.last.title.trim().isNotEmpty) {
                                          tempSubtasks.add(Subtask(id: const Uuid().v4(), title: ''));
                                        }
                                      });
                                    },
                                    child: Icon(
                                      LucideIcons.x, 
                                      size: 16,
                                      color: ShadTheme.of(context).colorScheme.mutedForeground,
                                    ),
                                  )
                              ],
                            ),
                          )).toList(),
                        ),

                      const SizedBox(height: 16),
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
                                    (() {
                                      String dateStr = '';
                                      if (tempIsAnytime) {
                                        dateStr = Translations.tr('tab_anytime', locale);
                                      } else if (tempDueDate != null) {
                                        final date = tempDueDate!;
                                        final now = DateTime.now();
                                        final today = DateTime(now.year, now.month, now.day);
                                        final tomorrow = today.add(const Duration(days: 1));
                                        final dateStart = DateTime(date.year, date.month, date.day);
                                        
                                        if (dateStart == today) {
                                          dateStr = Translations.tr('tab_today', locale);
                                        } else if (dateStart == tomorrow) {
                                          dateStr = Translations.tr('tomorrow', locale);
                                        } else {
                                          dateStr = DateFormat(ref.watch(settingsProvider).dateFormat).format(date);
                                        }
                                      } else {
                                        dateStr = Translations.tr('set_due_date', locale);
                                      }
                                      
                                      if (tempRepeatEnabled) {
                                        final repeatStr = '${Translations.tr('every', locale)}$tempRepeatInterval ${_getRepeatUnitLabel(tempRepeatUnit, locale)}';
                                        return '$dateStr · $repeatStr';
                                      }
                                      
                                      return dateStr;
                                    })(),
                                    style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),

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
                                  newSubtasks: tempSubtasks.where((s) => s.title.trim().isNotEmpty).toList(),
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
              _showDetailsDialog(locale);
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
                                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (widget.todo.dueDate != null || (widget.todo.repeatInterval != null && widget.todo.repeatUnit != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
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
                                      (() {
                                        String dateStr = '';
                                        if (widget.todo.isAnytime) {
                                          dateStr = Translations.tr('tab_anytime', locale);
                                        } else if (widget.todo.dueDate != null) {
                                          final date = widget.todo.dueDate!;
                                          final now = DateTime.now();
                                          final today = DateTime(now.year, now.month, now.day);
                                          final tomorrow = today.add(const Duration(days: 1));
                                          final dateStart = DateTime(date.year, date.month, date.day);
                                          
                                          if (dateStart == today) {
                                            dateStr = Translations.tr('tab_today', locale);
                                          } else if (dateStart == tomorrow) {
                                            dateStr = Translations.tr('tomorrow', locale);
                                          } else {
                                            dateStr = DateFormat(ref.watch(settingsProvider).dateFormat).format(date);
                                          }
                                        }
                                        
                                        if (widget.todo.repeatInterval != null && widget.todo.repeatUnit != null) {
                                          final repeatStr = '${Translations.tr('every', locale)}${widget.todo.repeatInterval} ${_getRepeatUnitLabel(widget.todo.repeatUnit!, locale)}';
                                          return dateStr.isEmpty ? repeatStr : '$dateStr · $repeatStr';
                                        }
                                        
                                        return dateStr;
                                      })(),
                                      style: ShadTheme.of(context).textTheme.muted.copyWith(
                                        fontSize: 12,
                                        color: _isOverdue
                                            ? ShadTheme.of(context).colorScheme.destructive
                                            : ShadTheme.of(context).colorScheme.mutedForeground,
                                      ),
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
    );
  }
}
