import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkwell/platform/extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ExtensionBridge.channel, null);
  });
  test(
    'Android bridge decodes native metadata without implying trust',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ExtensionBridge.channel, (call) async {
            expect(call.method, 'listInstalled');
            return [
              {
                'name': 'Fixture',
                'packageName': 'test.fixture',
                'version': '1.4.1',
                'entryPoint': '.Fixture',
                'fingerprints': ['AB:CD'],
                'nsfw': false,
              },
            ];
          });
      final items = await ExtensionBridge().installed();
      expect(items.single.packageName, 'test.fixture');
      expect(items.single.fingerprints, ['AB:CD']);
    },
  );
  test('Non-Android has no synthetic extension results', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(await ExtensionBridge().installed(), isEmpty);
  });
  test('Native errors are not silently turned into empty results', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ExtensionBridge.channel, (call) async {
          throw PlatformException(code: 'SCAN_FAILED');
        });
    await expectLater(
      ExtensionBridge().installed(),
      throwsA(isA<PlatformException>()),
    );
  });
}
