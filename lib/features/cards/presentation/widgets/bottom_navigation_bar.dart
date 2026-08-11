import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../backup/presentation/backup_screen.dart';
import '../bloc/bottom_navigation/bottom_navigation_bloc.dart';
import '../bloc/bottom_navigation/bottom_navigation_event.dart';
import '../bloc/bottom_navigation/bottom_navigation_state.dart';
import '../bloc/card_overview/card_overview_bloc.dart';
import '../bloc/card_overview/card_overview_state.dart';
import '../pages/home_screen/home_screen.dart';
import '../pages/profile_screen/profile_screen.dart';
import '../pages/reminder_screen/reminder_screen.dart';

/// Four equal destinations — Cards, Reminders, Backup, You — with no centre
/// action slot. Adding a card is now a floating button on the Cards screen
/// itself (top-right, above the bar), not a slot inside the nav pill.
class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: IndexedStack(
            index: state.currentIndex,
            children: const [
              HomeScreen(),
              ReminderScreen(),
              // BackupCubit and CardOverviewBloc are already ancestors here
              // (provided at the app root and in _MainShell), so the screen
              // can sit directly in the tab stack with no extra wrapping.
              BackupScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _FloatingNavBar(
            currentIndex: state.currentIndex,
            onTabTap: (i) =>
                context.read<BottomNavigationBloc>().add(ChangeTabEvent(i)),
          ),
        );
      },
    );
  }
}

// ─── Floating pill nav bar ────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.currentIndex, required this.onTabTap});

  final int currentIndex;
  final ValueChanged<int> onTabTap;

  static const _tabs = [
    _TabData(icon: Icons.credit_card_outlined, label: 'Cards'),
    _TabData(icon: Icons.notifications_rounded, label: 'Reminders'),
    _TabData(icon: Icons.cloud_outlined, label: 'Backup'),
    _TabData(icon: Icons.person_rounded, label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      // Margin so the pill floats above the system nav bar
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : scheme.shadow)
                  .withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            // Reminders (index 1) carries a count of bills needing attention.
            // Rebuilds only on that count, via BlocSelector, not on every
            // card-list change.
            final item = i == 1
                ? BlocSelector<CardOverviewBloc, CardOverviewState, int>(
                    selector: (state) => state.actionNeededCount,
                    builder: (context, dueCount) => _NavItem(
                      data: _tabs[i],
                      isSelected: currentIndex == i,
                      onTap: () => onTabTap(i),
                      scheme: scheme,
                      badgeCount: dueCount,
                    ),
                  )
                : _NavItem(
                    data: _tabs[i],
                    isSelected: currentIndex == i,
                    onTap: () => onTabTap(i),
                    scheme: scheme,
                  );
            return Expanded(child: Center(child: item));
          }),
        ),
      ),
    );
  }
}

// ─── Individual nav tab item ──────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.scheme,
    this.badgeCount = 0,
  });

  final _TabData data;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  /// Count shown on the icon. Zero hides the badge entirely — a badge reading
  /// "0" is noise, and the point of one is to be noticed.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    // The selected tab is a solid dark pill with light content — inverseSurface
    // / onInverseSurface is the exact Material pairing for that contrast, and
    // it already flips correctly between light and dark mode.
    final bg = isSelected ? scheme.inverseSurface : Colors.transparent;
    final fg = isSelected ? scheme.onInverseSurface : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    data.icon,
                    key: ValueKey(isSelected),
                    size: 20,
                    color: fg,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: _CountBadge(count: badgeCount, scheme: scheme),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(data.label, maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Count badge ──────────────────────────────────────────────────────────────

/// The small red count that sits on the reminders bell. Ringed in the bar's
/// own surface colour so it stays legible where it overlaps the icon.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.scheme});

  final int count;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // Past nine the exact number stops mattering and the badge would grow
    // wide enough to crowd the tab.
    final label = count > 9 ? '9+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 17),
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: scheme.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

// ─── Tab data model ───────────────────────────────────────────────────────────

class _TabData {
  const _TabData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
