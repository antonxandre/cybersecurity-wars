import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/fullscreen_helper.dart';
import 'features/settings/domain/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Carregar e sincronizar configurações do sistema
  SettingsService.instance.initialize();

  // Forçar orientação Paisagem (Landscape) em Mobile/Tablet/Desktop
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  if (kDebugMode) {
    // Quando kDebugMode for true, o software não deve inicializar em tela cheia;
    // a janela deve estar maximizada apenas.
    FullscreenHelper.maximize();
  } else {
    // Em produção/release, inicializa em tela cheia imersiva por padrão
    FullscreenHelper.initDefaultFullscreen();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await Flame.device.fullScreen();
  }

  // Inicializadores de dispositivo do Flame Engine
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
