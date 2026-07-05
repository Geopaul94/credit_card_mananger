import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../bloc/bottom_navigation/bottom_navigation_bloc.dart';
import '../bloc/bottom_navigation/bottom_navigation_event.dart';
import '../bloc/bottom_navigation/bottom_navigation_state.dart';
import '../pages/home_screen/home_screen.dart';
import '../pages/profile_screen/profile_screen.dart';
import '../pages/reminder_screen/reminder_screen.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          body: IndexedStack(
            index: state.currentIndex,
            children: [
              const HomeScreen(),
              const ReminderScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 8.0,
              ),
              child: GNav(
                selectedIndex: state.currentIndex,
                onTabChange: (index) {
                  context.read<BottomNavigationBloc>().add(
                    ChangeTabEvent(index),
                  );
                },
                gap: 8,
                activeColor: colorScheme.primary,
                iconSize: 24.0,
                textSize: 13.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                tabs: const [
                  GButton(icon: Icons.home, text: 'Home'),
                  GButton(icon: Icons.notifications, text: 'Reminders'),
                  GButton(icon: Icons.person, text: 'Profile'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
