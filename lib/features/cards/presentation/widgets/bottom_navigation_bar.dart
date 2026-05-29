import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bottom_navigation/bottom_navigation_bloc.dart';
import '../bloc/bottom_navigation/bottom_navigation_event.dart';
import '../bloc/bottom_navigation/bottom_navigation_state.dart';
import '../bloc/card_overview/card_overview_bloc.dart';
import '../pages/add_card_screen/add_card_screen.dart';
import '../pages/home_screen/home_screen.dart';
import '../pages/profile_screen/profile_screen.dart';
import '../pages/reminder_screen/reminder_screen.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  Future<void> _openAddCard(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CardOverviewBloc>(),
          child: const AddCardScreen(),
        ),
      ),
    );
  }

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
              ProfileScreen(),
            ],
          ),
          // ── Floating pill bottom nav ──────────────────────────────────────
          bottomNavigationBar: _FloatingNavBar(
            currentIndex: state.currentIndex,
            onTabTap: (i) => context
                .read<BottomNavigationBloc>()
                .add(ChangeTabEvent(i)),
            onAddTap: () => _openAddCard(context),
          ),
        );
      },
    );
  }
}

// ─── Floating pill nav bar ────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTabTap,
    required this.onAddTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTap;
  final VoidCallback onAddTap;

  static const _tabs = [
    _TabData(icon: Icons.home_rounded, label: 'Home'),
    _TabData(icon: Icons.notifications_rounded, label: 'Reminders'),
    _TabData(icon: Icons.person_rounded, label: 'Profile'),
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
        height: 68,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2540) : Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Left tabs: Home + Reminders ─────────────────────────
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    data: _tabs[0],
                    isSelected: currentIndex == 0,
                    onTap: () => onTabTap(0),
                    scheme: scheme,
                  ),
                  _NavItem(
                    data: _tabs[1],
                    isSelected: currentIndex == 1,
                    onTap: () => onTabTap(1),
                    scheme: scheme,
                  ),
                ],
              ),
            ),

            // ── Center add FAB ──────────────────────────────────────
            _AddFab(onTap: onAddTap, scheme: scheme),

            // ── Right tab: Profile ───────────────────────────────────
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    data: _tabs[2],
                    isSelected: currentIndex == 2,
                    onTap: () => onTabTap(2),
                    scheme: scheme,
                  ),
                  // Invisible spacer to mirror left side's two-item layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
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
  });

  final _TabData data;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                data.icon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
              child: Text(data.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Center "+" add button ────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap, required this.scheme});
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
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
