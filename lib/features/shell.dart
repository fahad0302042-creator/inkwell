import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/catalog.dart';
import '../core/store.dart';
import 'details.dart';
import 'extensions_screen.dart';
import 'settings.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  static const labels = ['Library', 'Browse', 'History', 'Settings'];
  static const icons = [
    Icons.auto_stories_outlined,
    Icons.explore_outlined,
    Icons.history,
    Icons.tune,
  ];
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final screen = switch (selected) {
      0 => LibraryScreen(onBrowse: () => setState(() => selected = 1)),
      1 => const BrowseScreen(),
      2 => const HistoryScreen(),
      _ => const SettingsScreen(),
    };
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 230,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant
                          .withValues(alpha: .5),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 34,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Brand(),
                    const SizedBox(height: 55),
                    const Eyebrow('Your reading space'),
                    const SizedBox(height: 18),
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: selected == i,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          leading: Icon(icons[i], size: 21),
                          title: Text(
                            labels[i],
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => setState(() => selected = i),
                        ),
                      ),
                    const Spacer(),
                    const Icon(Icons.spa_outlined, size: 26),
                    const SizedBox(height: 12),
                    const Text(
                      'One more chapter.\nA little less noise.',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 20,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Eyebrow('Inkwell / v0.1'),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 40 : 24,
                      vertical: 22,
                    ),
                    child: Row(
                      children: [
                        if (!wide)
                          const Flexible(child: Brand())
                        else
                          const Eyebrow('A good place to get lost'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Color(0xFF698469),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'LOCAL FIRST',
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1140),
                        child: screen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
              destinations: List.generate(
                4,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: labels[i],
                ),
              ),
            ),
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 31,
            height: 35,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 19,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'inkwell',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 29,
              letterSpacing: -1.3,
            ),
          ),
        ],
      ),
    ),
  );
}

class LibraryScreen extends ConsumerStatefulWidget {
  final VoidCallback onBrowse;
  const LibraryScreen({super.key, required this.onBrowse});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String filter = 'All titles', query = '';
  bool searching = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final saved = catalog.where((c) => state.saved.contains(c.id)).toList();
    final items = saved.where((c) {
      final progress = state.progress[c.id];
      final matches = switch (filter) {
        'Reading' => progress != null && progress < 3,
        'Unread' => progress == null,
        'Finished' => progress == 3,
        _ => true,
      };
      return matches && c.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    final recent = state.recent.where((id) => state.saved.contains(id));
    final featured = recent.isNotEmpty
        ? catalog.firstWhere((c) => c.id == recent.first)
        : (saved.isNotEmpty ? saved.first : null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow('Your next chapter awaits'),
                  SizedBox(height: 9),
                  Text(
                    'The library',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 38,
                      letterSpacing: -1.2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                searching = !searching;
                query = '';
              }),
              tooltip: 'Search library',
              icon: Icon(searching ? Icons.close : Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'A home for the stories you keep coming back to.',
          style: TextStyle(fontSize: 13),
        ),
        if (searching)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Search your library',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        const SizedBox(height: 26),
        if (featured != null)
          FeatureCard(comic: featured, page: state.progress[featured.id]),
        const SizedBox(height: 27),
        Row(
          children: [
            const Eyebrow('Your collection'),
            const Spacer(),
            Text(
              '${saved.length} titles',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final name in [
                'All titles',
                'Reading',
                'Unread',
                'Finished',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    selected: filter == name,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => filter = name),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.auto_stories_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  saved.isEmpty
                      ? 'Your next story starts here.'
                      : 'No titles in this view.',
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onBrowse,
                  child: const Text('Explore sample collection'),
                ),
              ],
            ),
          )
        else
          ComicGrid(items: items),
        const SizedBox(height: 22),
        const Text(
          'BUNDLED SAMPLES  /  NO CONNECTED SOURCES',
          style: TextStyle(fontSize: 9, letterSpacing: 1.7, color: Colors.grey),
        ),
      ],
    );
  }
}

