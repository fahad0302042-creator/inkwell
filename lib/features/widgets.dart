import 'package:flutter/material.dart';

import '../core/catalog.dart';

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 2,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class Cover extends StatelessWidget {
  final Comic comic;
  final double radius;
  const Cover(this.comic, {super.key, this.radius = 14});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(
      comic.cover,
      fit: BoxFit.cover,
      semanticLabel: '${comic.title} cover',
    ),
  );
}

class Notice extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const Notice(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.info_outline,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: .5),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(message, style: const TextStyle(fontSize: 13, height: 1.55)),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> saveAction(BuildContext context, Future<void> action) async {
  try {
    await action;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save. Please check your device storage and try again.',
          ),
        ),
      );
    }
  }
}
