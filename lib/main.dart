import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'services/audio_reactive_service.dart';
import 'services/ble_led_service.dart';
import 'services/local_api_service.dart';
import 'services/obs_service.dart';
import 'services/screen_sync_service.dart';
import 'ui/console_screen.dart';
import 'ui/theme/glass_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop Window Manager Configuration
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(980, 740),
    minimumSize: Size(620, 680),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Frameless custom Windows titlebar
    title: 'RGB LED Console • ELK-BLEDOM BLE Controller',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });

  runApp(const RgbConsoleApp());
}

class RgbConsoleApp extends StatefulWidget {
  const RgbConsoleApp({super.key});

  @override
  State<RgbConsoleApp> createState() => _RgbConsoleAppState();
}

class _RgbConsoleAppState extends State<RgbConsoleApp> {
  late final BleLedService _bleService;
  late final ScreenSyncService _screenSyncService;
  late final AudioReactiveService _audioReactiveService;
  late final LocalApiService _localApiService;
  late final ObsService _obsService;

  @override
  void initState() {
    super.initState();
    _bleService = BleLedService();
    _screenSyncService = ScreenSyncService(bleService: _bleService);
    _audioReactiveService = AudioReactiveService(bleService: _bleService);
    _localApiService = LocalApiService(
      bleService: _bleService,
      screenSyncService: _screenSyncService,
      audioReactiveService: _audioReactiveService,
    );
    _obsService = ObsService(bleService: _bleService);
  }

  @override
  void dispose() {
    _obsService.dispose();
    _localApiService.dispose();
    _audioReactiveService.dispose();
    _screenSyncService.dispose();
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BleLedService>.value(value: _bleService),
        ChangeNotifierProvider<ScreenSyncService>.value(
          value: _screenSyncService,
        ),
        ChangeNotifierProvider<AudioReactiveService>.value(
          value: _audioReactiveService,
        ),
        ChangeNotifierProvider<LocalApiService>.value(value: _localApiService),
        ChangeNotifierProvider<ObsService>.value(value: _obsService),
      ],
      child: MaterialApp(
        title: 'RGB LED Console',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: GlassColors.base,
          cardColor: GlassColors.glass,
          canvasColor: GlassColors.canvas,
          colorScheme: const ColorScheme.dark(
            primary: GlassColors.violet,
            secondary: GlassColors.cyan,
            surface: GlassColors.glass,
            onSurface: GlassColors.textPrimary,
          ),
          fontFamily: 'Segoe UI',
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(GlassColors.borderRaised),
            radius: const Radius.circular(4),
            thickness: WidgetStateProperty.all(6),
          ),
          tooltipTheme: TooltipThemeData(
            decoration: BoxDecoration(
              color: GlassColors.overlay.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              border: Border.all(
                color: GlassColors.borderRaised.withValues(alpha: 0.8),
              ),
            ),
            textStyle: const TextStyle(fontSize: 11.5, color: Colors.white),
          ),
          dividerTheme: const DividerThemeData(
            color: GlassColors.borderDefault,
            thickness: 1,
          ),
        ),
        home: const ConsoleScreen(),
      ),
    );
  }
}
