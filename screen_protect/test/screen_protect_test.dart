import 'package:flutter_test/flutter_test.dart';
import 'package:screen_protect/screen_protect.dart';

void main() {
  group('ScreenProtectController', () {
    test('defaults to enabled', () {
      final controller = ScreenProtectController();
      expect(controller.isProtectionEnabled, isTrue);
      expect(controller.value, isTrue);
    });

    test('setEnabled notifies listeners', () {
      final controller = ScreenProtectController();
      var calls = 0;
      controller.addListener(() => calls++);

      controller.setEnabled(false);
      expect(controller.isProtectionEnabled, isFalse);
      expect(calls, 1);

      controller.setEnabled(false);
      expect(calls, 1);

      controller.enable();
      expect(controller.isProtectionEnabled, isTrue);
      expect(calls, 2);
    });
  });
}
