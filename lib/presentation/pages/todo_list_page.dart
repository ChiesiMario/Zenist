import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';

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
      ref.read(todoNotifierProvider.notifier).addTodo(
        text, 
        dueDate: _selectedDueDate,
        isAnytime: _isAnytimeSelected,
      );
      _controller.clear();
      setState(() {
        _selectedDueDate = null;
        _isAnytimeSelected = false;
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
    // 為了避免與鍵盤搶空間，先移除焦點
    _focusNode.unfocus();
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: ShadTheme.of(context).colorScheme.background,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: ShadTheme.of(context).radius,
            side: BorderSide(color: ShadTheme.of(context).colorScheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadCalendar(
                  selected: _selectedDueDate,
                  onChanged: (v) {
                    Navigator.of(context).pop(v);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton.outline(
                    onPressed: () {
                      Navigator.of(context).pop('anytime');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.infinity, size: 16),
                        SizedBox(width: 8.0),
                        Text('設為隨時'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    if (result != null) {
      setState(() {
        if (result == 'anytime') {
          _isAnytimeSelected = true;
          _selectedDueDate = null;
        } else if (result is DateTime) {
          _isAnytimeSelected = false;
          _selectedDueDate = result;
        }
      });
      // 選完日期後可以選擇把焦點還給輸入框
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoListStreamProvider);

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
                                    hintText: 'Add a new task...',
                                    hintStyle: ShadTheme.of(context).textTheme.p.copyWith(
                                      color: ShadTheme.of(context).colorScheme.mutedForeground,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(left: 12, right: 80, top: 11, bottom: 11),
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
                                      onPressed: _pickDate,
                                      width: 32,
                                      height: 32,
                                      padding: EdgeInsets.zero,
                                      child: Icon(
                                        _isAnytimeSelected ? LucideIcons.infinity : LucideIcons.calendar,
                                        size: 16,
                                        color: (_selectedDueDate != null || _isAnytimeSelected)
                                            ? ShadTheme.of(context).colorScheme.primary
                                            : ShadTheme.of(context).colorScheme.mutedForeground,
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

                              final todos = allTodos.where((todo) {
                                if (_currentIndex == 0) { // 今天
                                  if (todo.dueDate == null || todo.isAnytime) return false;
                                  if (todo.dueDate!.isBefore(todayStart)) {
                                    return !todo.isCompleted; // 過期但未完成
                                  }
                                  return todo.dueDate!.isBefore(todayEnd); // 今天之內
                                } else if (_currentIndex == 1) { // 未來
                                  if (todo.dueDate == null || todo.isAnytime) return false;
                                  return todo.dueDate!.isAfter(todayEnd.subtract(const Duration(milliseconds: 1)));
                                } else if (_currentIndex == 2) { // 某天
                                  return todo.dueDate == null && !todo.isAnytime;
                                } else if (_currentIndex == 3) { // 隨時
                                  return todo.isAnytime;
                                }
                                return false;
                              }).toList();

                              if (todos.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No tasks yet.\nEnjoy the emptiness.',
                                    textAlign: TextAlign.center,
                                    style: ShadTheme.of(context).textTheme.p.copyWith(
                                          height: 1.5,
                                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                                        ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                                itemCount: todos.length,
                                itemBuilder: (context, index) {
                                  return TodoItemWidget(
                                    key: ValueKey(todos[index].id),
                                    todo: todos[index]
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
          // Glassmorphism Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 16,
                    left: 24,
                    right: 24,
                  ),
                  color: ShadTheme.of(context).colorScheme.background.withOpacity(0.7),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Zenist.', style: ShadTheme.of(context).textTheme.h4.copyWith(fontWeight: FontWeight.w700)),
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
                            _buildNavItem(0, Icons.wb_sunny_outlined, Icons.wb_sunny, '今天'),
                            _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, '未來'),
                            _buildNavItem(2, Icons.inbox_outlined, Icons.inbox, '某天'),
                            _buildNavItem(3, Icons.all_inclusive_outlined, Icons.all_inclusive, '隨時'),
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
