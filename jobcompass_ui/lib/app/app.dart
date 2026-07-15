import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/applications/screens/application_history_screen.dart';
import '../features/feed/screens/feed_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/saved/screens/saved_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class JobCompassApp extends ConsumerWidget {
  const JobCompassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);
    final home = authState.isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : authState.isAuthenticated
        ? const MainNavigation()
        : const LoginScreen();

    return AppStrings(
      language: language,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JobCompass',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: Locale(language.code),
        home: SelectionArea(child: home),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  void _selectTab(int index) {
    if (selectedIndex == index) {
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (selectedIndex) {
      case 0:
        return HomeScreen(
          onOpenFeed: () => _selectTab(1),
          onOpenSaved: () => _selectTab(2),
          onOpenProfile: () => _selectTab(4),
        );
      case 1:
        return const FeedScreen();
      case 2:
        return const SavedScreen();
      case 3:
        return const ApplicationHistoryScreen();
      case 4:
        return const ProfileScreen();
      default:
        return HomeScreen(
          onOpenFeed: () => _selectTab(1),
          onOpenSaved: () => _selectTab(2),
          onOpenProfile: () => _selectTab(4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: context.tr('home'),
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: context.tr('feed'),
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: context.tr('saved'),
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: context.tr('crm'),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}
