import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/store.dart';
import '../platform/extensions.dart';
import 'widgets.dart';

final sourceImageProvider = FutureProvider.autoDispose
    .family<Uint8List, (String, bool)>(
      (ref, key) =>
          ref.watch(extensionBridgeProvider).image(key.$1, cover: key.$2),
    );

class SourceImage extends ConsumerWidget {
  final String handle;
  final bool cover;
  final BoxFit fit;
  const SourceImage({
    super.key,
    required this.handle,
    this.cover = false,
    this.fit = BoxFit.contain,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (handle, cover);
    return ref
        .watch(sourceImageProvider(key))
        .when(
          loading: () => const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Center(
            child: cover
                ? const Icon(Icons.broken_image_outlined)
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(runtimeError(e), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(sourceImageProvider(key)),
                            child: const Text('Retry image'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          data: (bytes) => Image.memory(
            bytes,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                const Center(child: Text('Unsupported or invalid image')),
          ),
        );
  }
}

class SourceBrowseScreen extends ConsumerStatefulWidget {
  final ExtensionSource source;
  const SourceBrowseScreen({super.key, required this.source});
  @override
  ConsumerState<SourceBrowseScreen> createState() => _SourceBrowseScreenState();
}

class _SourceBrowseScreenState extends ConsumerState<SourceBrowseScreen> {
  final query = TextEditingController();
  final items = <SourceManga>[];
  bool loading = true, hasNext = false, latest = false;
  String? error;
  int page = 1, generation = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    final ticket = ++generation;
    final nextPage = more ? page + 1 : 1;
    setState(() {
      loading = true;
      error = null;
      if (!more) items.clear();
    });
    try {
      final result = await ref
          .read(extensionBridgeProvider)
          .search(widget.source, query.text.trim(), nextPage, latest: latest);
      if (!mounted || ticket != generation) return;
      setState(() {
        items.addAll(result.items);
        hasNext = result.hasNextPage;
        page = nextPage;
      });
    } catch (e) {
      if (mounted && ticket == generation) {
        setState(() => error = runtimeError(e));
      }
    } finally {
      if (mounted && ticket == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${widget.source.name} · ${widget.source.lang.toUpperCase()}',
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: TextField(
            controller: query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              latest = false;
              load();
            },
            decoration: InputDecoration(
              hintText: 'Search this source',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Search source',
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  latest = false;
                  load();
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Popular'),
                selected: !latest && query.text.isEmpty,
                onSelected: (_) {
                  query.clear();
                  latest = false;
                  load();
                },
              ),
              const SizedBox(width: 8),
              if (widget.source.supportsLatest)
                ChoiceChip(
                  label: const Text('Latest'),
                  selected: latest,
                  onSelected: (_) {
                    query.clear();
                    latest = true;
                    load();
                  },
                ),
              const Spacer(),
              const Text(
                'LIVE SOURCE',
                style: TextStyle(fontSize: 9, letterSpacing: 1),
              ),
            ],
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == items.length) {
                if (error != null) {
                  return Column(
                    children: [
                      Notice('Source request failed', error!),
                      TextButton(
                        onPressed: () => load(more: items.isNotEmpty),
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }
                if (!loading && items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No titles returned by this source.'),
                    ),
                  );
                }
                if (!loading && hasNext) {
                  return OutlinedButton(
                    onPressed: () => load(more: true),
                    child: const Text('Load more'),
                  );
                }
                return const SizedBox(height: 24);
              }
              final manga = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 12,
                  leading: SizedBox(
                    width: 48,
                    height: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: manga.hasCover
                          ? SourceImage(
                              handle: manga.handle,
                              cover: true,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.menu_book_outlined),
                    ),
                  ),
                  title: Text(manga.title),
                  subtitle: Text(widget.source.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SourceDetailsScreen(
                        manga: manga,
                        source: widget.source,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class SourceDetailsScreen extends ConsumerStatefulWidget {
  final SourceManga manga;
  final ExtensionSource source;
  const SourceDetailsScreen({
    super.key,
    required this.manga,
    required this.source,
  });
  @override
  ConsumerState<SourceDetailsScreen> createState() =>
      _SourceDetailsScreenState();
}

class _SourceDetailsScreenState extends ConsumerState<SourceDetailsScreen> {
  late Future<SourceManga> details;
  late Future<List<SourceChapter>> chapters;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    final bridge = ref.read(extensionBridgeProvider);
    details = bridge.details(widget.manga.handle);
    chapters = bridge.chapters(widget.manga.handle);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.manga.title),
      actions: [
        IconButton(
          tooltip: 'Reload title',
          onPressed: () => setState(refresh),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('${widget.source.name} / ${widget.source.lang}'),
                const SizedBox(height: 16),
                FutureBuilder<SourceManga>(
                  future: details,
                  builder: (context, snapshot) {
                    final manga = snapshot.data ?? widget.manga;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (manga.hasCover) ...[
                              SizedBox(
                                width: 100,
                                height: 150,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SourceImage(
                                    handle: manga.handle,
                                    cover: true,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    manga.title,
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (manga.author.isNotEmpty)
                                    Text(manga.author),
                                  if (manga.genre.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        manga.genre,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const LinearProgressIndicator(),
                        if (snapshot.hasError)
                          Notice(
                            'Details unavailable',
                            runtimeError(snapshot.error!),
                          ),
                        if (manga.description.isNotEmpty)
                          Text(
                            manga.description,
                            style: const TextStyle(height: 1.6),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Notice(
                  'Online reading preview',
                  'Chapter positions are saved on this device. Adding live titles to the main library, custom filters, source settings and offline downloads are not implemented yet.',
                ),
                const SizedBox(height: 24),
                Text('Chapters', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
        FutureBuilder<List<SourceChapter>>(
          future: chapters,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Notice(
                    'Chapters unavailable',
                    runtimeError(snapshot.error!),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
            final list = snapshot.data!;
            if (list.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No chapters returned.'),
                ),
              );
            }
            return SliverList.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final chapter = list[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.article_outlined),
                  title: Text(chapter.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SourceChapterReader(chapter: chapter),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
  );
}

class SourceChapterReader extends ConsumerStatefulWidget {
  final SourceChapter chapter;
  const SourceChapterReader({super.key, required this.chapter});
  @override
  ConsumerState<SourceChapterReader> createState() =>
      _SourceChapterReaderState();
}

class _SourceChapterReaderState extends ConsumerState<SourceChapterReader> {
  late Future<List<SourcePage>> request;
  late PageController controller;
  final scroll = ScrollController();
  int index = 0;
  bool visible = true;
  ReaderMode? previousMode;
  double extent = 0;
  int count = 0;
  String get key => 'source.progress.${widget.chapter.progressKey}';
  @override
  void initState() {
    super.initState();
    index = ref.read(preferencesProvider).getInt(key) ?? 0;
    controller = PageController(initialPage: index);
    request = ref.read(extensionBridgeProvider).pages(widget.chapter.handle);
    scroll.addListener(() {
      if (!scroll.hasClients || extent == 0 || count == 0) return;
      final end =
          scroll.position.maxScrollExtent > 0 &&
          scroll.offset >= scroll.position.maxScrollExtent - 1;
      final next = end
          ? count - 1
          : ((scroll.offset + 40) / extent).floor().clamp(0, count - 1);
      if (next != index) record(next);
    });
  }

  void record(int next) {
    if (next != index) setState(() => index = next);
    saveAction(context, () async {
      if (!await ref.read(preferencesProvider).setInt(key, next)) {
        throw StateError('Could not save page');
      }
    }());
  }

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> settings() async {
    final mode = await showModalBottomSheet<ReaderMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in ReaderMode.values)
              ListTile(
                title: Text(switch (m) {
                  ReaderMode.rightToLeft => 'Right to left',
                  ReaderMode.leftToRight => 'Left to right',
                  ReaderMode.vertical => 'Vertical scroll',
                }),
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (mode != null && mounted) {
      await saveAction(
        context,
        ref.read(libraryProvider.notifier).setMode(mode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(libraryProvider.select((s) => s.mode));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chapter.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Source reader settings',
            onPressed: settings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: FutureBuilder<List<SourcePage>>(
        future: request,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Notice(
                        'Could not load chapter',
                        runtimeError(snapshot.error!),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          request = ref
                              .read(extensionBridgeProvider)
                              .pages(widget.chapter.handle);
                        }),
                        child: const Text('Retry chapter'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pages = snapshot.data!;
          if (pages.isEmpty) {
            return const Center(
              child: Text('No pages returned by this source.'),
            );
          }
          count = pages.length;
          final bounded = index.clamp(0, count - 1);
          if (index != bounded) {
            index = bounded;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && controller.hasClients) {
                controller.jumpToPage(index);
              }
            });
          }
          if (previousMode != mode) {
            previousMode = mode;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (mode == ReaderMode.vertical && scroll.hasClients) {
                scroll.jumpTo(
                  (index * extent).clamp(0, scroll.position.maxScrollExtent),
                );
              } else if (controller.hasClients) {
                controller.jumpToPage(index);
              }
            });
          }
          return LayoutBuilder(
            builder: (context, box) {
              extent = box.maxWidth * 1.5 + 12;
              Widget image(int i) => GestureDetector(
                onTap: () => setState(() => visible = !visible),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: SizedBox.expand(
                    child: SourceImage(handle: pages[i].handle),
                  ),
                ),
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: mode == ReaderMode.vertical
                        ? ListView.builder(
                            controller: scroll,
                            itemExtent: extent,
                            itemCount: count,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: image(i),
                            ),
                          )
                        : PageView.builder(
                            controller: controller,
                            reverse: mode == ReaderMode.rightToLeft,
                            itemCount: count,
                            onPageChanged: record,
                            itemBuilder: (_, i) => image(i),
                          ),
                  ),
                  if (visible)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: .94),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Previous source page',
                                onPressed: index > 0
                                    ? () => go(index - 1, mode)
                                    : null,
                                icon: const Icon(Icons.skip_previous_outlined),
                              ),
                              Expanded(
                                child: Text(
                                  'PAGE ${index + 1} / $count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Next source page',
                                onPressed: index < count - 1
                                    ? () => go(index + 1, mode)
                                    : null,
                                icon: const Icon(Icons.skip_next_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void go(int next, ReaderMode mode) {
    if (mode == ReaderMode.vertical) {
      scroll.animateTo(
        (next * extent).clamp(0, scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }
}
