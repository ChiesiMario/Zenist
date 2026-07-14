
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';
import '../../domain/entities/todo.dart';
import '../providers/settings_provider.dart';
import 'settings_page.dart';
import '../../core/localization/translations.dart';


class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DateTime? _selectedDueDate;
  bool _isAnytimeSelected = false;
  bool _isRepeatEnabled = false;
  int _repeatInterval = 1;
  String _repeatUnit = 'week';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  void _submit() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      DateTime? finalDueDate = _selectedDueDate;
      bool finalIsAnytime = _isAnytimeSelected;

      // 如果沒有手動選擇日期，且當前位於「今天」或「隨時」分頁，則自動繼承該分頁的屬性
      if (finalDueDate == null && !finalIsAnytime) {
        if (_currentIndex == 0) {
          finalDueDate = DateTime.now();
        } else if (_currentIndex == 3) {
          finalIsAnytime = true;
        }
      }

      ref.read(todoNotifierProvider.notifier).addTodo(
        text, 
        dueDate: finalDueDate,
        isAnytime: finalIsAnytime,
        repeatInterval: (_isRepeatEnabled && !finalIsAnytime) ? _repeatInterval : null,
        repeatUnit: (_isRepeatEnabled && !finalIsAnytime) ? _repeatUnit : null,
      );
      _controller.clear();
      setState(() {
        _selectedDueDate = null;
        _isAnytimeSelected = false;
        _isRepeatEnabled = false;
        _repeatInterval = 1;
        _repeatUnit = 'week';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    _focusNode.unfocus();
    
    // Create local copies of state for the dialog
    DateTime? dialogDate = _selectedDueDate;
    bool dialogAnytime = _isAnytimeSelected;
    bool dialogRepeat = _isRepeatEnabled;
    int dialogInterval = _repeatInterval;
    String dialogUnit = _repeatUnit;

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
                                      Text(Translations.tr('tab_anytime', ref.read(settingsProvider).locale)),
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
                                      Text(Translations.tr('tab_anytime', ref.read(settingsProvider).locale)),
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
                            child: Row(
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
                                          child: Text(Translations.tr('repeat', ref.read(settingsProvider).locale)),
                                        )
                                      : ShadButton.outline(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          onPressed: () {
                                            setStateDialog(() {
                                              dialogRepeat = true;
                                            });
                                          },
                                          child: Text(Translations.tr('repeat', ref.read(settingsProvider).locale)),
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
                                                  ShadOption(value: 'day', child: Text(Translations.tr('unit_day', ref.read(settingsProvider).locale))),
                                                  ShadOption(value: 'week', child: Text(Translations.tr('unit_week', ref.read(settingsProvider).locale))),
                                                  ShadOption(value: 'month', child: Text(Translations.tr('unit_month', ref.read(settingsProvider).locale))),
                                                  ShadOption(value: 'year', child: Text(Translations.tr('unit_year', ref.read(settingsProvider).locale))),
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
                                                    case 'day': return Text(Translations.tr('unit_day', ref.read(settingsProvider).locale));
                                                    case 'week': return Text(Translations.tr('unit_week', ref.read(settingsProvider).locale));
                                                    case 'month': return Text(Translations.tr('unit_month', ref.read(settingsProvider).locale));
                                                    case 'year': return Text(Translations.tr('unit_year', ref.read(settingsProvider).locale));
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
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_selectedDueDate != null || _isAnytimeSelected)
                              ShadButton.ghost(
                                onPressed: () => Navigator.of(context).pop({'clear': true}),
                                child: Text(Translations.tr('clear_date', ref.read(settingsProvider).locale), style: TextStyle(color: ShadTheme.of(context).colorScheme.mutedForeground)),
                              )
                            else
                              const SizedBox(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShadButton.ghost(
                                  onPressed: () => Navigator.of(context).pop(null),
                                  child: Text(Translations.tr('cancel', ref.read(settingsProvider).locale)),
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
                                  child: Text(Translations.tr('confirm', ref.read(settingsProvider).locale)),
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
          _isAnytimeSelected = false;
          _selectedDueDate = null;
          _isRepeatEnabled = false;
        });
      } else {
        setState(() {
          _isAnytimeSelected = result['anytime'] as bool;
          _selectedDueDate = result['date'] as DateTime?;
          _isRepeatEnabled = result['repeat'] as bool;
          _repeatInterval = result['interval'] as int;
          _repeatUnit = result['unit'] as String;
        });
      }
      _focusNode.requestFocus();
    }
  }

  String _getRepeatUnitLabel(String unit, String locale) {
    switch (unit) {
      case 'day': return Translations.tr('unit_day', locale);
      case 'week': return Translations.tr('unit_week', locale);
      case 'month': return Translations.tr('unit_month', locale);
      case 'year': return Translations.tr('unit_year', locale);
      default: return unit;
    }
  }

