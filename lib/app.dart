import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/catalog_screen.dart';
import 'screens/guide_excursions_screen.dart';
import 'screens/guide_home_screen.dart';
import 'screens/inspector_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/key_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/role_screen.dart';
import 'state/observation_controller.dart';
import 'state/session_controller.dart';
import 'theme/flora_theme.dart';
import 'widgets/achievement_banner.dart';
import 'widgets/confirm_exit.dart';
import 'widgets/flora_nav_bar.dart';
import 'widgets/splash_gate.dart';

class LenskieFloraApp extends StatelessWidget {
  const LenskieFloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Флора Ленских Столбов',
      debugShowCheckedModeBanner: false,
      theme: buildFloraTheme(),
      builder: (context, child) =>
          AchievementBannerHost(child: child ?? const SizedBox.shrink()),
      home: const SplashGate(child: AppStart()),
    );
  }
}

class AppStart extends StatelessWidget {
  const AppStart({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionController>().role;
    return switch (role) {
      'tourist' => const TouristShell(),
      'guide' => const GuideShell(),
      'inspector' => const InspectorShell(),
      _ => const RoleScreen(),
    };
  }
}

class InspectorShell extends StatelessWidget {
  const InspectorShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final notes = context.watch<ObservationController>().notes;
    final pages = [
      const InspectorHomeScreen(),
      const InspectorNotesScreen(),
      MapScreen(
        active: session.tab == 2,
        showOwnPoints: true,
        pins: [
          for (final note in notes)
            if (note.lat != null && note.lon != null) note
        ],
      ),
      const InspectorNotesScreen(reports: true),
      const ProfileScreen(),
    ];
    return ShellBack(
      child: Scaffold(
        backgroundColor: cream,
        body: IndexedStack(index: session.tab, children: pages),
        bottomNavigationBar:
            FloraNavBar(index: session.tab, onTap: session.selectTab),
      ),
    );
  }
}

class GuideShell extends StatelessWidget {
  const GuideShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final pages = [
      const GuideHomeScreen(),
      const CatalogScreen(),
      const GuideExcursionsScreen(),
      MapScreen(active: session.tab == 3),
      const ProfileScreen(),
    ];
    return ShellBack(
      child: Scaffold(
        backgroundColor: cream,
        body: IndexedStack(index: session.tab, children: pages),
        bottomNavigationBar:
            FloraNavBar(index: session.tab, onTap: session.selectTab),
      ),
    );
  }
}

class TouristShell extends StatelessWidget {
  const TouristShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final pages = [
      const HomeScreen(),
      const CatalogScreen(),
      const KeyScreen(),
      MapScreen(active: session.tab == 3),
      const ProfileScreen(),
    ];
    return ShellBack(
      child: Scaffold(
        backgroundColor: cream,
        body: IndexedStack(index: session.tab, children: pages),
        bottomNavigationBar:
            FloraNavBar(index: session.tab, onTap: session.selectTab),
      ),
    );
  }
}

class ShellBack extends StatelessWidget {
  final Widget child;
  const ShellBack({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (session.tryBack()) return;
        if (session.tab != 0) {
          session.selectTab(0);
          return;
        }
        confirmAppExit(context);
      },
      child: child,
    );
  }
}
