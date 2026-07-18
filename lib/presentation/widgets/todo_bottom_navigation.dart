import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/localization/translations.dart';

class TodoBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final String locale;
  final ValueChanged<int> onIndexChanged;

  const TodoBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.locale,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          _buildNavItem(
                            context,
                            0,
                            Icons.wb_sunny_outlined,
                            Icons.wb_sunny,
                            Translations.tr('tab_today', locale),
                          ),
                          _buildNavItem(
                            context,
                            1,
                            Icons.calendar_today_outlined,
                            Icons.calendar_today,
                            Translations.tr('tab_upcoming', locale),
                          ),
                          _buildNavItem(
                            context,
                            2,
                            Icons.inbox_outlined,
                            Icons.inbox,
                            Translations.tr('tab_someday', locale),
                          ),
                          _buildNavItem(
                            context,
                            3,
                            Icons.all_inclusive_outlined,
                            Icons.all_inclusive,
                            Translations.tr('tab_anytime', locale),
                          ),
                        ],
                      ),
                      _buildFilletsOverlay(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = currentIndex == index;
    final isLeftOfActive = index == currentIndex - 1;
    final isRightOfActive = index == currentIndex + 1;

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            transform: isActive ? Matrix4.translationValues(0, -1, 0) : null,
            decoration: BoxDecoration(
              color: isActive
                  ? ShadTheme.of(context).colorScheme.card
                  : Colors.transparent,
              borderRadius: isActive
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    )
                  : null,
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: ShadTheme.of(context).colorScheme.border,
                      ),
                      right: BorderSide(
                        color: ShadTheme.of(context).colorScheme.border,
                      ),
                      bottom: BorderSide(
                        color: ShadTheme.of(context).colorScheme.border,
                      ),
                    )
                  : null,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  onIndexChanged(index);
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
                        color: isActive
                            ? ShadTheme.of(context).colorScheme.foreground
                            : ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: isActive
                              ? ShadTheme.of(context).colorScheme.foreground
                              : ShadTheme.of(
                                  context,
                                ).colorScheme.mutedForeground,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
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

  Widget _buildFilletsOverlay(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Row(
          children: List.generate(4, (index) {
            final isLeftOfActive = index == currentIndex - 1;
            final isRightOfActive = index == currentIndex + 1;

            return Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
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
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: ShadTheme.of(context).colorScheme.border,
                                width: 1,
                              ),
                              right: BorderSide(
                                color: ShadTheme.of(context).colorScheme.border,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: ShadTheme.of(context).colorScheme.border,
                                width: 1,
                              ),
                              left: BorderSide(
                                color: ShadTheme.of(context).colorScheme.border,
                                width: 1,
                              ),
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
