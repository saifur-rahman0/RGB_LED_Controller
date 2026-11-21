import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'services/ble_led_service.dart';
import 'ui/console_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop Window Configuration
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(940, 720),
    minimumSize: Size(540, 680),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'RGBZap LED Console • ELK-BLEDOM BLE Controller',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });

  runApp(const RgbZapApp());
}

class RgbZapApp extends StatelessWidget {
  const RgbZapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BleLedService>(
      create: (_) => BleLedService(),
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