class FeatureCard extends StatelessWidget {
  final Comic comic;
  final int? page;
  const FeatureCard({super.key, required this.comic, this.page});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF183E35),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page == null ? 'ON YOUR SHELF' : 'PICK UP WHERE YOU LEFT OFF',
                style: const TextStyle(
                  color: Color(0xFFC5D5AF),
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                comic.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lora',
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                page == null
                    ? 'A small story for a quiet moment.'
                    : 'Chapter 01 · Page ${page! + 1} of 4',
                style: const TextStyle(color: Color(0xFFB3C5BC), fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xFF183E35),
                  backgroundColor: const Color(0xFFE3EDCD),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: () => openReader(context, comic),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(
                  page == null ? 'Start reading' : 'Continue',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Transform.rotate(
          angle: .07,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width < 400 ? 80 : 110,
            height: 164,
            child: Cover(comic, radius: 8),
          ),
        ),
      ],
    ),
  );
}

class ComicGrid extends ConsumerWidget {
  final List<Comic> items;
  const ComicGrid({super.key, required this.items});
  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, size) {
      final count = (size.maxWidth / 165).floor().clamp(2, 5);
      final width = (size.maxWidth - (count - 1) * 18) / count;
      return Wrap(
        spacing: 18,
        runSpacing: 24,
        children: items.map((comic) {
          final page = ref.watch(libraryProvider).progress[comic.id];
          return SizedBox(
            width: width,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => openComic(context, comic),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Cover(comic),
                        Positioned(
                          top: 9,
                          left: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xDDFAF8ED),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'SAMPLE',
                              style: TextStyle(
                                color: Color(0xFF243D34),
                                fontSize: 8,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    comic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    page == null ? comic.genre : 'Page ${page + 1} of 4',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  bool extensions = false;
  String query = '';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('Find your next favourite'),
            SizedBox(height: 9),
            Text(
              'Explore',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 38,
                letterSpacing: -1.2,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Samples'),
              icon: Icon(Icons.auto_stories_outlined),
            ),
            ButtonSegment(
              value: true,
              label: Text('Extensions'),
              icon: Icon(Icons.extension_outlined),
            ),
          ],
          selected: {extensions},
          onSelectionChanged: (v) => setState(() => extensions = v.first),
        ),
      ),
      const SizedBox(height: 20),
      Expanded(
        child: extensions
            ? const ExtensionsScreen()
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search sample titles or genres',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Notice(
                    'A little reading room',
                    'Four original concept covers and one shared four-page story. Bundled samples—not live manga sources.',
                    icon: Icons.local_florist_outlined,
                  ),
                  const SizedBox(height: 24),
                  if (!catalog.any(
                    (c) => '${c.title} ${c.genre}'.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  ))
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No matching samples.'),
                      ),
                    )
                  else
                    ComicGrid(
                      items: catalog
                          .where(
                            (c) => '${c.title} ${c.genre}'
                                .toLowerCase()
                                .contains(query.toLowerCase()),
                          )
                          .toList(),
                    ),
                ],
              ),
      ),
    ],
  );
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Eyebrow('Between the bookmarks'),
        const SizedBox(height: 9),
        const Text(
          'Recently read',
          style: TextStyle(fontFamily: 'Lora', fontSize: 38),
        ),
        const SizedBox(height: 24),
        if (state.recent.isEmpty)
          const Notice(
            'A fresh page',
            'Open a sample and start reading. Your recently read stories will appear here.',
            icon: Icons.history,
          ),
        for (final id in state.recent.where(
          (id) => catalog.any((c) => c.id == id),
        ))
          Builder(
            builder: (context) {
              final comic = catalog.firstWhere((c) => c.id == id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 42,
                    height: 64,
                    child: Cover(comic, radius: 5),
                  ),
                  title: Text(comic.title),
                  subtitle: Text(
                    'Chapter 01 · Page ${(state.progress[id] ?? 0) + 1} of 4',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => openReader(context, comic),
                ),
              );
            },
          ),
      ],
    );
  }
}
