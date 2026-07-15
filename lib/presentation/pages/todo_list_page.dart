import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';
import '../../domain/entities/todo.dart';
import '../providers/settings_provider.dart';
import '../widgets/all_done_zen_ring_widget.dart';
import '../widgets/future_empty_widgets.dart';

import '../../core/localization/translations.dart';
import '../../application/services/auto_sync_manager.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/toast_utils.dart';
import 'settings_page.dart';


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
  bool _isInputExpanded = false;

  final GlobalKey<_SyncIconWidgetState> _syncIconKey = GlobalKey<_SyncIconWidgetState>();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        // Automatically collapse if focus is lost and input is empty
        if (!_focusNode.hasFocus && _controller.text.trim().isEmpty) {
          _isInputExpanded = false;
        }
      });
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
        _isInputExpanded = false;
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
    String tempDescription = '';
    bool showNoteInput = false;
    final noteFocusNode = FocusNode();
        final noteController = TextEditingController(text: tempDescription);
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

            void updateNoteFocus() {
              if (mounted) {
                setState(() {
                });
              }
            }
            noteFocusNode.removeListener(updateNoteFocus);
            noteFocusNode.addListener(updateNoteFocus);


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
                        padding: EdgeInsets.all((isInputFocused || noteFocusNode.hasFocus) ? 0.0 : 1.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: (isInputFocused || noteFocusNode.hasFocus)
                                ? ShadTheme.of(context).colorScheme.ring
                                : ShadTheme.of(context).colorScheme.border,
                            width: (isInputFocused || noteFocusNode.hasFocus) ? 2.0 : 1.0,
                          ),
                          borderRadius: ShadTheme.of(context).radius,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
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
                                      contentPadding: EdgeInsets.only(left: 12, right: 0, top: 11, bottom: 11),
                                      isDense: true,
                                    ),
                                    cursorColor: ShadTheme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: ShadButton.ghost(
                                      width: 32,
                                      height: 32,
                                      padding: EdgeInsets.zero,
                                      child: Icon(
                                        showNoteInput ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                        color: ShadTheme.of(context).colorScheme.mutedForeground,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showNoteInput = !showNoteInput;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (showNoteInput) ...[
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: ShadTheme.of(context).colorScheme.border.withValues(alpha: 0.5),
                              ),
                              TextField(
                                focusNode: noteFocusNode,
                                controller: noteController,
                                maxLines: null,
                                style: ShadTheme.of(context).textTheme.p.copyWith(
                                  fontSize: 13,
                                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  hintText: Translations.tr('add_note', locale),
                                  hintStyle: TextStyle(
                                    color: ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.4),
                                  ),
                                  isDense: true,
                                ),
                                cursorColor: ShadTheme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: showNoteInput ? 8 : 16),
                      if (tempSubtasks.isNotEmpty)
                        Column(
                          children: tempSubtasks.map((subtask) => Padding(
                            key: ValueKey(subtask.id),
                            padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                            child: Row(
                              children: [
                                Opacity(
                                  opacity: subtask.isCompleted ? 0.4 : 0.15,
                                  child: ShadCheckbox(
                                    value: subtask.isCompleted,
                                    onChanged: (subtask.id == tempSubtasks.last.id && subtask.title.trim().isEmpty) ? null : (v) {
                                      setState(() {
                                        final idx = tempSubtasks.indexOf(subtask);
                                        tempSubtasks[idx] = subtask.copyWith(isCompleted: v);
                                      });
                                    },
                                  ),
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
                                        color: ShadTheme.of(context).colorScheme.mutedForeground,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: Translations.tr('subtask_placeholder', locale),
                                        hintStyle: TextStyle(
                                          color: ShadTheme.of(context).colorScheme.mutedForeground.withOpacity(0.4)
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
                                  const SizedBox(width: 32, height: 32)
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
                                  description: noteController.text.trim(),
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
      noteFocusNode.dispose();
      noteController.dispose();
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
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 70.0),
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
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(
                            left: 24.0,
                            right: 24.0,
                            top: _isInputExpanded ? 24.0 : 10.0,
                            bottom: _isInputExpanded ? 12.0 : 0.0,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double targetWidth = _isInputExpanded ? constraints.maxWidth : 32.0;
                              final double targetHeight = _isInputExpanded ? 44.0 : 32.0;

                              return Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  width: targetWidth,
                                  height: targetHeight,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: (_isInputExpanded && _focusNode.hasFocus
                                              ? ShadTheme.of(context).colorScheme.ring
                                              : ShadTheme.of(context).colorScheme.border)
                                          .withOpacity(_isInputExpanded ? 1.0 : 0.0),
                                      width: _isInputExpanded && _focusNode.hasFocus ? 2.0 : 1.0,
                                    ),
                                    borderRadius: ShadTheme.of(context).radius,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: ShadTheme.of(context).radius,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Expanded State Content
                                        AnimatedOpacity(
                                          opacity: _isInputExpanded ? 1.0 : 0.0,
                                          duration: const Duration(milliseconds: 200),
                                          curve: _isInputExpanded ? const Interval(0.4, 1.0, curve: Curves.easeOut) : Curves.easeIn,
                                          child: IgnorePointer(
                                            ignoring: !_isInputExpanded,
                                            child: OverflowBox(
                                              maxWidth: constraints.maxWidth,
                                              maxHeight: 44.0,
                                              alignment: Alignment.center,
                                              child: SizedBox(
                                                width: constraints.maxWidth,
                                                height: 44.0,
                                                child: Stack(
                                                  alignment: Alignment.centerRight,
                                                  children: [
                                                    TextField(
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
                                                              LucideIcons.expand,
                                                              size: 15,
                                                              color: ShadTheme.of(context).colorScheme.mutedForeground,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          ShadButton.ghost(
                                                            onPressed: _pickDate,
                                                            height: 32,
                                                            padding: EdgeInsets.symmetric(horizontal: (_selectedDueDate != null || _isAnytimeSelected) ? 8 : 8),
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
                                            ),
                                          ),
                                        ),

                                        // Collapsed State Content (+)
                                        AnimatedOpacity(
                                          opacity: _isInputExpanded ? 0.0 : 1.0,
                                          duration: Duration(milliseconds: _isInputExpanded ? 50 : 150),
                                          curve: _isInputExpanded ? Curves.easeOut : const Interval(0.5, 1.0, curve: Curves.easeOut),
                                          child: IgnorePointer(
                                            ignoring: _isInputExpanded,
                                            child: ShadButton.ghost(
                                              width: 32,
                                              height: 32,
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                setState(() {
                                                  _isInputExpanded = true;
                                                });
                                                Future.delayed(const Duration(milliseconds: 50), () {
                                                  _focusNode.requestFocus();
                                                });
                                              },
                                              child: Icon(
                                                LucideIcons.plus,
                                                size: 16,
                                                color: ShadTheme.of(context).colorScheme.mutedForeground,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: todosAsync.when(
                            data: (allTodos) {
                              final now = DateTime.now();
                              final todayStart = DateTime(now.year, now.month, now.day);
                              final todayEnd = todayStart.add(const Duration(days: 1));

                              final uncompletedTodos = <Todo>[];
                              final completedTodayTodos = <Todo>[];

                              for (final todo in allTodos) {
                                if (!todo.isCompleted) {
                                  bool matchesTab = false;
                                  if (_currentIndex == 0) { // 今天
                                    if (todo.dueDate != null && !todo.isAnytime) {
                                      if (todo.dueDate!.isBefore(todayEnd)) {
                                        matchesTab = true; // 過期或今天之內
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
                                    uncompletedTodos.add(todo);
                                  }
                                } else {
                                  // 已完成的任務
                                  if (_currentIndex == 0) {
                                    // 在「今天」標籤，顯示所有今天打勾完成的任務（戰利品）
                                    if (todo.completedAt != null && 
                                        !todo.completedAt!.isBefore(todayStart) && 
                                        todo.completedAt!.isBefore(todayEnd)) {
                                      completedTodayTodos.add(todo);
                                    }
                                  }
                                }
                              }

                              int _compareTodos(Todo a, Todo b) {
                                if (a.dueDate != null && b.dueDate != null) {
                                  return a.dueDate!.compareTo(b.dueDate!);
                                } else if (a.dueDate != null) {
                                  return -1; // a has due date, b doesn't -> a comes first
                                } else if (b.dueDate != null) {
                                  return 1;  // b has due date, a doesn't -> b comes first
                                } else {
                                  return a.createdAt.compareTo(b.createdAt);
                                }
                              }

                              uncompletedTodos.sort(_compareTodos);
                              completedTodayTodos.sort(_compareTodos);

                              if (uncompletedTodos.isEmpty && completedTodayTodos.isEmpty) {
                                if (_currentIndex == 1) {
                                  return UpcomingEmptyWidget(
                                    title: Translations.tr('empty_upcoming_title', locale),
                                    subtitle: Translations.tr('empty_upcoming_subtitle', locale),
                                  );
                                } else if (_currentIndex == 2) {
                                  return SomedayEmptyWidget(
                                    title: Translations.tr('empty_someday_title', locale),
                                    subtitle: Translations.tr('empty_someday_subtitle', locale),
                                  );
                                } else if (_currentIndex == 3) {
                                  return AnytimeEmptyWidget(
                                    title: Translations.tr('empty_anytime_title', locale),
                                    subtitle: Translations.tr('empty_anytime_subtitle', locale),
                                  );
                                } else {
                                  return TodayEmptyWidget(
                                    title: Translations.tr('empty_today_title', locale),
                                    subtitle: Translations.tr('empty_today_subtitle', locale),
                                  );
                                }
                              }
                              
                              final showZenRing = _currentIndex == 0 && uncompletedTodos.isEmpty && completedTodayTodos.isNotEmpty;
                              
                              int itemCount = uncompletedTodos.length + (completedTodayTodos.isEmpty ? 0 : completedTodayTodos.length + 1);
                              if (showZenRing) itemCount += 1;

                              return ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  int adjustedIndex = index;
                                  
                                  if (showZenRing) {
                                    if (adjustedIndex == 0) {
                                      final subtitle = Translations.tr('completed_x_tasks', locale)
                                          .replaceAll('{count}', completedTodayTodos.length.toString());
                                      return AllDoneZenRingWidget(
                                        message: Translations.tr('all_done_today', locale),
                                        subtitle: subtitle,
                                      );
                                    }
                                    adjustedIndex -= 1;
                                  }

                                  if (adjustedIndex < uncompletedTodos.length) {
                                    return TodoItemWidget(
                                      key: ValueKey(uncompletedTodos[adjustedIndex].id),
                                      todo: uncompletedTodos[adjustedIndex],
                                    );
                                  }
                                  
                                  final completedIndex = adjustedIndex - uncompletedTodos.length;
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
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox(
                  height: 60.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            'Zenist.',
                            style: ShadTheme.of(context).textTheme.h2.copyWith(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 32,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SyncIconWidget(key: _syncIconKey),
                            const SizedBox(width: 4),
                            ShadButton.ghost(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              },
                              width: 36,
                              height: 36,
                              padding: EdgeInsets.zero,
                              child: const Icon(LucideIcons.settings, size: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _SyncIconWidget extends ConsumerStatefulWidget {
  const _SyncIconWidget({super.key});

  @override
  ConsumerState<_SyncIconWidget> createState() => _SyncIconWidgetState();
}

class _SyncIconWidgetState extends ConsumerState<_SyncIconWidget> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.3,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    final syncState = ref.watch(autoSyncManagerProvider);
    
    if (syncState == SyncState.manual) {
      _pulseController.stop();
      _rotationController.repeat();
    } else if (syncState == SyncState.auto) {
      _rotationController.stop();
      _pulseController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _rotationController.reset();
      _pulseController.stop();
      _pulseController.value = 1.0;
    }

    IconData iconData;
    Color? iconColor;

    if (!isLoggedIn) {
      iconData = LucideIcons.cloudOff;
      iconColor = ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5);
    } else if (syncState == SyncState.manual) {
      iconData = LucideIcons.loader2;
      iconColor = ShadTheme.of(context).colorScheme.primary;
    } else if (syncState == SyncState.auto) {
      iconData = LucideIcons.cloud;
      iconColor = ShadTheme.of(context).colorScheme.primary;
    } else {
      iconData = LucideIcons.cloud;
      iconColor = ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5);
    }

    Widget iconWidget = Icon(iconData, size: 24, color: iconColor);

    if (syncState == SyncState.manual) {
      iconWidget = RotationTransition(
        turns: _rotationController,
        child: iconWidget,
      );
    } else if (syncState == SyncState.auto) {
      iconWidget = FadeTransition(
        opacity: _pulseController,
        child: iconWidget,
      );
    }

    return ShadButton.ghost(
      onPressed: () {
        if (!isLoggedIn) {
          ToastUtils.show(context, '請先前往「設置」頁面登入 Dropbox 以啟用雲端同步功能。');
        } else if (syncState == SyncState.idle) {
          ref.read(autoSyncManagerProvider.notifier).manualSync();
        }
      },
      width: 36,
      height: 36,
      padding: EdgeInsets.zero,
      child: iconWidget,
    );
  }
}

