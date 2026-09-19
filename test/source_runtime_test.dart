import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwell/core/store.dart';
import 'package:inkwell/features/source_screens.dart';
import 'package:inkwell/platform/extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ExtensionBridge.channel, null),
  );
  test('Source identities retain 64-bit precision as strings', () {
    final source = ExtensionSource.fromMap({
      'id': '9223372036854775806',
      'name': 'Fixture',
      'lang': 'en',
      'packageName': 'test.fixture',
    });
    expect(source.id, '9223372036854775806');
  });
  test('Trust passes the reviewed exact APK identity and handles returned source list', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ExtensionBridge.channel, (call) async {
          expect(call.method, 'trustAndLoad');
          expect(call.arguments, {
            'packageName': 'test.fixture',
            'identity': 'version:hash:signers',
          });
          return [
            {'id': '123', 'name': 'Fixture'},
          ];
        });
    await ExtensionBridge().trust(
      const InstalledExtension(
        name: 'Fixture',
        packageName: 'test.fixture',
        version: '1.4.1',
        entryPoint: '.Factory',
        fingerprints: ['certificate'],
        nsfw: false,
        identity: 'version:hash:signers',
        supported: true,
      ),
    );
  });
  testWidgets(
    'Live-source UI follows native search, chapters, pages and saves progress',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final calls = <String>[];
      final manga = {
        'handle': 'm1',
        'title': 'Native fixture title',
        'url': '/title',
        'description': 'Fixture only',
        'hasCover': false,
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ExtensionBridge.channel, (call) async {
            calls.add(call.method);
            return switch (call.method) {
              'search' => {
                'hasNextPage': false,
                'items': [manga],
              },
              'details' => manga,
              'chapters' => [
                {
                  'handle': 'c1',
                  'name': 'Native fixture chapter',
                  'url': '/chapter',
                  'progressKey': 'fixture-key',
                },
              ],
              'pages' => [
                {'handle': 'p1', 'index': 0},
                {'handle': 'p2', 'index': 1},
              ],
              'image' => base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aN1cAAAAASUVORK5CYII=',
              ),
              _ => throw PlatformException(code: 'UNEXPECTED_METHOD'),
            };
          });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [preferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: SourceBrowseScreen(
              source: ExtensionSource(
                id: '123',
                name: 'Fixture',
                lang: 'en',
                packageName: 'test.fixture',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Native fixture title'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Native fixture chapter'),
        150,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Native fixture chapter'));
      await tester.pumpAndSettle();
      expect(find.text('PAGE 1 / 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Next source page'));
      await tester.pumpAndSettle();
      expect(find.text('PAGE 2 / 2'), findsOneWidget);
      expect(prefs.getInt('source.progress.fixture-key'), 1);
      expect(
        calls,
        containsAll(['search', 'details', 'chapters', 'pages', 'image']),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
