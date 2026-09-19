class Comic {
  final String id, title, author, genre, description, cover;
  const Comic(
    this.id,
    this.title,
    this.author,
    this.genre,
    this.description,
    this.cover,
  );
  List<String> get pages =>
      List.generate(4, (i) => 'assets/pages/page_${i + 1}.png');
}

// Original bundled sample material. These are NOT results from an extension.
const catalog = [
  Comic(
    'moon',
    'Moonlit Courier',
    'Inkwell Studio',
    'Adventure',
    'Every night, a small courier crosses a sleeping city with a letter addressed to the moon. Tonight, someone writes back.\n\nOriginal four-page reader sample, bundled offline. The other sample covers open the same short story to exercise the library.',
    'assets/covers/moon.png',
  ),
  Comic(
    'garden',
    'Paper Gardens',
    'Inkwell Studio',
    'Slice of life',
    'A garden that grows between the pages. A concept cover from the Inkwell sample collection; opens the shared four-page reader sample.',
    'assets/covers/garden.png',
  ),
  Comic(
    'signal',
    'Signal / 09',
    'Inkwell Studio',
    'Sci-fi',
    'A quiet transmission from the edge of the city. A concept cover from the Inkwell sample collection; opens the shared four-page reader sample.',
    'assets/covers/signal.png',
  ),
  Comic(
    'sea',
    'The Last Blue',
    'Inkwell Studio',
    'Fantasy',
    'Follow the tide beyond the map. A concept cover from the Inkwell sample collection; opens the shared four-page reader sample.',
    'assets/covers/sea.png',
  ),
];
