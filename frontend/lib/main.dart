import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/battle/presentation/screens/arena_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PromptSecArenaApp());
}

class PromptSecArenaApp extends StatelessWidget {
  const PromptSecArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptSec Arena (CyberWars)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ArenaScreen(),
    );
  }
}
