import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstalledExtension {
  final String name, packageName, version, entryPoint;
  final List<String> fingerprints;
  final bool nsfw;
  const InstalledExtension({
    required this.name,
    required this.packageName,
    required this.version,
    required this.entryPoint,
    required this.fingerprints,
    required this.nsfw,
  });
  factory InstalledExtension.fromMap(Map<dynamic, dynamic> map) =>
      InstalledExtension(
        name: map['name'] as String,
        packageName: map['packageName'] as String,
        version: map['version'] as String,
        entryPoint: map['entryPoint'] as String,
        fingerprints: List<String>.from(map['fingerprints'] as List),
        nsfw: map['nsfw'] as bool,
      );
}

class ExtensionBridge {
  static const channel = MethodChannel('dev.inkwell/extensions');
  bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<List<InstalledExtension>> installed() async {
    if (!available) return [];
    final result = await channel.invokeListMethod<dynamic>('listInstalled');
    return (result ?? [])
        .map((item) => InstalledExtension.fromMap(item as Map))
        .toList();
  }

  Future<void> openSettings(String packageName) => channel.invokeMethod<void>(
    'openAppSettings',
    {'packageName': packageName},
  );
}

final extensionBridgeProvider = Provider((ref) => ExtensionBridge());
final installedExtensionsProvider = FutureProvider(
  (ref) => ref.watch(extensionBridgeProvider).installed(),
);
