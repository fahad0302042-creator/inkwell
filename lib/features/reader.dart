import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/catalog.dart';
import '../core/store.dart';
import 'widgets.dart';

class ComicReader extends ConsumerStatefulWidget {
  final Comic comic;
  final bool restart;
  const ComicReader({super.key, required this.comic, this.restart = false});
  @override
  ConsumerState<ComicReader> createState() => _ComicReaderState();
}

class _ComicReaderState extends ConsumerState<ComicReader> {
  late int page;
  late PageController pager;
  late ScrollController scroll;
  bool chrome = true;
  double extent = 0;
  ReaderMode? previousMode;
  @override
  void initState() {
    super.initState();
    page = widget.restart
        ? 0
        : (ref.read(libraryProvider).progress[widget.comic.id] ?? 0).clamp(
            0,
            3,
          );
    pager = PageController(initialPage: page);
    scroll = ScrollController()..addListener(onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) record(page);
    });
  }

  void record(int next) {
    if (page != next) setState(() => page = next);
    saveAction(
      context,
      ref.read(libraryProvider.notifier).record(widget.comic.id, next),
    );
  }

  void onScroll() {
    if (extent <= 0 || ref.read(libraryProvider).mode != ReaderMode.vertical) {
      return;
    }
    final atEnd =
        scroll.position.maxScrollExtent > 0 &&
        scroll.offset >= scroll.position.maxScrollExtent - 1;
    final next = atEnd
        ? 3
        : ((scroll.offset + 80) / extent).floor().clamp(0, 3);
    if (next != page) record(next);
  }

  void go(int index) {
    if (index < 0 || index > 3) return;
    if (ref.read(libraryProvider).mode == ReaderMode.vertical) {
      scroll.animateTo(
        (index * extent).clamp(0, scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      pager.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    pager.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> options() async {
    final mode = await showModalBottomSheet<ReaderMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Make yourself comfortable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Reading direction · pinch a page to zoom'),
              const SizedBox(height: 14),
              for (final item in ReaderMode.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item == ref.read(libraryProvider).mode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(switch (item) {
                    ReaderMode.rightToLeft => 'Right to left · Manga',
                    ReaderMode.leftToRight => 'Left to right · Comics',
                    ReaderMode.vertical => 'Vertical scroll · Webtoon',
                  }),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
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
    final mode = ref.watch(libraryProvider.select((v) => v.mode));
    if (previousMode != mode) {
      previousMode = mode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (mode == ReaderMode.vertical && scroll.hasClients) {
          scroll.jumpTo(
            (page * extent).clamp(0, scroll.position.maxScrollExtent),
          );
        } else if (pager.hasClients) {
          pager.jumpToPage(page);
        }
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFF111614),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth.clamp(0.0, 780.0);
            extent = width * 1.5 + 16;
            Widget image(int index) => GestureDetector(
              onTap: () => setState(() => chrome = !chrome),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.asset(
                  widget.comic.pages[index],
                  fit: BoxFit.contain,
                  semanticLabel: 'Sample story, page ${index + 1} of 4',
                ),
              ),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: mode == ReaderMode.vertical
                          ? ListView.builder(
                              controller: scroll,
                              itemCount: 4,
                              itemExtent: extent,
                              itemBuilder: (_, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: image(index),
                              ),
                            )
                          : PageView.builder(
                              controller: pager,
                              reverse: mode == ReaderMode.rightToLeft,
                              itemCount: 4,
                              onPageChanged: record,
                              itemBuilder: (_, index) => image(index),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !chrome,
                    child: AnimatedOpacity(
                      opacity: chrome ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: ColoredBox(
                        color: const Color(0xEC111614),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                color: Colors.white,
                                tooltip: 'Back',
                                icon: const Icon(Icons.arrow_back),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.comic.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(
                                      'Chapter 01 · Bundled sample',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: options,
                                tooltip: 'Reader settings',
                                color: Colors.white,
                                icon: const Icon(Icons.tune),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !chrome,
                    child: AnimatedOpacity(
                      opacity: chrome ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: ColoredBox(
                        color: const Color(0xEC111614),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: page > 0
                                        ? () => go(page - 1)
                                        : null,
                                    tooltip: 'Previous page',
                                    color: Colors.white,
                                    disabledColor: Colors.white24,
                                    icon: const Icon(
                                      Icons.skip_previous_outlined,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'PAGE ${page + 1} / 4',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: page < 3
                                        ? () => go(page + 1)
                                        : null,
                                    tooltip: 'Next page',
                                    color: Colors.white,
                                    disabledColor: Colors.white24,
                                    icon: const Icon(Icons.skip_next_outlined),
                                  ),
                                ],
                              ),
                              LinearProgressIndicator(
                                value: (page + 1) / 4,
                                minHeight: 2,
                                color: const Color(0xFFC9E2B9),
                                backgroundColor: Colors.white12,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap the page to hide controls',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
