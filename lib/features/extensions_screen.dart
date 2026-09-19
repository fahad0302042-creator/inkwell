import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/extensions.dart';
import 'source_screens.dart';
import 'widgets.dart';

class ExtensionsScreen extends ConsumerStatefulWidget {
  const ExtensionsScreen({super.key});
  @override
  ConsumerState<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends ConsumerState<ExtensionsScreen>
    with WidgetsBindingObserver {
  String? busy;
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

  Future<void> run(String name, Future<void> Function() task) async {
    setState(() => busy = name);
    try {
      await task();
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Extension could not complete the request'),
            content: SingleChildScrollView(
              child: SelectableText(runtimeError(e)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } finally {
      ref.invalidate(installedExtensionsProvider);
      ref.invalidate(extensionSourcesProvider(name));
      if (mounted) setState(() => busy = null);
    }
  }

  Future<void> trust(InstalledExtension item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trust ${item.name}?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This APK contains third-party code. It will run with Inkwell’s permissions, including network and access to app data. The compatibility layer is NOT a security sandbox.\n\nOnly continue if you trust the publisher. Updates require a new review.',
              ),
              const SizedBox(height: 18),
              Text(
                '${item.packageName}\nVersion ${item.version} · API ${item.apiVersion}',
              ),
              const SizedBox(height: 12),
              const Text('Signing certificate SHA-256'),
              SelectableText(
                item.fingerprints.join('\n'),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Trust this APK and load'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await run(
        item.packageName,
        () => ref.read(extensionBridgeProvider).trust(item),
      );
    }
  }

  Future<void> revoke(InstalledExtension item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke extension trust?'),
        content: const Text(
          'Future source calls will be blocked. Close and restart Inkwell afterward to fully unload any code already started by this extension.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await run(
        item.packageName,
        () => ref.read(extensionBridgeProvider).revoke(item.packageName),
      );
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
          'Experimental extension runtime',
          'API 1.4 / 1.6 host with source browsing and reading. Compatibility varies by extension. Source settings, custom filters, JavaScript and verification-page handling are not implemented.',
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 16),
        if (bridge.available)
          OutlinedButton.icon(
            onPressed: () => run('website', bridge.openWebsite),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Keiyoushi extension listing'),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(child: Eyebrow('Installed on this device')),
            IconButton(
              tooltip: 'Rescan extensions',
              onPressed: busy == null
                  ? () => ref.invalidate(installedExtensionsProvider)
                  : null,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (!bridge.available)
          const Notice(
            'Android device required',
            'Native extension code only runs in the Android app. No synthetic source results are shown.',
            icon: Icons.android,
          ),
        if (bridge.available)
          installed.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) =>
                Notice('Could not scan extensions', runtimeError(e)),
            data: (items) => items.isEmpty
                ? const Notice(
                    'No installed extensions found',
                    'Install an extension APK through Android’s installer, then return and rescan. Private extensions inside Mihon cannot be discovered. The first test target is Keiyoushi xkcd.',
                    icon: Icons.extension_outlined,
                  )
                : Column(
                    children: items
                        .map(
                          (item) => Card(
                            elevation: 0,
                            child: ExpansionTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.version} · ${item.trusted
                                    ? 'Trusted · experimental'
                                    : item.supported
                                    ? 'Needs trust'
                                    : 'Unsupported API'}',
                              ),
                              leading: Icon(
                                item.trusted
                                    ? Icons.verified_user_outlined
                                    : Icons.extension_outlined,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                18,
                              ),
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  item.packageName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'API ${item.apiVersion} · ${item.entryPoint}',
                                ),
                                const SizedBox(height: 10),
                                const Eyebrow('Signing certificate · SHA-256'),
                                SelectableText(
                                  item.fingerprints.join('\n'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                if (item.nsfw)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      'This extension declares mature content.',
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                if (busy == item.packageName)
                                  const LinearProgressIndicator(),
                                if (!item.trusted && item.supported)
                                  FilledButton.icon(
                                    onPressed: busy == null
                                        ? () => trust(item)
                                        : null,
                                    icon: const Icon(Icons.shield_outlined),
                                    label: const Text('Review trust and load'),
                                  ),
                                if (item.trusted) ...[
                                  SourceList(packageName: item.packageName),
                                  TextButton(
                                    onPressed: busy == null
                                        ? () => revoke(item)
                                        : null,
                                    child: const Text('Revoke trust'),
                                  ),
                                ],
                                TextButton.icon(
                                  onPressed: busy == null
                                      ? () => run(
                                          item.packageName,
                                          () => bridge.openSettings(
                                            item.packageName,
                                          ),
                                        )
                                      : null,
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
        const Text(
          'Downloaded files are not automatically trusted. Trust is tied to the exact package, version, signing certificate and APK bytes.',
          style: TextStyle(fontSize: 12, height: 1.6),
        ),
      ],
    );
  }
}

class SourceList extends ConsumerWidget {
  final String packageName;
  const SourceList({super.key, required this.packageName});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(extensionSourcesProvider(packageName))
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Notice('Source could not load', runtimeError(e)),
            TextButton(
              onPressed: () =>
                  ref.invalidate(extensionSourcesProvider(packageName)),
              child: const Text('Retry loading'),
            ),
          ],
        ),
        data: (sources) => Column(
          children: sources
              .map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name),
                  subtitle: Text(s.lang.toUpperCase()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SourceBrowseScreen(source: s),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
}
