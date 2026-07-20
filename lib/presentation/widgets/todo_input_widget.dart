import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';

import '../providers/todo_provider.dart';
import '../providers/settings_provider.dart';
import '../../core/localization/translations.dart';
import '../../core/utils/date_formatter.dart';
import 'todo_editor_dialog.dart';

class TodoInputWidget extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<bool>? onExpandedChanged;

  const TodoInputWidget({
    super.key,
    required this.currentIndex,
    this.onExpandedChanged,
  });

  @override
  ConsumerState<TodoInputWidget> createState() => _TodoInputWidgetState();
}

class _TodoInputWidgetState extends ConsumerState<TodoInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DateTime? _selectedDueDate;
  bool _isAnytimeSelected = false;
  bool _isRepeatEnabled = false;
  int _repeatInterval = 1;
  String _repeatUnit = 'week';
  bool _isInputExpanded = false;
  bool _isDialogShowing = false;

  void _setExpanded(bool expanded) {
    if (_isInputExpanded != expanded) {
      setState(() {
        _isInputExpanded = expanded;
      });
      widget.onExpandedChanged?.call(expanded);
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted &&
              !_focusNode.hasFocus &&
              _controller.text.trim().isEmpty &&
              !_isDialogShowing) {
            _setExpanded(false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      DateTime? finalDueDate = _selectedDueDate;
      bool finalIsAnytime = _isAnytimeSelected;

      // 如果沒有手動選擇日期，且當前位於「今天」或「隨時」分頁，則自動繼承該分頁的屬性
      if (finalDueDate == null && !finalIsAnytime) {
        if (widget.currentIndex == 0) {
          finalDueDate = DateTime.now();
        } else if (widget.currentIndex == 3) {
          finalIsAnytime = true;
        }
      }

      ref.read(todoNotifierProvider.notifier).addTodo(
            text,
            dueDate: finalDueDate,
            isAnytime: finalIsAnytime,
            repeatInterval: (_isRepeatEnabled && !finalIsAnytime)
                ? _repeatInterval
                : null,
            repeatUnit: (_isRepeatEnabled && !finalIsAnytime) ? _repeatUnit : null,
          );
      _controller.clear();
      _setExpanded(false);
      setState(() {
        _selectedDueDate = null;
        _isAnytimeSelected = false;
        _isRepeatEnabled = false;
        _repeatInterval = 1;
        _repeatUnit = 'week';
      });
    }
  }

  Future<void> _pickDate() async {
    _isDialogShowing = true;
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
                                      const Icon(
                                        LucideIcons.infinity,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        Translations.tr(
                                          'tab_anytime',
                                          ref.read(settingsProvider).locale,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        LucideIcons.infinity,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        Translations.tr(
                                          'tab_anytime',
                                          ref.read(settingsProvider).locale,
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
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 40,
                                  width: 84,
                                  child: dialogRepeat
                                      ? ShadButton(
                                          padding: const EdgeInsets.symmetric(
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
                                              ref.read(settingsProvider).locale,
                                            ),
                                          ),
                                        )
                                      : ShadButton.outline(
                                          padding: const EdgeInsets.symmetric(
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
                                              ref.read(settingsProvider).locale,
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
                                              initialValue:
                                                  dialogInterval.toString(),
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
                                                  ShadOption(
                                                    value: 'day',
                                                    child: Text(
                                                      Translations.tr(
                                                        'unit_day',
                                                        ref
                                                            .read(
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
                                                            .read(
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
                                                            .read(
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
                                                            .read(
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
                                                selectedOptionBuilder:
                                                    (context, value) {
                                                  switch (value) {
                                                    case 'day':
                                                      return Text(
                                                        Translations.tr(
                                                          'unit_day',
                                                          ref
                                                              .read(
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
                                                              .read(
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
                                                              .read(
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
                                                              .read(
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
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (dialogDate != null || dialogAnytime)
                              ShadButton.ghost(
                                onPressed: () =>
                                    Navigator.of(context).pop({'clear': true}),
                                child: Text(
                                  Translations.tr(
                                    'clear_date',
                                    ref.read(settingsProvider).locale,
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
                                      ref.read(settingsProvider).locale,
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
                                      ref.read(settingsProvider).locale,
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

    _isDialogShowing = false;
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
    } else {
      if (_controller.text.trim().isEmpty) {
        setState(() {
          _isInputExpanded = false;
        });
      } else {
        _focusNode.requestFocus();
      }
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
        return unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsProvider).locale;

    return AnimatedPadding(
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
          final double targetWidth =
              _isInputExpanded ? constraints.maxWidth : 32.0;
          final double targetHeight = _isInputExpanded ? 44.0 : 32.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: _isInputExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShadButton.ghost(
                              onPressed: _pickDate,
                              height: 32,
                              padding: EdgeInsets.symmetric(
                                horizontal: (_selectedDueDate != null ||
                                        _isAnytimeSelected)
                                    ? 8
                                    : 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isAnytimeSelected
                                        ? LucideIcons.infinity
                                        : LucideIcons.calendar,
                                    size: 16,
                                    color: (_selectedDueDate != null ||
                                            _isAnytimeSelected)
                                        ? ShadTheme.of(context).colorScheme.primary
                                        : ShadTheme.of(context).colorScheme.mutedForeground,
                                  ),
                                  if (_isAnytimeSelected || _selectedDueDate != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      (() {
                                        String dateStr = '';
                                        if (_isAnytimeSelected || _selectedDueDate != null) {
                                          dateStr = DateFormatter.getRelativeDateString(
                                            date: _selectedDueDate,
                                            locale: locale,
                                            dateFormat: ref.watch(settingsProvider).dateFormat,
                                            isAnytime: _isAnytimeSelected,
                                            includeAbsolute: false,
                                          );
                                        }
                                        if (_isRepeatEnabled) {
                                          final repeatStr = '${Translations.tr('every', locale)}$_repeatInterval ${_getRepeatUnitLabel(_repeatUnit, locale)}';
                                          return '$dateStr · $repeatStr';
                                        }
                                        return dateStr;
                                      })(),
                                      style: TextStyle(
                                        color: ShadTheme.of(context).colorScheme.primary,
                                        fontSize: 13,
                                        height: 1.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ShadButton.ghost(
                              onPressed: () async {
                                _isDialogShowing = true;
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => TodoEditorDialog(
                                    initialTitle: _controller.text,
                                    initialDate: _selectedDueDate,
                                  ),
                                );
                                _isDialogShowing = false;
                                if (_controller.text.trim().isEmpty) {
                                  _setExpanded(false);
                                } else {
                                  _focusNode.requestFocus();
                                }
                              },
                              height: 32,
                              width: 32,
                              padding: EdgeInsets.zero,
                              child: Icon(
                                LucideIcons.expand,
                                size: 15,
                                color: ShadTheme.of(context).colorScheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Center(
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
                          .withOpacity(
                        _isInputExpanded ? 1.0 : 0.0,
                      ),
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
                      curve: _isInputExpanded
                          ? const Interval(0.4, 1.0, curve: Curves.easeOut)
                          : Curves.easeIn,
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
                                  style: ShadTheme.of(context)
                                      .textTheme
                                      .p
                                      .copyWith(
                                        fontSize: 14,
                                      ),
                                  decoration: InputDecoration(
                                    hintText: Translations.tr(
                                      'add_new_task',
                                      locale,
                                    ),
                                    hintStyle: ShadTheme.of(context)
                                        .textTheme
                                        .p
                                        .copyWith(
                                          color: ShadTheme.of(context)
                                              .colorScheme
                                              .mutedForeground,
                                          fontSize: 14,
                                        ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(
                                      left: 12,
                                      right: 44,
                                      top: 11,
                                      bottom: 11,
                                    ),
                                    isDense: true,
                                  ),
                                  cursorColor: ShadTheme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                                Positioned(
                                  right: 6,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ShadButton.ghost(
                                        onPressed: _submit,
                                        width: 32,
                                        height: 32,
                                        padding: EdgeInsets.zero,
                                        child: const Icon(
                                          LucideIcons.arrowUp,
                                          size: 16,
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

                    // Collapsed State Content (+)
                    AnimatedOpacity(
                      opacity: _isInputExpanded ? 0.0 : 1.0,
                      duration: Duration(
                        milliseconds: _isInputExpanded ? 50 : 150,
                      ),
                      curve: _isInputExpanded
                          ? Curves.easeOut
                          : const Interval(0.5, 1.0, curve: Curves.easeOut),
                      child: IgnorePointer(
                        ignoring: _isInputExpanded,
                        child: ShadButton.ghost(
                          width: 32,
                          height: 32,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _setExpanded(true);
                            setState(() {
                              if (widget.currentIndex == 0) {
                                _selectedDueDate = DateTime.now();
                                _isAnytimeSelected = false;
                              } else if (widget.currentIndex == 3) {
                                _selectedDueDate = null;
                                _isAnytimeSelected = true;
                              } else {
                                _selectedDueDate = null;
                                _isAnytimeSelected = false;
                              }
                            });
                            Future.delayed(
                              const Duration(milliseconds: 50),
                              () {
                                _focusNode.requestFocus();
                              },
                            );
                          },
                          child: Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: ShadTheme.of(context)
                                .colorScheme
                                .mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isInputExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 28.0),
                        child: Divider(
                          height: 1,
                          color: ShadTheme.of(context).colorScheme.border,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}
