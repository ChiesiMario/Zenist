import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../core/localization/translations.dart';
import '../../domain/entities/todo.dart';
import '../providers/settings_provider.dart';
import '../providers/todo_provider.dart';
import '../../application/services/audio_service.dart';
import 'animated_path_checkbox.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/date_formatter.dart';
class TodoEditorDialog extends ConsumerStatefulWidget {
  final Todo? existingTodo;
  final String? initialTitle;
  final DateTime? initialDate;

  const TodoEditorDialog({
    super.key,
    this.existingTodo,
    this.initialTitle,
    this.initialDate,
  });

  @override
  ConsumerState<TodoEditorDialog> createState() => _TodoEditorDialogState();
}

class _TodoEditorDialogState extends ConsumerState<TodoEditorDialog> {
  late TextEditingController textController;
  final focusNode = FocusNode();
  final noteFocusNode = FocusNode();
  late TextEditingController noteController;
  final _scrollController = ScrollController();

  DateTime? tempDueDate;
  bool isConfirmingDelete = false;
  int deleteConfirmId = 0;
  bool isInputFocused = false;
  bool tempIsAnytime = false;
  bool tempRepeatEnabled = false;
  int tempRepeatInterval = 1;
  String tempRepeatUnit = 'week';
  bool showNoteInput = false;
  List<Subtask> tempSubtasks = [];
  bool _isInitialLoad = true;

