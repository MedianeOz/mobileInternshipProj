// lib/app/views/shell/main_shell_view.dart
//
// Persistent authenticated app shell with the five Deliverable 6 tabs.

import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../alerts/alerts_view.dart';
import '../home/threat_feed_view.dart';
import '../knowledge_base/library_view.dart';
import '../password/password_checker_view.dart';
import '../profile/profile_view.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  int currentIndex = 0;
  final int unreadAlertCount = 0;

  final List<Widget> _tabs = const [
    ThreatFeedView(),
    PasswordCheckerView(),
    LibraryView(),
    AlertsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Feed',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'Shield',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: _AlertsNavIcon(
                unreadAlertCount: unreadAlertCount,
                isActive: false,
              ),
              activeIcon: _AlertsNavIcon(
                unreadAlertCount: unreadAlertCount,
                isActive: true,
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsNavIcon extends StatelessWidget {
  final int unreadAlertCount;
  final bool isActive;

  const _AlertsNavIcon({
    required this.unreadAlertCount,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(isActive ? Icons.notifications : Icons.notifications_outlined),
        if (unreadAlertCount > 0)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
