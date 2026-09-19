import 'package:inkwell/platform/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwell/main.dart';
import 'package:inkwell/core/store.dart';

Future<void> launch(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  ReaderMode mode = ReaderMode.rightToLeft,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(ExtensionBridge.channel, (call) async => []);
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ExtensionBridge.channel, null),
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'library.v1': LibraryState(mode: mode).encode(),
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
      child: const InkwellApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Mobile library, chapter navigation, and persisted history', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('The library'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start reading').first);
    await tester.pumpAndSettle();
    expect(find.text('PAGE 1 / 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 2 / 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Chapter 01 · Page 2 of 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Small phone does not overflow', (tester) async {
    await launch(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'nothing matches');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No matching samples.'),
      150,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    expect(find.text('No matching samples.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Desktop sidebar and honest extension status', (tester) async {
    await launch(tester, size: const Size(1440, 1000));
    expect(find.text('Your reading space'.toUpperCase()), findsOneWidget);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extensions'));
    await tester.pumpAndSettle();
    expect(find.text('Experimental extension runtime'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reader mode changes preserve the current page', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Start reading').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 3 / 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vertical scroll · Webtoon'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 3 / 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Left to right · Comics'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 3 / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Settings theme and reset confirmation work', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.scrollUntilVisible(
      find.text('Reset local library and preferences'),
      150,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    await tester.tap(find.text('Reset local library and preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('2 titles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Vertical reader moves to next page', (tester) async {
    await launch(tester, mode: ReaderMode.vertical);
    await tester.tap(find.text('Start reading').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 2 / 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE 4 / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