void _showAddTaskDialog(String locale) {
    final textController = TextEditingController(text: _controller.text);
    final focusNode = FocusNode();
    DateTime? tempDueDate = _selectedDueDate;
    
    
    bool isInputFocused = true;
    
    bool tempIsAnytime = _isAnytimeSelected;
    bool tempRepeatEnabled = _isRepeatEnabled;
    int tempRepeatInterval = _repeatInterval;
    String tempRepeatUnit = _repeatUnit;
    List<Subtask> tempSubtasks = [];
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
                            Translations.tr('add_new_task', locale),
                            style: ShadTheme.of(context).textTheme.h4,
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
                                          color: ShadTheme.of(context).colorScheme.mutedForeground.withOpacity(0.5)
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
                                ref.read(todoNotifierProvider.notifier).addTodo(
                                  newTitle, 
                                  dueDate: tempDueDate,
                                  isAnytime: tempIsAnytime,
                                  repeatInterval: tempRepeatEnabled ? tempRepeatInterval : null,
                                  repeatUnit: tempRepeatEnabled ? tempRepeatUnit : null,
                                  subtasks: tempSubtasks.where((s) => s.title.trim().isNotEmpty).toList(),
                                );
                                _controller.clear();
                                // Clear page state
                                this.setState(() {
                                  _selectedDueDate = null;
                                  _isAnytimeSelected = false;
                                  _isRepeatEnabled = false;
                                  _repeatInterval = 1;
                                  _repeatUnit = 'week';
                                });
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
    final todosAsync = ref.watch(todoListStreamProvider);
    final locale = ref.watch(settingsProvider).locale;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 列表與主要內容
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 80.0),
                    child: Container(
                    decoration: BoxDecoration(
                      color: ShadTheme.of(context).colorScheme.card,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: _currentIndex == 0 ? Radius.zero : const Radius.circular(12),
                        bottomRight: _currentIndex == 3 ? Radius.zero : const Radius.circular(12),
                      ),
                      border: Border.all(color: ShadTheme.of(context).colorScheme.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _focusNode.hasFocus 
                                        ? ShadTheme.of(context).colorScheme.ring 
                                        : ShadTheme.of(context).colorScheme.border,
                                    width: _focusNode.hasFocus ? 2.0 : 1.0,
                                  ),
                                  borderRadius: ShadTheme.of(context).radius,
                                ),
                                child: TextField(
                                  focusNode: _focusNode,
                                  controller: _controller,
                                  onSubmitted: (_) => _submit(),
                                  style: ShadTheme.of(context).textTheme.p.copyWith(
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: Translations.tr('add_new_task', locale),
                                    hintStyle: ShadTheme.of(context).textTheme.p.copyWith(
                                      color: ShadTheme.of(context).colorScheme.mutedForeground,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(left: 12, right: 112, top: 11, bottom: 11),
                                    isDense: true,
                                  ),
                                  cursorColor: ShadTheme.of(context).colorScheme.primary,
                                ),
                              ),
                              Positioned(
                                right: 6,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShadButton.ghost(
                                      onPressed: () => _showAddTaskDialog(locale),
                                      height: 32,
                                      width: 32,
                                      padding: EdgeInsets.zero,
                                      child: Icon(
                                        LucideIcons.maximize2,
                                        size: 16,
                                        color: ShadTheme.of(context).colorScheme.mutedForeground,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ShadButton.ghost(
                                      onPressed: _pickDate,
                                      height: 32,
                                      padding: EdgeInsets.symmetric(horizontal: (_selectedDueDate != null || _isAnytimeSelected) ? 8 : 8), // Keep 8 for icon, expand if text
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isAnytimeSelected ? LucideIcons.infinity : LucideIcons.calendar,
                                            size: 16,
                                            color: (_selectedDueDate != null || _isAnytimeSelected)
                                                ? ShadTheme.of(context).colorScheme.primary
                                                : ShadTheme.of(context).colorScheme.mutedForeground,
                                          ),
                                          if (_isAnytimeSelected || _selectedDueDate != null) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              (() {
                                                final locale = ref.watch(settingsProvider).locale;
                                                
                                                String getRepeatUnitLabel(String unit) {
                                                  switch (unit) {
                                                    case 'day': return Translations.tr('unit_day', locale);
                                                    case 'week': return Translations.tr('unit_week', locale);
                                                    case 'month': return Translations.tr('unit_month', locale);
                                                    case 'year': return Translations.tr('unit_year', locale);
                                                    default: return unit;
                                                  }
                                                }

                                                String dateStr = '';
                                                if (_isAnytimeSelected) {
                                                  dateStr = Translations.tr('tab_anytime', locale);
                                                } else {
                                                  final date = _selectedDueDate!;
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

                                                if (_isRepeatEnabled) {
                                                  final repeatStr = '${Translations.tr('every', locale)}$_repeatInterval ${getRepeatUnitLabel(_repeatUnit)}';
                                                  return '$dateStr · $repeatStr';
                                                }

                                                return dateStr;
                                              })(),
                                              style: TextStyle(
                                                color: ShadTheme.of(context).colorScheme.primary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ShadButton.ghost(
                                      onPressed: _submit,
                                      width: 32,
                                      height: 32,
                                      padding: EdgeInsets.zero,
                                      child: const Icon(LucideIcons.arrowUp, size: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: todosAsync.when(
                            data: (allTodos) {
                              final now = DateTime.now();
                              final todayStart = DateTime(now.year, now.month, now.day);
                              final todayEnd = todayStart.add(const Duration(days: 1));

                              final uncompletedTodos = <Todo>[];
                              final completedTodayTodos = <Todo>[];

                              for (final todo in allTodos) {
                                bool matchesTab = false;
                                if (_currentIndex == 0) { // 今天
                                  if (todo.dueDate != null && !todo.isAnytime) {
                                    if (todo.dueDate!.isBefore(todayStart)) {
                                      if (!todo.isCompleted) matchesTab = true; // 過期但未完成
                                    } else if (todo.dueDate!.isBefore(todayEnd)) {
                                      matchesTab = true; // 今天之內
                                    }
                                  }
                                } else if (_currentIndex == 1) { // 未來
                                  if (todo.dueDate != null && !todo.isAnytime && todo.dueDate!.isAfter(todayEnd.subtract(const Duration(milliseconds: 1)))) {
                                    matchesTab = true;
                                  }
                                } else if (_currentIndex == 2) { // 某天
                                  if (todo.dueDate == null && !todo.isAnytime) matchesTab = true;
                                } else if (_currentIndex == 3) { // 隨時
                                  if (todo.isAnytime) matchesTab = true;
                                }

                                if (matchesTab) {
                                  if (!todo.isCompleted) {
                                    uncompletedTodos.add(todo);
                                  } else {
                                    // 僅限今天完成的
                                    if (todo.completedAt != null && 
                                        !todo.completedAt!.isBefore(todayStart) && 
                                        todo.completedAt!.isBefore(todayEnd)) {
                                      completedTodayTodos.add(todo);
                                    }
                                  }
                                }
                              }

                              if (uncompletedTodos.isEmpty && completedTodayTodos.isEmpty) {
                                return Center(
                                  child: Text(
                                    Translations.tr('empty_state', locale),
                                    textAlign: TextAlign.center,
                                    style: ShadTheme.of(context).textTheme.p.copyWith(
                                          height: 1.5,
                                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                                        ),
                                  ),
                                );
                              }
                              
                              final itemCount = uncompletedTodos.length + (completedTodayTodos.isEmpty ? 0 : completedTodayTodos.length + 1);

                              return ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  if (index < uncompletedTodos.length) {
                                    return TodoItemWidget(
                                      key: ValueKey(uncompletedTodos[index].id),
                                      todo: uncompletedTodos[index],
                                    );
                                  }
                                  
                                  final completedIndex = index - uncompletedTodos.length;
                                  if (completedIndex == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 32, bottom: 8),
                                      child: Text(
                                        Translations.tr('completed', locale),
                                        style: ShadTheme.of(context).textTheme.large.copyWith(
                                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final todo = completedTodayTodos[completedIndex - 1];
                                  return TodoItemWidget(
                                    key: ValueKey(todo.id),
                                    todo: todo,
                                  );
                                },
                              );
                            },
                            loading: () => Center(child: CircularProgressIndicator(color: ShadTheme.of(context).colorScheme.foreground)),
                            error: (err, stack) => Center(child: Text('Error: $err')),
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
          // Header
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox(
                  height: 80.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Zenist.',
                          style: GoogleFonts.nunito(
                            textStyle: ShadTheme.of(context).textTheme.h2.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 32,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ),
                        ShadButton.ghost(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                          width: 48,
                          height: 48,
                          padding: EdgeInsets.zero,
                          child: const Icon(LucideIcons.settings, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: ShadTheme.of(context).colorScheme.background,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          children: [
                            _buildNavItem(0, Icons.wb_sunny_outlined, Icons.wb_sunny, Translations.tr('tab_today', locale)),
                            _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, Translations.tr('tab_upcoming', locale)),
                            _buildNavItem(2, Icons.inbox_outlined, Icons.inbox, Translations.tr('tab_someday', locale)),
                            _buildNavItem(3, Icons.all_inclusive_outlined, Icons.all_inclusive, Translations.tr('tab_anytime', locale)),
                          ],
                        ),
                        _buildFilletsOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    final isLeftOfActive = index == _currentIndex - 1;
    final isRightOfActive = index == _currentIndex + 1;

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 原始的 Tab 容器
          Container(
            width: double.infinity,
            transform: isActive ? Matrix4.translationValues(0, -1, 0) : null,
            decoration: BoxDecoration(
              color: isActive ? ShadTheme.of(context).colorScheme.card : Colors.transparent,
              borderRadius: isActive
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    )
                  : null,
              border: isActive
                  ? Border(
                      left: BorderSide(color: ShadTheme.of(context).colorScheme.border),
                      right: BorderSide(color: ShadTheme.of(context).colorScheme.border),
                      bottom: BorderSide(color: ShadTheme.of(context).colorScheme.border),
                    )
                  : null,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: SizedBox(
                  height: 72, 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? activeIcon : icon,
                        size: 20,
                        color: isActive ? ShadTheme.of(context).colorScheme.foreground : ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: isActive ? ShadTheme.of(context).colorScheme.foreground : ShadTheme.of(context).colorScheme.mutedForeground,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilletsOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Row(
          children: List.generate(4, (index) {
            final isLeftOfActive = index == _currentIndex - 1;
            final isRightOfActive = index == _currentIndex + 1;
            
            return Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 右側反向圓角 (覆蓋在選中標籤左側的直角上)
                  if (isLeftOfActive)
                    Positioned(
                      top: -1,
                      right: -1,
                      width: 13,
                      height: 13,
                      child: Container(
                        color: ShadTheme.of(context).colorScheme.card,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ShadTheme.of(context).colorScheme.background,
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
                            border: Border(
                              top: BorderSide(color: ShadTheme.of(context).colorScheme.border, width: 1),
                              right: BorderSide(color: ShadTheme.of(context).colorScheme.border, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 左側反向圓角 (覆蓋在選中標籤右側的直角上)
                  if (isRightOfActive)
                    Positioned(
                      top: -1,
                      left: -1,
                      width: 13,
                      height: 13,
                      child: Container(
                        color: ShadTheme.of(context).colorScheme.card,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ShadTheme.of(context).colorScheme.background,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
                            border: Border(
                              top: BorderSide(color: ShadTheme.of(context).colorScheme.border, width: 1),
                              left: BorderSide(color: ShadTheme.of(context).colorScheme.border, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
