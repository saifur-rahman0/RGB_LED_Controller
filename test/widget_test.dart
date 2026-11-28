import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_led_controller/protocol/elk_protocol.dart';
import 'package:rgb_led_controller/ui/theme/glass_theme.dart';
import 'package:rgb_led_controller/ui/widgets/animated_effect_tile.dart';
import 'package:rgb_led_controller/ui/widgets/glowing_card.dart';

void main() {
  test('App initialization and protocol sanity check', () {
    expect(ElkProtocol.targetDeviceAddress, 'FF:FF:10:C5:29:1F');
    expect(ElkProtocol.targetDeviceNamePrefix, 'ELK-BLEDOM');
    expect(ElkEffectCatalog.modes.length, 29);
  });

  testWidgets('Glassmorphism components render cleanly without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: GlassColors.base,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GlowingCard(
                  glowColor: GlassColors.cyan,
                  isGlowing: true,
                  child: const GlassSectionHeader(
                    icon: Icons.bolt_rounded,
                    title: 'GLASS SECTION',
                    accentColor: GlassColors.cyan,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: AnimatedEffectTile(
                    title: '7-Color Strobe',
                    subtitle: 'Dynamic strobe flash',
                    badge: '0x95',
                    icon: Icons.flash_on_rounded,
                    isActive: true,
                    isStrobeWarning: true,
                    isDisabledBySafety: true,
                    onTap: () {},
                    colorGenerator: (_) => const [
                      GlassColors.violet,
                      GlassColors.cyan,
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const GlassEmptyState(
                  icon: Icons.palette_outlined,
                  title: 'Empty State',
                  subtitle: 'Save colors to see them here',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('GLASS SECTION'), findsOneWidget);
    expect(find.text('7-Color Strobe'), findsOneWidget);
    expect(find.text('Empty State'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
