import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_led_controller/protocol/elk_protocol.dart';

void main() {
  group('ElkProtocol 9-byte payload tests for FF:FF:10:C5:29:1F', () {
    test('Handshake packet is exactly 9 bytes matching specification', () {
      final packet = ElkProtocol.handshake();
      expect(packet.length, 9);
      expect(packet, Uint8List.fromList([0x7E, 0x07, 0x83, 0x02, 0x01, 0x01, 0x01, 0x00, 0xEF]));
    });

    test('Power ON packet is exactly 9 bytes matching specification', () {
      final packet = ElkProtocol.powerOn();
      expect(packet.length, 9);
      expect(packet, Uint8List.fromList([0x7E, 0x04, 0x04, 0xF0, 0x00, 0x01, 0xFF, 0x00, 0xEF]));
    });

    test('Power OFF packet is exactly 9 bytes matching specification', () {
      final packet = ElkProtocol.powerOff();
      expect(packet.length, 9);
      expect(packet, Uint8List.fromList([0x7E, 0x04, 0x04, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xEF]));
    });

    test('Solid RGB packet is exactly 9 bytes matching specification', () {
      final packet = ElkProtocol.setRgb(255, 0, 128);
      expect(packet.length, 9);
      expect(packet, Uint8List.fromList([0x7E, 0x07, 0x05, 0x03, 0xFF, 0x00, 0x80, 0x10, 0xEF]));
    });

    test('Brightness packet is exactly 9 bytes and clamps properly', () {
      final packet = ElkProtocol.setBrightness(75);
      expect(packet.length, 9);
      expect(packet, Uint8List.fromList([0x7E, 0x04, 0x01, 75, 0x01, 0xFF, 0xFF, 0x00, 0xEF]));

      // Clamping test
      final clampedLow = ElkProtocol.setBrightness(0);
      expect(clampedLow[3], 1);
      final clampedHigh = ElkProtocol.setBrightness(150);
      expect(clampedHigh[3], 100);
    });

    test('Hardware Effect packet generates correct mode ID', () {
      final crossfade7 = ElkProtocol.setEffect(0x87);
      expect(crossfade7.length, 9);
      expect(crossfade7, Uint8List.fromList([0x7E, 0x05, 0x03, 0x87, 0x03, 0xFF, 0xFF, 0x00, 0xEF]));

      final strobe7 = ElkProtocol.setEffect(0x95);
      expect(strobe7.length, 9);
      expect(strobe7, Uint8List.fromList([0x7E, 0x05, 0x03, 0x95, 0x03, 0xFF, 0xFF, 0x00, 0xEF]));
    });

    test('Hardware Effect Speed packet generates correct payload', () {
      final speedPacket = ElkProtocol.setEffectSpeed(60);
      expect(speedPacket.length, 9);
      expect(speedPacket, Uint8List.fromList([0x7E, 0x04, 0x02, 60, 0x00, 0x00, 0x00, 0x00, 0xEF]));
    });

    test('Format hex string works as expected', () {
      final str = ElkProtocol.formatHex(Uint8List.fromList([0x7E, 0x04, 0xEF]));
      expect(str, '7E 04 EF');
    });

    test('UUID matching logic accurately resolves short and full UUIDs', () {
      expect(ElkProtocol.isServiceMatch('0000fff0-0000-1000-8000-00805f9b34fb'), isTrue);
      expect(ElkProtocol.isServiceMatch('FFF0'), isTrue);
      expect(ElkProtocol.isWriteCharMatch('0000fff3-0000-1000-8000-00805f9b34fb'), isTrue);
      expect(ElkProtocol.isWriteCharMatch('fff3'), isTrue);
    });
  });
}
