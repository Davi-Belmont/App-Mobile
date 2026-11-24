// Responsável: Cainã Coutinho (estrutura inicial do projeto)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/navigation/main_shell.dart';
import 'package:study_planner/core/theme/app_theme.dart';
import 'package:study_planner/features/auth/login_screen.dart';
import 'package:study_planner/features/dashboard/dashboard_provider.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/profile/grades_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DisciplinesProvider()),
        ChangeNotifierProvider(create: (_) => ActivitiesProvider()),
        ChangeNotifierProvider(create: (_) => GradesProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'StudyPlanner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const MainShell(),
        },
      ),
    );
  }
}
