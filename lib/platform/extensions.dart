import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstalledExtension {
  final String name, packageName, version, entryPoint, apiVersion, identity;
  final List<String> fingerprints;
  final bool nsfw, trusted, supported;
  const InstalledExtension({
    required this.name,
    required this.packageName,
    required this.version,
    required this.entryPoint,
    required this.fingerprints,
    required this.nsfw,
    this.apiVersion = 'unknown',
    this.identity = '',
    this.trusted = false,
    this.supported = false,
  });
  factory InstalledExtension.fromMap(Map<dynamic, dynamic> m) =>
      InstalledExtension(
        name: m['name'] as String,
        packageName: m['packageName'] as String,
        version: m['version'] as String,
        entryPoint: m['entryPoint'] as String,
        fingerprints: List<String>.from(m['fingerprints'] as List),
        nsfw: m['nsfw'] as bool,
        apiVersion: m['apiVersion'] as String? ?? 'unknown',
        identity: m['identity'] as String? ?? '',
        trusted: m['trusted'] == true,
        supported: m['supported'] == true,
      );
}

class ExtensionSource {
  final String id, name, lang, packageName;
  final bool supportsLatest;
  const ExtensionSource({
    required this.id,
    required this.name,
    required this.lang,
    required this.packageName,
    this.supportsLatest = false,
  });
  factory ExtensionSource.fromMap(Map<dynamic, dynamic> m) => ExtensionSource(
    id: m['id'] as String,
    name: m['name'] as String,
    lang: m['lang'] as String,
    packageName: m['packageName'] as String,
    supportsLatest: m['supportsLatest'] == true,
  );
}

class SourceManga {
  final String handle, title, url, description, author, genre;
  final bool hasCover;
  const SourceManga({
    required this.handle,
    required this.title,
    required this.url,
    this.description = '',
    this.author = '',
    this.genre = '',
    this.hasCover = false,
  });
  factory SourceManga.fromMap(Map<dynamic, dynamic> m) => SourceManga(
    handle: m['handle'] as String,
    title: m['title'] as String,
    url: m['url'] as String,
    description: m['description'] as String? ?? '',
    author: m['author'] as String? ?? '',
    genre: m['genre'] as String? ?? '',
    hasCover: m['hasCover'] == true,
  );
}

class SourceSearchResult {
  final List<SourceManga> items;
  final bool hasNextPage;
  const SourceSearchResult(this.items, this.hasNextPage);
  factory SourceSearchResult.fromMap(Map<dynamic, dynamic> m) =>
      SourceSearchResult(
        (m['items'] as List).map((v) => SourceManga.fromMap(v as Map)).toList(),
        m['hasNextPage'] == true,
      );
}

class SourceChapter {
  final String handle, name, url, progressKey;
  const SourceChapter({
    required this.handle,
    required this.name,
    required this.url,
    required this.progressKey,
  });
  factory SourceChapter.fromMap(Map<dynamic, dynamic> m) => SourceChapter(
    handle: m['handle'] as String,
    name: m['name'] as String,
    url: m['url'] as String,
    progressKey: m['progressKey'] as String,
  );
}

class SourcePage {
  final String handle;
  final int index;
  const SourcePage(this.handle, this.index);
  factory SourcePage.fromMap(Map<dynamic, dynamic> m) =>
      SourcePage(m['handle'] as String, m['index'] as int);
}

class ExtensionBridge {
  static const channel = MethodChannel('dev.inkwell/extensions');
  bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<List<InstalledExtension>> installed() async {
    if (!available) return [];
    final result = await channel.invokeListMethod<dynamic>('listInstalled');
    return (result ?? [])
        .map((v) => InstalledExtension.fromMap(v as Map))
        .toList();
  }

  Future<List<ExtensionSource>> sources(String packageName) async =>
      (await channel.invokeListMethod<dynamic>('sources', {
                'packageName': packageName,
              }) ??
              [])
          .map((v) => ExtensionSource.fromMap(v as Map))
          .toList();
  Future<void> trust(InstalledExtension extension) => channel
      .invokeMethod<dynamic>('trustAndLoad', {
        'packageName': extension.packageName,
        'identity': extension.identity,
      })
      .then((_) {});
  Future<void> revoke(String name) =>
      channel.invokeMethod<void>('revokeTrust', {'packageName': name});
  Future<void> openSettings(String name) =>
      channel.invokeMethod<void>('openAppSettings', {'packageName': name});
  Future<void> openWebsite() =>
      channel.invokeMethod<void>('openExtensionWebsite');
  Future<SourceSearchResult> search(
    ExtensionSource source,
    String query,
    int page, {
    bool latest = false,
  }) async {
    final result = await channel.invokeMapMethod<dynamic, dynamic>('search', {
      'packageName': source.packageName,
      'sourceId': source.id,
      'query': query,
      'page': page,
      'latest': latest,
    });
    return SourceSearchResult.fromMap(result!);
  }

  Future<SourceManga> details(String handle) async => SourceManga.fromMap(
    (await channel.invokeMapMethod<dynamic, dynamic>('details', {
      'handle': handle,
    }))!,
  );
  Future<List<SourceChapter>> chapters(String handle) async =>
      (await channel.invokeListMethod<dynamic>('chapters', {
                'handle': handle,
              }) ??
              [])
          .map((v) => SourceChapter.fromMap(v as Map))
          .toList();
  Future<List<SourcePage>> pages(String handle) async =>
      (await channel.invokeListMethod<dynamic>('pages', {'handle': handle}) ??
              [])
          .map((v) => SourcePage.fromMap(v as Map))
          .toList();
  Future<Uint8List> image(String handle, {bool cover = false}) async =>
      (await channel.invokeMethod<Uint8List>('image', {
        'handle': handle,
        'cover': cover,
      }))!;
}

String runtimeError(Object error) => error is PlatformException
    ? '${error.code}\n${error.message ?? 'Extension operation failed'}'
    : error.toString();
final extensionBridgeProvider = Provider((ref) => ExtensionBridge());
final installedExtensionsProvider = FutureProvider(
  (ref) => ref.watch(extensionBridgeProvider).installed(),
);
final extensionSourcesProvider = FutureProvider.autoDispose
    .family<List<ExtensionSource>, String>(
      (ref, name) => ref.watch(extensionBridgeProvider).sources(name),
    );
