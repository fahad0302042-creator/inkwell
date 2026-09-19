import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/extensions.dart';
import 'widgets.dart';

class ExtensionsScreen extends ConsumerStatefulWidget {
  const ExtensionsScreen({super.key});
  @override
  ConsumerState<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends ConsumerState<ExtensionsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(installedExtensionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(extensionBridgeProvider);
    final installed = ref.watch(installedExtensionsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      children: [
        const Notice(
          'Discovery is ready. Execution is not.',
          'Inkwell can inspect installed extension APKs on Android. The source compatibility engine is not implemented yet: source search, chapter fetching and downloads are unavailable.',
          icon: Icons.construction_outlined,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Eyebrow('Installed on this device')),
            IconButton(
              tooltip: 'Rescan extensions',
              onPressed: () => ref.invalidate(installedExtensionsProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (!bridge.available)
          const Notice(
            'Android device required',
            'The browser preview demonstrates the Flutter interface. Install the Android app to inspect extension packages. No fake extension results are shown.',
            icon: Icons.android,
          ),
        if (bridge.available)
          installed.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Notice(
              'Could not scan extensions',
              '$e\nTap rescan to try again.',
              icon: Icons.error_outline,
            ),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Notice(
                      'No installed extensions found',
                      'Only system-installed extension APKs are visible. Extensions stored privately inside another reader cannot be discovered. Install only APKs from developers you trust, using Android’s installer.',
                      icon: Icons.extension_outlined,
                    ),
                  )
                : Column(
                    children: items
                        .map(
                          (item) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            child: ExpansionTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.version} · Runtime unavailable',
                              ),
                              leading: const Icon(Icons.extension_outlined),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                20,
                              ),
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Eyebrow('Package'),
                                const SizedBox(height: 5),
                                SelectableText(item.packageName),
                                const SizedBox(height: 14),
                                const Eyebrow('Declared entry point'),
                                const SizedBox(height: 5),
                                SelectableText(
                                  item.entryPoint.isEmpty
                                      ? 'Not declared'
                                      : item.entryPoint,
                                ),
                                const SizedBox(height: 14),
                                const Eyebrow('Signing certificate · SHA-256'),
                                const SizedBox(height: 5),
                                SelectableText(
                                  item.fingerprints.isEmpty
                                      ? 'Unavailable — do not trust'
                                      : item.fingerprints.join('\n'),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                                if (item.nsfw)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      'The extension declares mature content.',
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Detected does not mean trusted or compatible. No extension code is executed.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      await bridge.openSettings(
                                        item.packageName,
                                      );
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not open Android app settings.',
                                                ),
                                              ),
                                            );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Android app settings'),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        const SizedBox(height: 24),
        const Eyebrow('The trust boundary'),
        const SizedBox(height: 12),
        const Text(
          'Extension APKs contain executable third-party code, not just source lists. A future runtime must verify signing certificates, require explicit trust, and re-check updates. A native bridge is not a security sandbox.',
          style: TextStyle(fontSize: 13, height: 1.7),
        ),
      ],
    );
  }
}
