import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ratings_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/requests_provider.dart';
import 'providers/skills_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell_screen.dart';
import 'theme/app_theme.dart';

class SkillShareApp extends StatefulWidget {
  const SkillShareApp({super.key});

  @override
  State<SkillShareApp> createState() => _SkillShareAppState();
}

class _SkillShareAppState extends State<SkillShareApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'SkillShare',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.mode,
      home:
          auth.isAuthenticated ? const RootShellScreen() : const LoginScreen(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RatingsProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => SkillsProvider()),
        ChangeNotifierProvider(create: (_) => RequestsProvider()),
      ],
      child: const SkillShareApp(),
    );
  }
}
