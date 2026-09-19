import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/store.dart';
import 'widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Eyebrow('Just the way you like it'),
        const SizedBox(height: 9),
        const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Lora', fontSize: 38),
        ),
        const SizedBox(height: 28),
        const Eyebrow('Appearance'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Dark theme'),
          subtitle: const Text('A softer shelf after sundown'),
          value: state.dark,
          onChanged: (v) => saveAction(
            context,
            ref.read(libraryProvider.notifier).setDark(v),
          ),
        ),
        const Divider(height: 32),
        const Eyebrow('Default reading mode'),
        const SizedBox(height: 12),
        for (final mode in ReaderMode.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(switch (mode) {
              ReaderMode.rightToLeft => 'Right to left',
              ReaderMode.leftToRight => 'Left to right',
              ReaderMode.vertical => 'Vertical scroll',
            }),
            trailing: Icon(
              state.mode == mode
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            onTap: () => saveAction(
              context,
              ref.read(libraryProvider.notifier).setMode(mode),
            ),
          ),
        const Divider(height: 32),
        const Eyebrow('Your data'),
        const SizedBox(height: 12),
        const Text(
          'Library, progress and preferences stay on this device. No accounts, analytics or cloud sync.',
          style: TextStyle(height: 1.6),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Reset local library and preferences'),
          onPressed: () async {
            final reset = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Start a fresh shelf?'),
                content: const Text(
                  'This removes saved titles, reading progress and history, and resets reader and theme preferences. Bundled samples and installed extension APKs are not deleted.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
            if (reset == true && context.mounted) {
              await saveAction(
                context,
                ref.read(libraryProvider.notifier).reset(),
              );
            }
          },
        ),
        const SizedBox(height: 30),
        const Notice(
          'Inkwell · Experimental runtime 0.2',
          'Flutter + Kotlin. Experimental extension browsing and online reading. Compatibility depends on the source. Offline downloads, live library storage, source settings, JavaScript and background updates are future work.',
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Inkwell',
            applicationVersion: '0.2.0',
            applicationLegalese: 'Original bundled sample artwork and story.',
          ),
          child: const Text('Open-source licences'),
        ),
      ],
    );
  }
}
