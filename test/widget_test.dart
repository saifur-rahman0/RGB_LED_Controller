import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_led_controller/protocol/elk_protocol.dart';

void main() {
  test('App initialization and protocol sanity check', () {
    expect(ElkProtocol.targetDeviceAddress, 'FF:FF:10:C5:29:1F');
    expect(ElkProtocol.targetDeviceNamePrefix, 'ELK-BLEDOM');
    expect(ElkEffectCatalog.modes.length, 29);
  });
}
