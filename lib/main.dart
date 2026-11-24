import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'services/audio_reactive_service.dart';
import 'services/ble_led_service.dart';
import 'services/local_api_service.dart';
import 'services/obs_service.dart';
import 'services/screen_sync_service.dart';
import 'ui/console_screen.dart';

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
    title: 'RGBZap LED Console • ELK-BLEDOM BLE Controller',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });

  runApp(const RgbZapApp());
}

class RgbZapApp extends StatefulWidget {
  const RgbZapApp({super.key});

  @override
  State<RgbZapApp> createState() => _RgbZapAppState();
}

class _RgbZapAppState extends State<RgbZapApp> {
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
        ChangeNotifierProvider<ScreenSyncService>.value(value: _screenSyncService),
        ChangeNotifierProvider<AudioReactiveService>.value(value: _audioReactiveService),
        ChangeNotifierProvider<LocalApiService>.value(value: _localApiService),
        ChangeNotifierProvider<ObsService>.value(value: _obsService),
      ],
      child: MaterialApp(
        title: 'RGBZap LED Console',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF111114),
          cardColor: const Color(0xFF18181B),
          canvasColor: const Color(0xFF141417),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8B5CF6),
            secondary: Color(0xFF06B6D4),
            surface: Color(0xFF18181B),
            onSurface: Color(0xFFFAFAFA),
          ),
          fontFamily: 'Segoe UI',
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(const Color(0xFF3F3F46)),
            radius: const Radius.circular(4),
            thickness: WidgetStateProperty.all(6),
          ),
          tooltipTheme: const TooltipThemeData(
            decoration: BoxDecoration(
              color: Color(0xFF27272A),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            textStyle: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
        home: const ConsoleScreen(),
      ),
    );
  }
}
