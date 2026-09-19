import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkwell/core/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Library state survives serialization', () {
    const initial = LibraryState(
      saved: {'moon'},
      progress: {'moon': 2},
      recent: ['moon'],
      mode: ReaderMode.vertical,
      dark: true,
    );
    final decoded = LibraryState.decode(initial.encode());
    expect(decoded.saved, {'moon'});
    expect(decoded.progress, {'moon': 2});
    expect(decoded.recent, ['moon']);
    expect(decoded.mode, ReaderMode.vertical);
    expect(decoded.dark, true);
  });
  test('Corrupted storage recovers to defaults', () {
    expect(LibraryState.decode('{broken').saved, {'moon', 'garden'});
    expect(LibraryState.decode('{}').recent, isEmpty);
  });
  test('Bookmarks, progress, settings, and reset persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final controller = container.read(libraryProvider.notifier);
    await controller.toggle('signal');
    await controller.record('signal', 2);
    await controller.record('moon', 1);
    await controller.record('signal', 99);
    await controller.setMode(ReaderMode.vertical);
    await controller.setDark(true);
    expect(container.read(libraryProvider).progress['signal'], 3);
    expect(container.read(libraryProvider).recent, ['signal', 'moon']);
    final restored = LibraryState.decode(prefs.getString('library.v1'));
    expect(restored.saved, contains('signal'));
    expect(restored.dark, true);
    expect(restored.mode, ReaderMode.vertical);
    await controller.reset();
    expect(container.read(libraryProvider).saved, isEmpty);
    expect(container.read(libraryProvider).progress, isEmpty);
    expect(container.read(libraryProvider).recent, isEmpty);
    expect(container.read(libraryProvider).dark, false);
  });
}