  bool get _isOverdue {
    if (tempIsAnytime || tempDueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(tempDueDate!.year, tempDueDate!.month, tempDueDate!.day);
    return date.isBefore(today);
  }
  @override
  void initState() {
    super.initState();
    final todo = widget.existingTodo;
    if (todo != null) {
      textController = TextEditingController(text: todo.title);
      tempDueDate = todo.dueDate;
      tempIsAnytime = todo.isAnytime;
      tempRepeatEnabled = todo.repeatInterval != null;
      tempRepeatInterval = todo.repeatInterval ?? 1;
      tempRepeatUnit = todo.repeatUnit ?? 'week';
      final tempDescription = todo.description;
      showNoteInput = tempDescription.isNotEmpty;
      noteController = TextEditingController(text: tempDescription);
      tempSubtasks = List.from(todo.subtasks);
    } else {
      textController = TextEditingController(text: widget.initialTitle ?? '');
      tempDueDate = widget.initialDate;
      noteController = TextEditingController();
    }

    if (tempSubtasks.isEmpty || tempSubtasks.last.title.trim().isNotEmpty) {
      tempSubtasks.add(Subtask(id: const Uuid().v4(), title: ''));
    }

    focusNode.addListener(_updateFocus);
    noteFocusNode.addListener(_updateNoteFocus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  void dispose() {
    focusNode.removeListener(_updateFocus);
    noteFocusNode.removeListener(_updateNoteFocus);
    focusNode.dispose();
    noteFocusNode.dispose();
    textController.dispose();
    noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFocus() {
    if (mounted) {
      setState(() {
        isInputFocused = focusNode.hasFocus;
      });
    }
  }

  void _updateNoteFocus() {
    if (mounted) {
      setState(() {});
    }
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

  Widget _buildHistoryIcons() {
    final todo = widget.existingTodo;
    if (todo == null || todo.repeatInterval == null || todo.completionHistory.isEmpty) {
      return const SizedBox();
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxIcons = (constraints.maxWidth / 18.0).floor();
          if (maxIcons <= 0) return const SizedBox();
          
          final records = todo.completionHistory.reversed.take(maxIcons).toList().reversed.toList();
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: records.map((record) {
              bool isSuccess = true;
              if (record.expectedDueDate != null) {
                final completed = record.completedAt;
                final expected = record.expectedDueDate!;
                final completedDate = DateTime(completed.year, completed.month, completed.day);
                final expectedDate = DateTime(expected.year, expected.month, expected.day);
                isSuccess = !completedDate.isAfter(expectedDate);
              }
              final iconColor = ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.3);
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: isSuccess 
                  ? Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.check, size: 10, color: ShadTheme.of(context).colorScheme.background),
                      ),
                    )
                  : Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border.all(color: iconColor),
                        shape: BoxShape.circle,
                      ),
                    ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

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
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF18181B)
                  : ShadTheme.of(context).colorScheme.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: ShadTheme.of(context).radius,
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : ShadTheme.of(context).colorScheme.border,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 310,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SizedBox(
                            width: 310,
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                LucideIcons.infinity,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8.0),
                                              Text(
                                                Translations.tr(
                                                  'tab_anytime',
                                                  ref
                                                      .watch(settingsProvider)
                                                      .locale,
                                                ),
                                              ),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                LucideIcons.infinity,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8.0),
                                              Text(
                                                Translations.tr(
                                                  'tab_anytime',
                                                  ref
                                                      .watch(settingsProvider)
                                                      .locale,
                                                ),
                                              ),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              onPressed: () {
                                                setStateDialog(() {
                                                  dialogRepeat = false;
                                                });
                                              },
                                              child: Text(
                                                Translations.tr(
                                                  'repeat',
                                                  ref
                                                      .watch(settingsProvider)
                                                      .locale,
                                                ),
                                              ),
                                            )
                                          : ShadButton.outline(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              onPressed: () {
                                                setStateDialog(() {
                                                  dialogRepeat = true;
                                                });
                                              },
                                              child: Text(
                                                Translations.tr(
                                                  'repeat',
                                                  ref
                                                      .watch(settingsProvider)
                                                      .locale,
                                                ),
                                              ),
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
                                                  initialValue: dialogInterval
                                                      .toString(),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (v) {
                                                    final val = int.tryParse(v);
                                                    if (val != null &&
                                                        val > 0) {
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
                                                      ShadOption(
                                                        value: 'day',
                                                        child: Text(
                                                          Translations.tr(
                                                            'unit_day',
                                                            ref
                                                                .watch(
                                                                  settingsProvider,
                                                                )
                                                                .locale,
                                                          ),
                                                        ),
                                                      ),
                                                      ShadOption(
                                                        value: 'week',
                                                        child: Text(
                                                          Translations.tr(
                                                            'unit_week',
                                                            ref
                                                                .watch(
                                                                  settingsProvider,
                                                                )
                                                                .locale,
                                                          ),
                                                        ),
                                                      ),
                                                      ShadOption(
                                                        value: 'month',
                                                        child: Text(
                                                          Translations.tr(
                                                            'unit_month',
                                                            ref
                                                                .watch(
                                                                  settingsProvider,
                                                                )
                                                                .locale,
                                                          ),
                                                        ),
                                                      ),
                                                      ShadOption(
                                                        value: 'year',
                                                        child: Text(
                                                          Translations.tr(
                                                            'unit_year',
                                                            ref
                                                                .watch(
                                                                  settingsProvider,
                                                                )
                                                                .locale,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (v) {
                                                      if (v != null) {
                                                        setStateDialog(() {
                                                          dialogUnit = v;
                                                        });
                                                        FocusScope.of(
                                                          context,
                                                        ).unfocus();
                                                      }
                                                    },
                                                    selectedOptionBuilder: (context, value) {
                                                      switch (value) {
                                                        case 'day':
                                                          return Text(
                                                            Translations.tr(
                                                              'unit_day',
                                                              ref
                                                                  .watch(
                                                                    settingsProvider,
                                                                  )
                                                                  .locale,
                                                            ),
                                                          );
                                                        case 'week':
                                                          return Text(
                                                            Translations.tr(
                                                              'unit_week',
                                                              ref
                                                                  .watch(
                                                                    settingsProvider,
                                                                  )
                                                                  .locale,
                                                            ),
                                                          );
                                                        case 'month':
                                                          return Text(
                                                            Translations.tr(
                                                              'unit_month',
                                                              ref
                                                                  .watch(
                                                                    settingsProvider,
                                                                  )
                                                                  .locale,
                                                            ),
                                                          );
                                                        case 'year':
                                                          return Text(
                                                            Translations.tr(
                                                              'unit_year',
                                                              ref
                                                                  .watch(
                                                                    settingsProvider,
                                                                  )
                                                                  .locale,
                                                            ),
                                                          );
                                                        default:
                                                          return const Text('');
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
                                onPressed: () =>
                                    Navigator.of(context).pop({'clear': true}),
                                child: Text(
                                  Translations.tr(
                                    'clear_date',
                                    ref.watch(settingsProvider).locale,
                                  ),
                                  style: TextStyle(
                                    color: ShadTheme.of(
                                      context,
                                    ).colorScheme.mutedForeground,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShadButton.ghost(
                                  onPressed: () =>
                                      Navigator.of(context).pop(null),
                                  child: Text(
                                    Translations.tr(
                                      'cancel',
                                      ref.watch(settingsProvider).locale,
                                    ),
                                  ),
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
                                  child: Text(
                                    Translations.tr(
                                      'confirm',
                                      ref.watch(settingsProvider).locale,
                                    ),
                                  ),
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
          },
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale;
    final isEdit = widget.existingTodo != null;

    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF18181B)
          : ShadTheme.of(context).colorScheme.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit
                        ? Translations.tr('edit', locale)
                        : Translations.tr('add_new_task', locale),
                    style: ShadTheme.of(context).textTheme.h4,
                  ),
                  if (isEdit)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerRight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        layoutBuilder:
                            (
                              Widget? currentChild,
                              List<Widget> previousChildren,
                            ) {
                              return Stack(
                                alignment: Alignment.centerRight,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                        child: isConfirmingDelete
                            ? ShadButton.destructive(
                                key: const ValueKey('confirm'),
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(Translations.tr('confirm', locale)),
                                onPressed: () {
                                  ref
                                      .read(todoNotifierProvider.notifier)
                                      .deleteTodo(widget.existingTodo!.id);
                                  Navigator.of(context).pop();
                                },
                              )
                            : ShadButton.ghost(
                                key: const ValueKey('delete'),
                                width: 32,
                                height: 32,
                                padding: EdgeInsets.zero,
                                child: Icon(
                                  LucideIcons.trash2,
                                  color: ShadTheme.of(
                                    context,
                                  ).colorScheme.mutedForeground,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isConfirmingDelete = true;
                                  });
                                  final currentId = ++deleteConfirmId;
                                  Future.delayed(
                                    const Duration(seconds: 3),
                                    () {
                                      if (mounted &&
                                          currentId == deleteConfirmId) {
                                        setState(() {
                                          isConfirmingDelete = false;
                                        });
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                ],
              ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                    controller: _scrollController,
                      padding: const EdgeInsets.only(left: 24, right: 21),
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHistoryIcons(),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: InkWell(
                          onTap: pickDate,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, 0.5),
                                  child: Icon(
                                    tempIsAnytime
                                        ? LucideIcons.infinity
                                        : LucideIcons.calendar,
                                    size: 14,
                                    color: _isOverdue
                                        ? ShadTheme.of(context).colorScheme.destructive
                                        : ShadTheme.of(context).colorScheme.mutedForeground,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    (() {
                                      String dateStr = '';
                                      if (tempIsAnytime || tempDueDate != null) {
                                        dateStr = DateFormatter.getRelativeDateString(
                                          date: tempDueDate,
                                          locale: locale,
                                          dateFormat: ref.watch(settingsProvider).dateFormat,
                                          isAnytime: tempIsAnytime,
                                          includeAbsolute: true,
                                        );
                                      } else {
                                        dateStr = Translations.tr(
                                          'set_due_date',
                                          locale,
                                        );
                                      }

                                      if (tempRepeatEnabled) {
                                        final repeatStr =
                                            '${Translations.tr('every', locale)}$tempRepeatInterval ${_getRepeatUnitLabel(tempRepeatUnit, locale)}';
                                        return '$dateStr · $repeatStr';
                                      }

                                      return dateStr;
                                    })(),
                                    style: ShadTheme.of(
                                      context,
                                    ).textTheme.muted.copyWith(
                                      fontSize: 13,
                                      height: 1.0,
                                      color: _isOverdue ? ShadTheme.of(context).colorScheme.destructive : ShadTheme.of(context).colorScheme.mutedForeground,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(
                          (isInputFocused || noteFocusNode.hasFocus) ? 0.0 : 1.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: (isInputFocused || noteFocusNode.hasFocus)
                                ? ShadTheme.of(context).colorScheme.ring
                                : ShadTheme.of(context).colorScheme.border,
                            width: (isInputFocused || noteFocusNode.hasFocus)
                                ? 2.0
                                : 1.0,
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
                                    autofocus: !isEdit,
                                    maxLines: null,
                                    style: ShadTheme.of(
                                      context,
                                    ).textTheme.p.copyWith(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: isEdit
                                          ? null
                                          : Translations.tr('add_new_task', locale),
                                      hintStyle: TextStyle(
                                        color: ShadTheme.of(context)
                                            .colorScheme
                                            .mutedForeground
                                            .withValues(alpha: 0.4),
                                      ),
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.only(
                                        left: 12,
                                        right: 0,
                                        top: 11,
                                        bottom: 11,
                                      ),
                                      isDense: true,
                                    ),
                                    cursorColor: ShadTheme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                        showNoteInput
                                            ? LucideIcons.chevronUp
                                            : LucideIcons.chevronDown,
                                        color: ShadTheme.of(
                                          context,
                                        ).colorScheme.mutedForeground,
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
                                color: ShadTheme.of(
                                  context,
                                ).colorScheme.border.withValues(alpha: 0.5),
                              ),
                              TextField(
                                focusNode: noteFocusNode,
                                controller: noteController,
                                maxLines: null,
                                style: ShadTheme.of(context).textTheme.p.copyWith(
                                  fontSize: 12,
                                  color: ShadTheme.of(
                                    context,
                                  ).colorScheme.mutedForeground,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  hintText: Translations.tr('add_note', locale),
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: ShadTheme.of(context)
                                        .colorScheme
                                        .mutedForeground
                                        .withValues(alpha: 0.4),
                                  ),
                                  isDense: true,
                                ),
                                cursorColor: ShadTheme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (tempSubtasks.isNotEmpty)
                        Column(
                          children: tempSubtasks
                              .map(
                                (subtask) => Padding(
                                  key: ValueKey(subtask.id),
                                  padding: const EdgeInsets.only(
                                    bottom: 4.0,
                                    left: 12.0,
                                    right: 12.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Transform.translate(
                                        offset: const Offset(-8.0, 1.0),
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: (subtask.id == tempSubtasks.last.id && subtask.title.trim().isEmpty) ? null : () {
                                            if (!subtask.isCompleted) {
                                              ref.read(audioServiceProvider).playTaskCompleteSound();
                                            }
                                            setState(() {
                                              final idx = tempSubtasks.indexOf(subtask);
                                              tempSubtasks[idx] = subtask.copyWith(isCompleted: !subtask.isCompleted);
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                                            child: MouseRegion(
                                              cursor: (subtask.id == tempSubtasks.last.id && subtask.title.trim().isEmpty) ? SystemMouseCursors.basic : SystemMouseCursors.click,
                                              child: Opacity(
                                                opacity: subtask.isCompleted ? 0.4 : 0.15,
                                                child: AnimatedPathCheckbox(
                                                  value: subtask.isCompleted,
                                                  onChanged: null,
                                                  activeColor: ShadTheme.of(context).colorScheme.primary,
                                                  inactiveColor: ShadTheme.of(context).colorScheme.primary,
                                                  checkColor: ShadTheme.of(context).colorScheme.primaryForeground,
                                                  duration: Duration.zero,
                                                  isCircular: true,
                                                  size: 14.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Focus(
                                          onKeyEvent: (node, event) {
                                            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                                              if (!HardwareKeyboard.instance.isShiftPressed) {
                                                node.unfocus();
                                                return KeyEventResult.handled;
                                              }
                                            }
                                            return KeyEventResult.ignored;
                                          },
                                          onFocusChange: (hasFocus) {
                                            if (!hasFocus) {
                                              final idx = tempSubtasks.indexWhere(
                                                (s) => s.id == subtask.id,
                                              );
                                              if (idx != -1) {
                                                final currentSubtask =
                                                    tempSubtasks[idx];
                                                if (idx == tempSubtasks.length - 1 &&
                                                    currentSubtask.title
                                                        .trim()
                                                        .isNotEmpty) {
                                                  setState(() {
                                                    tempSubtasks.add(
                                                      Subtask(
                                                        id: const Uuid().v4(),
                                                        title: '',
                                                      ),
                                                    );
                                                  });
                                                }
                                              }
                                            }
                                          },
                                          child: TextFormField(
                                            initialValue: subtask.title,
                                            autofocus: !_isInitialLoad && subtask.title.isEmpty,
                                            maxLines: null,
                                            style: ShadTheme.of(context).textTheme.p.copyWith(
                                              decoration: subtask.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: ShadTheme.of(
                                                context,
                                              ).colorScheme.mutedForeground,
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              hintText: Translations.tr(
                                                'subtask_placeholder',
                                                locale,
                                              ),
                                              hintStyle: ShadTheme.of(context).textTheme.p.copyWith(
                                                color: ShadTheme.of(context)
                                                    .colorScheme
                                                    .mutedForeground
                                                    .withValues(alpha: 0.4),
                                                fontSize: 13,
                                              ),
                                            ),
                                            onChanged: (v) {
                                              final idx = tempSubtasks.indexWhere(
                                                (s) => s.id == subtask.id,
                                              );
                                              if (idx != -1) {
                                                tempSubtasks[idx] = tempSubtasks[idx]
                                                    .copyWith(title: v);
                                              }
                                            },
                                            onFieldSubmitted: (v) {
                                              final idx = tempSubtasks.indexWhere(
                                                (s) => s.id == subtask.id,
                                              );
                                              if (idx == tempSubtasks.length - 1 &&
                                                  v.trim().isNotEmpty) {
                                                setState(() {
                                                  tempSubtasks[idx] = tempSubtasks[idx]
                                                      .copyWith(title: v);
                                                  tempSubtasks.add(
                                                    Subtask(
                                                      id: const Uuid().v4(),
                                                      title: '',
                                                    ),
                                                  );
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      if (subtask.id == tempSubtasks.last.id &&
                                          subtask.title.trim().isEmpty)
                                        const SizedBox(width: 32, height: 32)
                                      else
                                        ShadButton.ghost(
                                          width: 32,
                                          height: 32,
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() {
                                              tempSubtasks.removeWhere(
                                                (s) => s.id == subtask.id,
                                              );
                                              if (tempSubtasks.isEmpty ||
                                                  tempSubtasks.last.title
                                                      .trim()
                                                      .isNotEmpty) {
                                                tempSubtasks.add(
                                                  Subtask(
                                                    id: const Uuid().v4(),
                                                    title: '',
                                                  ),
                                                );
                                              }
                                            });
                                          },
                                          child: Icon(
                                            LucideIcons.x,
                                            size: 16,
                                            color: ShadTheme.of(
                                              context,
                                            ).colorScheme.mutedForeground,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
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
                          final validSubtasks = tempSubtasks
                              .where((s) => s.title.trim().isNotEmpty)
                              .toList();
                          if (isEdit) {
                            ref
                                .read(todoNotifierProvider.notifier)
                                .updateTodoDetails(
                                  widget.existingTodo!,
                                  newTitle,
                                  tempDueDate,
                                  description: noteController.text.trim(),
                                  isAnytime: tempIsAnytime,
                                  repeatInterval: tempRepeatEnabled
                                      ? tempRepeatInterval
                                      : null,
                                  repeatUnit: tempRepeatEnabled
                                      ? tempRepeatUnit
                                      : null,
                                  newSubtasks: validSubtasks,
                                );
                          } else {
                            ref
                                .read(todoNotifierProvider.notifier)
                                .addTodo(
                                  newTitle,
                                  dueDate: tempDueDate,
                                  description: noteController.text.trim(),
                                  isAnytime: tempIsAnytime,
                                  repeatInterval: tempRepeatEnabled
                                      ? tempRepeatInterval
                                      : null,
                                  repeatUnit: tempRepeatEnabled
                                      ? tempRepeatUnit
                                      : null,
                                  subtasks: validSubtasks,
                                );
                          }
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
