import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Forçar orientação Paisagem (Landscape) em Mobile/Tablet/Desktop
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Habilitar modo tela cheia imersivo
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Inicializadores de dispositivo do Flame Engine
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  runApp(const PromptSecArenaApp());
}

class PromptSecArenaApp extends StatelessWidget {
  const PromptSecArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PromptSec Arena (CyberWars)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}

