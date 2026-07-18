import 'package:flutter/material.dart';
import '../widgets/todo_editor_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../widgets/sync_icon_widget.dart';
import '../widgets/todo_bottom_navigation.dart';
import '../widgets/todo_input_widget.dart';
import 'settings_page.dart';

sealed class ListItem {
  String get id;
}

class TodoListItem extends ListItem {
  final Todo todo;
  final bool isCompletedSection;
  
  TodoListItem(this.todo, {this.isCompletedSection = false});
  
  @override
  String get id => isCompletedSection ? '${todo.id}_completed' : '${todo.id}_uncompleted';
}

class HeaderListItem extends ListItem {
  final bool hasCompleted;
  
  HeaderListItem(this.hasCompleted);
  
  @override
  String get id => 'completed_header';
}

class ZenRingListItem extends ListItem {
  final int completedCount;
  
  ZenRingListItem(this.completedCount);
  
  @override
  String get id => 'zen_ring';
}

class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(filteredTodosProvider(_currentIndex));
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
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 70.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ShadTheme.of(context).colorScheme.card,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: _currentIndex == 0
                              ? Radius.zero
                              : const Radius.circular(12),
                          bottomRight: _currentIndex == 3
                              ? Radius.zero
                              : const Radius.circular(12),
                        ),
                        border: Border.all(
                          color: ShadTheme.of(context).colorScheme.border,
                          width: 1,
                        ),
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
                          TodoInputWidget(currentIndex: _currentIndex),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: todosAsync.when(
                                data: (filteredData) {
                                  final uncompletedTodos = filteredData.uncompleted;
                                  final completedTodayTodos = filteredData.completedToday;
if (uncompletedTodos.isEmpty &&
                                      completedTodayTodos.isEmpty) {
                                    if (_currentIndex == 1) {
                                      return UpcomingEmptyWidget(
                                        title: Translations.tr(
                                          'empty_upcoming_title',
                                          locale,
                                        ),
                                        subtitle: Translations.tr(
                                          'empty_upcoming_subtitle',
                                          locale,
                                        ),
                                      );
                                    } else if (_currentIndex == 2) {
                                      return SomedayEmptyWidget(
                                        title: Translations.tr(
                                          'empty_someday_title',
                                          locale,
                                        ),
                                        subtitle: Translations.tr(
                                          'empty_someday_subtitle',
                                          locale,
                                        ),
                                      );
                                    } else if (_currentIndex == 3) {
                                      return AnytimeEmptyWidget(
                                        title: Translations.tr(
                                          'empty_anytime_title',
                                          locale,
                                        ),
                                        subtitle: Translations.tr(
                                          'empty_anytime_subtitle',
                                          locale,
                                        ),
                                      );
                                    } else {
                                      return TodayEmptyWidget(
                                        title: Translations.tr(
                                          'empty_today_title',
                                          locale,
                                        ),
                                        subtitle: Translations.tr(
                                          'empty_today_subtitle',
                                          locale,
                                        ),
                                      );
                                    }
                                  }

                                  final showZenRing =
                                      _currentIndex == 0 &&
                                      uncompletedTodos.isEmpty &&
                                      completedTodayTodos.isNotEmpty;

                                  final showCompletedSection = _currentIndex == 0;

                                  final listItems = <ListItem>[];
                                  
                                  if (showZenRing) {
                                    listItems.add(ZenRingListItem(completedTodayTodos.length));
                                  }
                                  
                                  for (final todo in uncompletedTodos) {
                                    listItems.add(TodoListItem(todo));
                                  }
                                  
                                  if (showCompletedSection && completedTodayTodos.isNotEmpty) {
                                    listItems.add(HeaderListItem(true));
                                        
                                    for (int i = 0; i < completedTodayTodos.length; i++) {
                                      listItems.add(TodoListItem(
                                        completedTodayTodos[i],
                                        isCompletedSection: true,
                                      ));
                                    }
                                  }

                                  return ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(
                                      bottom: 24,
                                      left: 24,
                                      right: 24,
                                    ),
                                    itemCount: listItems.length,
                                    itemBuilder: (context, index) {
                                      final item = listItems[index];
                                      Widget child;
                                      if (item is ZenRingListItem) {
                                        final subtitle = Translations.tr('completed_x_tasks', locale)
                                            .replaceAll('{count}', item.completedCount.toString());
                                        child = AllDoneZenRingWidget(
                                          message: Translations.tr('all_done_today', locale),
                                          subtitle: subtitle,
                                        );
                                      } else if (item is HeaderListItem) {
                                        child = KeyedSubtree(
                                          key: const ValueKey('completed_header_full'),
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 32, bottom: 8),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Opacity(
                                                opacity: 0.6,
                                                child: Text(
                                                  Translations.tr('completed', locale),
                                                  style: ShadTheme.of(context).textTheme.large.copyWith(
                                                    color: ShadTheme.of(context).colorScheme.mutedForeground,
                                                    fontWeight: FontWeight.normal,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else if (item is TodoListItem) {
                                        child = TodoItemWidget(
                                          key: ValueKey(item.id),
                                          todo: item.todo,
                                        );
                                      } else {
                                        child = const SizedBox.shrink();
                                      }

                                      return child;
                                    },
                                  );
                                },
                                loading: () => Center(
                                  child: CircularProgressIndicator(
                                    color: ShadTheme.of(
                                      context,
                                    ).colorScheme.foreground,
                                  ),
                                ),
                                error: (err, stack) =>
                                    Center(child: Text('Error: $err')),
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
                              style: ShadTheme.of(context).textTheme.h2
                                  .copyWith(
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
                              const SyncIconWidget(),
                              const SizedBox(width: 4),
                              ShadButton.ghost(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsPage(),
                                    ),
                                  );
                                },
                                width: 36,
                                height: 36,
                                padding: EdgeInsets.zero,
                                child: const Icon(
                                  LucideIcons.settings,
                                  size: 24,
                                ),
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
      bottomNavigationBar: TodoBottomNavigation(
        currentIndex: _currentIndex,
        locale: locale,
        onIndexChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
