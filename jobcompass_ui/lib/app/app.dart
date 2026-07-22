import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../features/admin/screens/admin_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/applications/screens/application_history_screen.dart';
import '../features/feed/screens/feed_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/saved/screens/saved_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/account_provider.dart';
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
        home: _ResponsiveSelectionArea(child: home),
      ),
    );
  }
}

class _ResponsiveSelectionArea extends StatelessWidget {
  const _ResponsiveSelectionArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // SelectionArea is useful on desktop, but it can compete with native
        // text-field gestures and the software keyboard on mobile browsers.
        if (constraints.maxWidth < 600) {
          return child;
        }

        return SelectionArea(child: child);
      },
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int selectedIndex = 0;

  void _selectTab(int index) {
    if (selectedIndex == index) {
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  Widget _buildCurrentScreen(int index, {required bool isAdmin}) {
    switch (index) {
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
      case 5:
        return isAdmin ? const AdminScreen() : const ProfileScreen();
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
    final isAdmin = ref.watch(currentUserProvider).value?.isAdmin ?? false;
    final destinationCount = isAdmin ? 6 : 5;
    final effectiveIndex = selectedIndex < destinationCount ? selectedIndex : 4;
    final currentScreen = _buildCurrentScreen(effectiveIndex, isAdmin: isAdmin);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          final extended = constraints.maxWidth >= 1180;

          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: extended,
                    selectedIndex: effectiveIndex,
                    onDestinationSelected: _selectTab,
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    destinations: _railDestinations(context, isAdmin: isAdmin),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: currentScreen),
              ],
            ),
          );
        }

        return Scaffold(
          body: currentScreen,
          bottomNavigationBar: NavigationBar(
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: effectiveIndex,
            onDestinationSelected: _selectTab,
            destinations: _bottomDestinations(context, isAdmin: isAdmin),
          ),
        );
      },
    );
  }

  List<NavigationDestination> _bottomDestinations(
    BuildContext context, {
    required bool isAdmin,
  }) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: context.tr('home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.work_outline),
        selectedIcon: const Icon(Icons.work),
        label: context.tr('feed'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.bookmark_outline),
        selectedIcon: const Icon(Icons.bookmark),
        label: context.tr('saved'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.analytics_outlined),
        selectedIcon: const Icon(Icons.analytics),
        label: context.tr('crm'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: context.tr('profile'),
      ),
      if (isAdmin)
        NavigationDestination(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: const Icon(Icons.admin_panel_settings),
          label: context.tr('admin'),
        ),
    ];
  }

  List<NavigationRailDestination> _railDestinations(
    BuildContext context, {
    required bool isAdmin,
  }) {
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: Text(context.tr('home')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.work_outline),
        selectedIcon: const Icon(Icons.work),
        label: Text(context.tr('feed')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.bookmark_outline),
        selectedIcon: const Icon(Icons.bookmark),
        label: Text(context.tr('saved')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.analytics_outlined),
        selectedIcon: const Icon(Icons.analytics),
        label: Text(context.tr('crm')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: Text(context.tr('profile')),
      ),
      if (isAdmin)
        NavigationRailDestination(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: const Icon(Icons.admin_panel_settings),
          label: Text(context.tr('admin')),
        ),
    ];
  }
}
