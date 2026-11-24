// Responsável: Cainã Coutinho
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/navigation/tab_nav.dart';
import 'package:study_planner/features/calendar/calendar_screen.dart';
import 'package:study_planner/features/dashboard/dashboard_provider.dart';
import 'package:study_planner/features/dashboard/dashboard_screen.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/disciplines/disciplines_screen.dart';
import 'package:study_planner/features/profile/grades_provider.dart';
import 'package:study_planner/features/profile/profile_screen.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';
import 'package:study_planner/features/tasks/tasks_screen.dart';

/// Casca do app: barra de abas inferior + carga inicial dos dados.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _screens = [
    DashboardScreen(),
    DisciplinesScreen(),
    CalendarScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    currentTab.value = TabIndex.home;
    currentTab.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisciplinesProvider>().load();
      context.read<ActivitiesProvider>().load();
      context.read<GradesProvider>().load();
      context.read<DashboardProvider>().load();
    });
  }

  @override
  void dispose() {
    currentTab.removeListener(_onTabChanged);
    super.dispose();
  }

  /// Atualiza em segundo plano os dados da aba que o usuário abriu.
  void _onTabChanged() {
    if (!mounted) return;
    switch (currentTab.value) {
      case TabIndex.home:
        context.read<DashboardProvider>().load(silent: true);
        context.read<ActivitiesProvider>().load(silent: true);
        break;
      case TabIndex.disciplines:
      case TabIndex.profile:
        context.read<GradesProvider>().load(silent: true);
        context.read<DisciplinesProvider>().load(silent: true); // médias da API
        break;
      case TabIndex.calendar:
      case TabIndex.tasks:
        context.read<ActivitiesProvider>().load(silent: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentTab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(index: index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => currentTab.value = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Disciplinas'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Calendário'),
            NavigationDestination(icon: Icon(Icons.checklist_rounded), selectedIcon: Icon(Icons.checklist_rtl_rounded), label: 'Tarefas'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
