import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/catalog.dart';
import '../core/store.dart';
import 'reader.dart';
import 'widgets.dart';

void openComic(BuildContext context, Comic comic) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => ComicDetails(comic: comic)));
void openReader(BuildContext context, Comic comic, {bool restart = false}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ComicReader(comic: comic, restart: restart),
      ),
    );

class ComicDetails extends ConsumerWidget {
  final Comic comic;
  const ComicDetails({super.key, required this.comic});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final saved = state.saved.contains(comic.id);
    final progress = state.progress[comic.id];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inkwell', style: TextStyle(fontFamily: 'Lora')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, height: 180, child: Cover(comic)),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('Sample collection'),
                        const SizedBox(height: 10),
                        Text(
                          comic.title,
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 29,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(comic.author),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text(
                            comic.genre,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => openReader(context, comic),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(
                  progress == null
                      ? 'Start reading'
                      : 'Continue · Page ${progress + 1} of 4',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => saveAction(
                  context,
                  ref.read(libraryProvider.notifier).toggle(comic.id),
                ),
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                ),
                label: Text(saved ? 'Saved to library' : 'Add to library'),
              ),
              const SizedBox(height: 26),
              const Eyebrow('The story'),
              const SizedBox(height: 12),
              Text(comic.description, style: const TextStyle(height: 1.7)),
              const SizedBox(height: 26),
              const Notice(
                'Available offline',
                'This original sample is included with the app. No extension or download is needed.',
                icon: Icons.offline_pin_outlined,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Chapters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  const Text('1 chapter'),
                ],
              ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.article_outlined),
                title: const Text('01 · A letter to the moon'),
                subtitle: const Text('Original sample · 4 pages'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openReader(context, comic),
              ),
              if (progress != null)
                TextButton(
                  onPressed: () => openReader(context, comic, restart: true),
                  child: const Text('Read again from the beginning'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
