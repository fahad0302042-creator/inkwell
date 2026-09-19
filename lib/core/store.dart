import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final libraryProvider = NotifierProvider<LibraryController, LibraryState>(
  LibraryController.new,
);

enum ReaderMode { rightToLeft, leftToRight, vertical }

class LibraryState {
  final Set<String> saved;
  final Map<String, int> progress;
  final List<String> recent;
  final ReaderMode mode;
  final bool dark;
  const LibraryState({
    this.saved = const {'moon', 'garden'},
    this.progress = const {},
    this.recent = const [],
    this.mode = ReaderMode.rightToLeft,
    this.dark = false,
  });
  LibraryState copyWith({
    Set<String>? saved,
    Map<String, int>? progress,
    List<String>? recent,
    ReaderMode? mode,
    bool? dark,
  }) => LibraryState(
    saved: saved ?? this.saved,
    progress: progress ?? this.progress,
    recent: recent ?? this.recent,
    mode: mode ?? this.mode,
    dark: dark ?? this.dark,
  );
  String encode() => jsonEncode({
    'saved': saved.toList(),
    'progress': progress,
    'recent': recent,
    'mode': mode.name,
    'dark': dark,
  });
  static LibraryState decode(String? raw) {
    if (raw == null) return const LibraryState();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LibraryState(
        saved: Set<String>.from(json['saved'] as List),
        progress: Map<String, int>.from(json['progress'] as Map),
        recent: List<String>.from(json['recent'] as List),
        mode: ReaderMode.values.firstWhere((v) => v.name == json['mode']),
        dark: json['dark'] as bool,
      );
    } catch (_) {
      return const LibraryState();
    }
  }
}

class LibraryController extends Notifier<LibraryState> {
  @override
  LibraryState build() => LibraryState.decode(
    ref.read(preferencesProvider).getString('library.v1'),
  );
  Future<void> _commit(LibraryState next) async {
    state = next;
    final success = await ref
        .read(preferencesProvider)
        .setString('library.v1', next.encode());
    if (!success) {
      throw StateError('Could not save your reading state.');
    }
  }

  Future<void> toggle(String id) {
    final next = {...state.saved};
    next.contains(id) ? next.remove(id) : next.add(id);
    return _commit(state.copyWith(saved: next));
  }

  Future<void> record(String id, int page) => _commit(
    state.copyWith(
      progress: {...state.progress, id: page.clamp(0, 3)},
      recent: [id, ...state.recent.where((v) => v != id)],
    ),
  );
  Future<void> setMode(ReaderMode mode) => _commit(state.copyWith(mode: mode));
  Future<void> setDark(bool dark) => _commit(state.copyWith(dark: dark));
  Future<void> reset() => _commit(const LibraryState(saved: {}));
}
